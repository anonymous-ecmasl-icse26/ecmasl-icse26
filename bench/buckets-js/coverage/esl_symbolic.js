const fs = require("fs");
const path = require("path");

var input_types = {
  string: "str",
  integer: "int",
  float: "real",
  boolean: "bool",
};
var esl_symbolic = {};

esl_symbolic.INPUT = undefined;

const getValue = function (varName, targetType) {
  if (!esl_symbolic.INPUT) throw new Error("Input file (-in.json) not found");

  const variable = esl_symbolic.INPUT[varName];
  if (!variable) return undefined;

  const type = variable.type;
  const value = variable.value;

  if (type !== targetType) {
    throw new Error(
      `ERROR: ${varName} has type ${type}` +
        `in ${esl_symbolic.INPUT.name} but ${targetType} was expected`,
    );
  }
  return value;
};

// Should receive a __filename arg
// e.g., ~/ECMA-SL/bench/buckets-js/coverage/test/arrays/arrays1.test.js

esl_symbolic.getInputs = function (filename) {
  const testDir = filename.includes("bug")
    ? path.basename(path.dirname(path.dirname(filename))) + "/bug"
    : path.basename(path.dirname(filename)); // arrays

  const testBase = path.basename(filename).replace(/\.test\.js$/, ".js"); // arrays1.js
  const dirname = path.dirname(filename); // .../bench/buckets-js/coverage/test/arrays

  const inputs = filename.includes("bug") ? "../../../inputs" : "../../inputs";

  const inputFolder = path.resolve(dirname, inputs, testDir, testBase); //...bench/buckets-js/coverage/inputs/arrays/arrays1.js

  if (!fs.existsSync(inputFolder)) {
    throw new Error(`Could not find inputs dir: ${inputFolder}`);
  }

  const inputFiles = fs
    .readdirSync(inputFolder)
    .filter((f) => f.endsWith("-in.json"))
    .map((f) => path.join(inputFolder, f));

  return inputFiles;
};

esl_symbolic.readInputFile = function (file) {
  const jsonString = fs.readFileSync(file, "utf-8");
  if (jsonString == undefined)
    throw new Error(`Could not read input file: ${file}`);
  esl_symbolic.INPUT = JSON.parse(jsonString);
};

esl_symbolic.number = function (varName) {
  const value = getValue(varName, input_types.float); // __esl_symbolic_number uses flt_symbol()
  return value ? value : 0.0;
};

esl_symbolic.index = function (varName) {
  const value = getValue(varName, input_types.float); // __esl_symbolic_index is a index(flt_symbol())
  return value ? value : 0.0;
};

esl_symbolic.string = function (varName) {
  const value = getValue(varName, input_types.string);
  return value ? value : "";
};

esl_symbolic.boolean = function (varName) {
  const value = getValue(varName, input_types.boolean);
  return value ? value : true;
};

esl_symbolic.assume = function (_) {
  return;
};

esl_symbolic.assert = function (condition) {
  if (condition !== true) {
    throw new Error("Assert Failed");
  }
};
module.exports = esl_symbolic;
