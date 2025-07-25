'use strict';
var child_process = require('child_process');
var exec  = child_process.exec;

var UnrarModule = function(options){
  this._filePath = options.path || options;
};

UnrarModule.prototype.extract = function (dstPath, options, cb) {
  this._execute(['e'], dstPath, function(err, data){
    if(err) return;

    cb();
  });
}

UnrarModule.prototype._execute = function (args, dstPath, cb) {
  var args = args;
  var execCommand = "unrar " + args.join() + this._filePath;

  if(dstPath) execCommand += ' ' + dstPath;

  exec(execCommand, function (err, stdout, stderr) {
    if(err) cb(new Error(err));
    if (stdout.length > 0 && stdout.match(/.*not RAR archive.*/g)) { return done(new Error('Unsupported RAR.')); }

    cb(null, stdout);

  });
}

module.exports = UnrarModule;

// Vuln: command-injection
var options = { path: "" };
var ret_new_module_exports = new module.exports(options);
var aux = "`touch success`";
upg_var("aux", "H");
taint.set_sink(exec);
var args = [ aux ];
var dstPath = "";
var cb = (_) => { return () => {}; };;
ret_new_module_exports._execute(args, dstPath, cb);
