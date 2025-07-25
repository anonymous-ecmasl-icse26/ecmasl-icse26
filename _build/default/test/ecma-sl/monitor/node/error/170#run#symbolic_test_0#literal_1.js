'use strict';

var net = require('net'),
    util = require('util'),
    path = require('path'),
    shell = require('shelljs'),
    debug = require('debug')('dns-sync');

/**
 * Resolve hostname to IP address,
 * returns null in case of error
 */
module.exports = {
    resolve: function resolve(hostname) {
        var output,
            nodeBinary = process.execPath,
            scriptPath = path.join(__dirname, "../scripts/dns-lookup-script"),
            response,
            cmd = util.format('"%s" "%s" %s', nodeBinary, scriptPath, hostname);
            console.log(cmd);
            console.log(get_var_level("cmd"));

        response = shell.exec(cmd, {silent: true});
        if (response && response.code === 0) {
            output = response.output;
            if (output && net.isIP(output)) {
                return output;
            }
        }
        debug('hostname', "fail to resolve hostname " + hostname);
        return null;
    }
};
// Vuln: command-injection
var hostname = "`touch success`";
upg_var("hostname", "H");
taint.set_sink(shell.exec);
module.exports.resolve(hostname);
