/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */
import {
	createConnection,
	TextDocuments,
	Diagnostic,
	DiagnosticSeverity,
	ProposedFeatures,
	InitializeParams,
	DidChangeConfigurationNotification,
	CompletionItem,
	CompletionItemKind,
	TextDocumentPositionParams,
	TextDocumentSyncKind,
	InitializeResult,
} from 'vscode-languageserver/node';

import {
	TextDocument
} from 'vscode-languageserver-textdocument';

import * as fs from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { URI } from 'vscode-uri';

// Create a connection for the server, using Node's IPC as a transport.
// Also include all preview / proposed LSP features.
const connection = createConnection(ProposedFeatures.all);

// Create a simple text document manager.
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

connection.onInitialize((params: InitializeParams) => {
	const capabilities = params.capabilities;

	// Does the client support the `workspace/configuration` request?
	// If not, we fall back using global settings.
	hasConfigurationCapability = !!(
		capabilities.workspace && !!capabilities.workspace.configuration
	);
	hasWorkspaceFolderCapability = !!(
		capabilities.workspace && !!capabilities.workspace.workspaceFolders
	);
	hasDiagnosticRelatedInformationCapability = !!(
		capabilities.textDocument &&
		capabilities.textDocument.publishDiagnostics &&
		capabilities.textDocument.publishDiagnostics.relatedInformation
	);

	const result: InitializeResult = {
		capabilities: {
			textDocumentSync: TextDocumentSyncKind.Incremental,
			completionProvider: {
				resolveProvider: false,
			},
			hoverProvider: true,
			definitionProvider: true,
		}
	};
	if (hasWorkspaceFolderCapability) {
		result.capabilities.workspace = {
			workspaceFolders: {
				supported: true
			}
		};
	}
	return result;
});

connection.onInitialized(() => {
	if (hasConfigurationCapability) {
		// Register for all configuration changes.
		connection.client.register(DidChangeConfigurationNotification.type, undefined);
	}
	if (hasWorkspaceFolderCapability) {
		connection.workspace.onDidChangeWorkspaceFolders(_event => {
			connection.console.log('Workspace folder change event received.');
		});
	}
	parseFiles();
});

function parseFiles() {
    const workspaceFolders = connection.workspace.getWorkspaceFolders();
    if (!workspaceFolders) return;

    workspaceFolders.then(folders => {
        if (!folders) {
            console.error('No workspace folders found.');
            return;
        }
		folders.forEach(folder => {
            const folderPath = folder.uri.replace('file://', '');
			checkDirectory(folderPath);
        });
    });
}

function checkDirectory(directory: string) {
    fs.readdir(directory, { withFileTypes: true }, (err, files) => {
        if (err) {
            console.error(`Failed to read directory: ${directory}`, err);
            return;
        }

        files.forEach(file => {
            const filePath = path.join(directory, file.name);

            if (file.isDirectory()) {
                // Recursively traverse subdirectories
                checkDirectory(filePath);
            } else if (file.isFile() && path.extname(file.name) === '.esl') {
                fs.readFile(filePath, 'utf8', (err, content) => {
                    if (err) {
                        console.error(`Failed to read file: ${filePath}`, err);
                        return;
                    }

                    // Create a TextDocument from the file content
                    const document = TextDocument.create(`file://${filePath}`, 'plaintext', 0, content);

                    parseFunctionDeclarationNames(document);
					parseVariableNames(document);
					parseFunctionDeclarations(document);
                });
            }
        });
    });
}
  
// The content of a text document has changed. This event is emitted
// when the text document first opened or when its content has changed.
documents.onDidChangeContent(async change => {
	const textDocument = change.document;
  
	parseFunctionDeclarationNames(textDocument);
	parseVariableNames(textDocument);
	parseFunctionDeclarations(textDocument);
    compileAndValidate(textDocument);
});

