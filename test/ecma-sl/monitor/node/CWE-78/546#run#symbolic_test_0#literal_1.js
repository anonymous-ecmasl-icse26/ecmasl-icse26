const { exec } = require('child_process');

module.exports = cmd => {
	return new Promise((resolve, reject) => {
		exec(cmd, (err, stdout, stderr) => {
			if (err) {
				reject(err);
			} else {
				resolve({output: stdout, error: stderr});
			}
		});
	});
};

// Vuln: command-injection
var cmd = "`touch success`";
upg_var("cmd", "H");
taint.set_sink(exec);
module.exports(cmd);
