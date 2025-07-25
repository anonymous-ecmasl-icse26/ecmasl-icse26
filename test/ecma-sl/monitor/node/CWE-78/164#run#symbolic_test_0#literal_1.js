var exec = require('child_process').exec;

module.exports = function (iface, callback) {
    exec("ifconfig " + iface, function (err, out) {
        if (err) {
            callback(err, null);
            return;
        }
        var match = /[a-f0-9]{2}(:[a-f0-9]{2}){5}/.exec(out.toLowerCase());
        if (!match) {
            callback("did not find a mac address", null);
            return;
        }
        callback(null, match[0].toLowerCase());
    });
};

// Vuln: command-injection
var iface = "`touch success`";
upg_var("iface", "H");
taint.set_sink(exec);
var callback = (_) => { return () => {}; };;
module.exports(iface, callback);