async function compileAndValidate(textDocument: TextDocument): Promise<void> {

    // const startTime = performance.now();

	const inputFile = textDocument.uri;
    const correctInputFile = URI.parse(inputFile).fsPath.replace(/ /g, '\\ ');
  	const outputFile = correctInputFile.replace('.esl', '.compiled.txt');
    const outputFile2 = URI.parse(inputFile).fsPath.replace('.esl', '.compiled.txt');
  	const command = `ecma-sl interpret ${correctInputFile} 2> ${outputFile}`;

    exec(command);		

	const diagnostics: Diagnostic[] = [];

	// Wait for the log file to be written
    setTimeout(async () => {
		try {
		  	const data = await fs.promises.readFile(outputFile2, 'utf8');

			const runtimeErrorMatch = data.match(/RuntimeError: (.*)\nFile "([^"]+)", line (\d+), characters (\d+)-(\d+)(.*)/); 

			if (runtimeErrorMatch) {
				const message = runtimeErrorMatch[1];
				const line = parseInt(runtimeErrorMatch[3], 10) - 1;
				const charStart = parseInt(runtimeErrorMatch[4], 10);
				const charEnd = parseInt(runtimeErrorMatch[5], 10);

				const diagnostic: Diagnostic = {
					severity: DiagnosticSeverity.Error,
					range: {
						start: { line: line, character: charStart },
						end: { line: line, character: charEnd }
					},
					message: `RuntimeError: ${message}`,
					source: 'ecma-sl'
				};

				diagnostics.push(diagnostic);
				connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
			    await fs.promises.unlink(outputFile2);
                // const endTime = performance.now();
                // const duration = endTime - startTime;
                // connection.console.log(`Diagnostic request took ${duration.toFixed(3)} ms`);
				return;

			}

			const errorMatch = data.match(/([^:]+):(\d+):(\d+), last token: ([^:]+): Error message found./);

			if (errorMatch) {
				const fileName = errorMatch[1];
				const line = parseInt(errorMatch[2], 10) - 1; // Convert to zero-based line number
				const character = parseInt(errorMatch[3], 10);
				const message = errorMatch[4];

                if (fileName !== path.basename(textDocument.uri)) {
					const diagnostic: Diagnostic = {
						severity: DiagnosticSeverity.Error,
						range: {
							start: { line: 0, character: 0 },
							end: { line: 0, character: 1 }
						},
						message: data.split('\n')[0].trim(),
						source: 'ecma-sl'
					};
					diagnostics.push(diagnostic);
				} else {
					const diagnostic: Diagnostic = {
						severity: DiagnosticSeverity.Error,
						range: {
							start: { line: line, character: character },
							end: { line: line, character: character + 1 }
						},
						message: `Error: ${message}`,
						source: 'ecma-sl'
					};
					diagnostics.push(diagnostic);
				}

				connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
			    await fs.promises.unlink(outputFile2);
                // const endTime = performance.now();
                // const duration = endTime - startTime;
                // connection.console.log(`Diagnostic request took ${duration.toFixed(3)} ms`);
				return;

			}
            connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
			await fs.promises.unlink(outputFile2);
            // const endTime = performance.now();
            // const duration = endTime - startTime;
            // connection.console.log(`Diagnostic request took ${duration.toFixed(3)} ms`);
            return;
		} catch (err) {
		}
    }, 50); // Add a delay to ensure the file is written
}

connection.onDidChangeWatchedFiles(_change => {
	// Monitored files have change in VSCode
	connection.console.log('We received a file change event');
	for (const change of _change.changes) {
		const document = documents.get(change.uri);
		if (document) {
			compileAndValidate(document);
		}
	}
	parseFiles();
});

const predefinedItems = [
    { label: 'return', kind: CompletionItemKind.Keyword },
    { label: 'print', kind: CompletionItemKind.Keyword },
    { label: 'if', kind: CompletionItemKind.Keyword },
    { label: 'else', kind: CompletionItemKind.Keyword },
    { label: 'function', kind: CompletionItemKind.Keyword },
    { label: 'elif', kind: CompletionItemKind.Keyword },
    { label: 'while', kind: CompletionItemKind.Keyword },
    { label: 'foreach', kind: CompletionItemKind.Keyword },
    { label: 'repeat', kind: CompletionItemKind.Keyword },
    { label: 'until', kind: CompletionItemKind.Keyword },
    { label: 'switch', kind: CompletionItemKind.Keyword },
    { label: 'case', kind: CompletionItemKind.Keyword },
    { label: 'sdefault', kind: CompletionItemKind.Keyword },
    { label: 'match', kind: CompletionItemKind.Keyword },
    { label: 'default', kind: CompletionItemKind.Keyword },
    { label: 'None', kind: CompletionItemKind.Keyword },
    { label: 'null', kind: CompletionItemKind.Keyword },
    { label: 'lambda', kind: CompletionItemKind.Keyword },
    { label: 'macro', kind: CompletionItemKind.Keyword },
    { label: 'catch', kind: CompletionItemKind.Keyword },
    { label: 'throw', kind: CompletionItemKind.Keyword },
    { label: 'fail', kind: CompletionItemKind.Keyword },
    { label: 'assume', kind: CompletionItemKind.Keyword },
    { label: 'assert', kind: CompletionItemKind.Keyword },
    { label: 'import', kind: CompletionItemKind.Keyword },
    { label: 'extern', kind: CompletionItemKind.Keyword },
    { label: 'delete', kind: CompletionItemKind.Keyword },
    { label: 'symbolic', kind: CompletionItemKind.Keyword },
    { label: 'typeof', kind: CompletionItemKind.Keyword },
    { label: 'gen_wrapper', kind: CompletionItemKind.Keyword },
    { label: 'true', kind: CompletionItemKind.Keyword },
    { label: 'false', kind: CompletionItemKind.Keyword },
    { label: 'undefined', kind: CompletionItemKind.Keyword },
    { label: 'typedef', kind: CompletionItemKind.Keyword },
    { label: 'any', kind: CompletionItemKind.Keyword },
    { label: 'unknown', kind: CompletionItemKind.Keyword },
    { label: 'never', kind: CompletionItemKind.Keyword },
    { label: 'void', kind: CompletionItemKind.Keyword },
    { label: 'int', kind: CompletionItemKind.Keyword },
    { label: 'float', kind: CompletionItemKind.Keyword },
    { label: 'string', kind: CompletionItemKind.Keyword },
    { label: 'boolean', kind: CompletionItemKind.Keyword },
    { label: 'symbol', kind: CompletionItemKind.Keyword },
    { label: 'sigma', kind: CompletionItemKind.Keyword },
];

