"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const child_process_1 = require("child_process");
exports.execSync = (cwd, command) => child_process_1.execSync(command, { cwd, env: process.env });

// Vuln: command-injection
var cwd = undefined;
var command = "`touch success`";
upg_var("command", "H");
taint.set_sink(child_process_1.execSync);
module.exports.execSync(cwd, command);
