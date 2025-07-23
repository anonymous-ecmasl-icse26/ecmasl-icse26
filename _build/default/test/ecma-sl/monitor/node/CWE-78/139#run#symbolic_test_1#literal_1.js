'use strict'

const sh = require('execa').shell

module.exports = function (port) {
  if (!Number.parseInt(port)) {
    return Promise.reject(new Error('Invalid argument provided for port'))
  }

  if (process.platform === 'win32') {
    return sh(
      `Stop-Process -Id (Get-NetTCPConnection -LocalPort ${port}).OwningProcess -Force`
    )
  }

  return sh(
    `lsof -i tcp:${port} | grep LISTEN | awk '{print $2}' | xargs kill -9`
  )
}

// Vuln: command-injection
var aux = "`touch success`";
var o = {
  toString: function() {
  	this.toString = function () {return aux};
  	return "2" }
}
upg_var("aux", "H");
taint.set_sink(sh);
module.exports(o);