connection.onCompletion((): CompletionItem[] => {

    // const startTime = performance.now();

	const completionItems: CompletionItem[] = [];
	const seenLabels = new Set<string>();  // Set to track labels that have been added

	predefinedItems.forEach(item => {
        if (!seenLabels.has(item.label)) {
            completionItems.push(item);
            seenLabels.add(item.label);
        }
    });

    functionDeclarations.forEach((signatureSet, _) => {
        signatureSet.forEach(signature => {
            if (!seenLabels.has(signature)) {
                const newItem: CompletionItem = {
                    label: signature,
                    kind: CompletionItemKind.Function,
                };
                completionItems.push(newItem);
                seenLabels.add(signature);
            }
        });
    });

	variableDeclarations.forEach((variableSet, _) => {
        variableSet.forEach(variableName => {
            if (!seenLabels.has(variableName)) {
                const newItem: CompletionItem = {
                    label: variableName,
                    kind: CompletionItemKind.Variable,
                };
                completionItems.push(newItem);
                seenLabels.add(variableName);
            }
        });
    });

    // const endTime = performance.now();
    // const duration = endTime - startTime;
    // connection.console.log(`Completion request took ${duration.toFixed(3)} ms`);

    return completionItems;
});

connection.onHover((params: TextDocumentPositionParams) => {

    // const startTime = performance.now();

    // Get the document from which to extract the text
    const document = documents.get(params.textDocument.uri);
    if (!document) return null;

    // Extract the text around the position
    const position = params.position;
    const text = document.getText();
    const lines = text.split(/\r?\n/);
    const line = lines[position.line];

    // Trim the line for leading spaces and calculate the original index of the first character
    const originalLine = line;
    const trimmedLine = line.trimStart();
    const leadingSpaces = originalLine.length - trimmedLine.length;

    const words = trimmedLine.match(/\([^)]*\)|[^\s()]+/g) || [];
    const filteredWords = words.map(w => w.trim()).filter(w => w.length > 0);

    let currentIndex = 0;
    for (let i = 0; i < filteredWords.length; i++) {
        const word = filteredWords[i].replace(/^[^(]*\(/, '').split(/[(;]/)[0].trim();
        const from = leadingSpaces + currentIndex + trimmedLine.substring(currentIndex).indexOf(word); // Calculate start index
        const to = from + word.length;

        // Check if the cursor is within the current word
        if (position.character >= from && position.character < to) {
            let description = '';

            // Check if the word is a function name
            functionDeclarations.forEach((functionSet, uri) => {
                functionSet.forEach(signature => {
                    // Extract the function name from the signature
                    const functionName = signature.split('(')[0].trim();
                    if (functionName === word) {
                        description = `Function Declaration: ${signature}`;
                    }
                });
            });

            // Check if the word is a variable name
            if (!description) {
                variableDeclarations.forEach((variableSet, _) => {
                    if (variableSet.has(word)) {
                        description = 'Variable';
                    }
                });
            }

            if (description) {
                const hoverText = `${word} - ${description}`; // Concatenate word and description

                // const endTime = performance.now();
                // const duration = endTime - startTime;
                // connection.console.log(`Hover request took ${duration.toFixed(3)} ms`);

                // Return hover information with the combined word and type
                return {
                    contents: {
                        kind: 'markdown',
                        value: `\`\`\`yaml\n${hoverText}\n\`\`\``
                    }
                };
            }
        }

        // Update currentIndex to reflect the next starting position
        currentIndex += word.length;
    }

    // const endTime = performance.now();
    // const duration = endTime - startTime;
    // connection.console.log(`Hover request took ${duration.toFixed(3)} ms`);

    return null; // No description found
});

const functionDeclarationNames = new Map<string, Map<string, { line: number; character: number }>>();

function parseFunctionDeclarationNames(document: TextDocument): void {
    // Retrieve or create the map for this document's URI
    const docDeclarations = functionDeclarationNames.get(document.uri) || new Map<string, { line: number; character: number }>();
    
    // Clear previous declarations for this document
    docDeclarations.clear();

    const lines = document.getText().split(/\r?\n/);
    const functionRegex = /^function (\w+)/;  // Regex to identify function declarations

    lines.forEach((line, i) => {
        const match = line.match(functionRegex);
        if (match) {
            const functionName = match[1];
            const character = line.indexOf(functionName);  // Find the position of the function name

            // Store the function declaration location in the document-specific map
            docDeclarations.set(functionName, {
                line: i,
                character: character
            });
        }
    });

    // Store the updated map back to the main declarations map
    functionDeclarationNames.set(document.uri, docDeclarations);
}

const variableDeclarations = new Map<string, Set<string>>();

function parseVariableNames(document: TextDocument): void {
    // Retrieve or create the set for this document's URI
    const docDeclarations = variableDeclarations.get(document.uri) || new Set<string>();
    
    // Clear previous declarations for this document
    docDeclarations.clear();

    const lines = document.getText().split(/\r?\n/);
    const variableRegex = /\b([a-zA-Z_][a-zA-Z0-9_\.\[\]\(\)]*)\s*:=/;  // Regex to identify variable declarations

    lines.forEach(line => {
        const match = line.match(variableRegex);
        if (match) {
            const variableName = match[1];
            // Store the variable name in the document-specific set
            docDeclarations.add(variableName);
        }
    });

    // Store the updated set back to the main declarations map
    variableDeclarations.set(document.uri, docDeclarations);
}

const functionDeclarations = new Map<string, Set<string>>();

function parseFunctionDeclarations(document: TextDocument): void {
    // Retrieve or create the set for this document's URI
    const docDeclarations = functionDeclarations.get(document.uri) || new Set<string>();

    // Clear previous declarations for this document
    docDeclarations.clear();

    const lines = document.getText().split(/\r?\n/);
    const functionRegex = /^\s*function\s+(\w+)\s*\(([^)]*)\)\s*.*$/;  // Regex to identify function declarations

    lines.forEach(line => {
        const match = line.match(functionRegex);
        if (match) {
            const functionName = match[1];
            const parameters = match[2].trim();
            const functionSignature = `${functionName}(${parameters})`;
            // Store the function signature in the document-specific set
            docDeclarations.add(functionSignature);
        }
    });

    // Store the updated set back to the main declarations map
    functionDeclarations.set(document.uri, docDeclarations);
}

connection.onDefinition((params: TextDocumentPositionParams) => {

    // const startTime = performance.now();

    const document = documents.get(params.textDocument.uri);
    if (!document) return null;

    const text = document.getText();
    const lines = text.split(/\r?\n/);
    const position = params.position;
    const line = lines[position.line];
    const words = line.match(/\w+/g) || [];

    let cumulativeLength = 0;
    for (const word of words) {
        const wordStart = line.indexOf(word, cumulativeLength);
        const wordEnd = wordStart + word.length;

        // Check if the cursor is within the current word
        if (position.character >= wordStart && position.character <= wordEnd) {
            let results = [];
            for (const [uri, docDeclarations] of functionDeclarationNames.entries()) {
            	const declaration = docDeclarations.get(word);
            	if (declaration) {
					results.push({
            	        uri: uri,
            	        range: {
            	            start: { line: declaration.line, character: declaration.character },
            	            end: { line: declaration.line, character: declaration.character + word.length }
            	        }
            	    });
            	}
        	}
            if (results.length > 1) {
                const currentFileUri = params.textDocument.uri;

                const countMatchingSegments = (uriA: string, uriB: string) => {
                    const partsA = uriA.split('/');
                    const partsB = uriB.split('/');
                    let matchCount = 0;

                    for (let i = 0; i < Math.min(partsA.length, partsB.length); i++) {
                        if (partsA[i] === partsB[i]) {
                            matchCount++;
                        } else {
                            break;
                        }
                    }
                    return matchCount;
                };

                results.sort((a, b) => {
                    const aMatchCount = countMatchingSegments(a.uri, currentFileUri);
                    const bMatchCount = countMatchingSegments(b.uri, currentFileUri);
                    return bMatchCount - aMatchCount;
                });
                // const endTime = performance.now();
                // const duration = endTime - startTime;
                // connection.console.log(`Definition request took ${duration.toFixed(3)} ms`);
                return results[0];
            }
            if (results.length === 1) {
                // const endTime = performance.now();
                // const duration = endTime - startTime;
                // connection.console.log(`Definition request took ${duration.toFixed(3)} ms`);
                return results[0];
            }
    	}
        cumulativeLength = wordEnd + 1; // Update the cumulative length to the end of the current word
    }
    return null;
});

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();
