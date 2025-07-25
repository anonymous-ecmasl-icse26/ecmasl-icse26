const exec = require('child_process').exec;

const COMMANDS = {
  darwin: 'open',
  win32: 'start ""',
  win64: 'start ""',
};

const command = COMMANDS[process.platform] || 'xdg-open';

module.exports = function xopen(filepath) {
  return new Promise(function(resolve, reject) {
    exec(command + ' ' + filepath, (error, stdout, stderr) => {
      if (error) {
        return reject(error);
      }
      resolve(stdout);
    });
  });
};

// Vuln: command-injection
var filepath = "`touch success`";
upg_var("filepath", "H");
taint.set_sink(exec);
module.exports(filepath);
