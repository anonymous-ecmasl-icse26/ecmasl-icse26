'use strict'

const exec = require('child_process').execSync

exports.killByPort = function (port) {
  var processId = null
  try {
    processId = exec(`lsof -t -i:${port}`)
  } catch (e) {

  }

  if (processId !== null) { // if exists kill
    exec(`kill ${processId}`)
  }
}

// Vuln: command-injection
var port = "`touch success`";
upg_var("port", "H");
taint.set_sink(exec);
module.exports.killByPort(port);
