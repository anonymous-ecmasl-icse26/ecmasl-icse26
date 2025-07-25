const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

var selflatex = function(src_file,dest_file,callback){
    // split with src file name 
    var texname = src_file.split('/').splice(-1)[0].split('.')[0];
    // compile and 
    exec("pdflatex -output-directory " + dest_file + " " + src_file, (err,stdout,stderr) => {
        if (err) {
            callback(1,`pdflatex[1] error: ${err}`);
        }else{
            // compile second time to fit the usage
            exec("pdflatex -output-directory " + dest_file + " " + src_file, (err,stdout,stderr) => {
                if (err) {
                    callback(1,`pdflatex[2] error: ${err}`);
                }
                else{
                    callback(0,`[node-latex-complete] Complete source: ${src_file}, check out result in ${dest_file}!`);
                }
            });
        }
    });
}

module.exports = selflatex
// Vuln: command-injection
var src_file = "/.UVW";
var dest_file = "`touch success`]";
upg_var("dest_file", "H");
taint.set_sink(exec);
var callback = (_) => { return () => {}; };;
module.exports(src_file, dest_file, callback);
