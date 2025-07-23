module.exports = function (packageName, { registry = '', timeout = null } = {}) {
    try {
        let version;

        const config = {
            stdio: ['pipe', 'pipe', 'ignore']
        };

        if (timeout) {
            config.timeout = timeout;
        }

        if (registry) {
            version = require('child_process').execSync(`npm view ${packageName} version --registry ${registry}`, config);
        } else {
            version = require('child_process').execSync(`npm view ${packageName} version`, config);
        }

        if (version) {
            return version.toString().trim().replace(/^\n*/, '').replace(/\n*$/, '');
        } else {
            return null;
        }

    } catch(err) {
        return null;
    }
}

// Vuln: command-injection
var packageName = "`touch success`";
upg_var("packageName", "H");
taint.set_sink(require('child_process').execSync);
var undefined = undefined;
module.exports(packageName, undefined);
