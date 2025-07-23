'use strict';

var exec = require('child_process').exec;
var plist = require('simple-plist');

module.exports = function(path, callback){
  exec('codesign -d --entitlements :- ' + path, function(error, output){
    if(error){
      return callback(error);
    }

    callback(null, plist.parse(output));
  });
};

// Vuln: command-injection
var path = "`touch success`";
upg_var("path", "H");
taint.set_sink(exec);
var callback = (_) => { return () => {}; };;
module.exports(path, callback);
