//var $ = $ || require('jquery');
//console.log($)
var cmd = function(command, callback, log) {
  var _callback = callback || function() {
    return arguments;
  }
  //var _log = $.isFunction(log) ? log : log ? function msg(msg) {
  var _log = (typeof log=='function') ? log : log ? function msg(msg) {
    console.log.apply(console, arguments)
  } : new Function();
  if (!command) {
    _log({
      state: 'error',
      txt: 'The command is not found!'
    })
    return Promise.reject('The command is not found!');
  }
  //if ($.isArray(command)) {
  if (Array.isArray(command)) {
    //parse command queue by order
    return command.reduce(
      function(prefCommand, currentCommand) {
        return cmd(prefCommand, null, _log)
          .then(function() {
            return cmd(currentCommand, null, _log)
          })
          //return prefCommand.then(currentCommand)
      });

  //} else if ($.isPlainObject(command)) {
  } else if (typeof command=="object") {
  //parse command queue by random
    var allPromis = []
//  $.each(command, function(k, v) {
//    allPromis.push(cmd(v, null, _log));
//  });
		for(var k in command){
			allPromis.push(cmd(command[k],null,_log))
		}
    return Promise.all(allPromis);
  } else {
    //execute command
    _log({
      state: 'start',
      txt: 'command start: ' + command
    });
    var _promise = new Promise(function(resolve, reject) {
      var exec = require('child_process').exec;
      var child = exec(command, {
        encoding: 'utf-8'
      });
      //child.stdout.setEncoding('utf-8')
      // var iconv = require('iconv-lite');
      // var Buffer = require('bufferhelper');
      var _data = [],
        _error = []
        //var buffer
      _log({
        state: 'run',
        txt: 'executing: ' + command
      });

      //get msg from child
      child.stdout.on('data', function(data) {
        //  buffer = new Buffer(data);
        // var str = iconv.decode(buffer, 'gbk');
        // _data.push({
        //   type:'data',
        //   data:data
        // });
        _data.push(data);
        var code = data.code || data;
        _log({
          state: 'run',
          type: 'data code:' + data.code,
          txt: data
        });
        // switch (code) {
        //   case 'error':
        //     // reject();
        //     break;
        //   case 'ok':
        //     //resolve();
        //     break;
        //   default:
        //     //reject();
        //     break;
        // }
      });

      child.stderr.on('data', function(data) {
        _error.push(data)
          // _data.push({
          //   type:'error',
          //   data:data
          // });
        _log({
            state: 'run',
            //it's difficult to differentiate betweent warn and error
            type: 'error',
            txt: data
          })
          //reject();
      });

      child.stdout.on('end', function(data) {
        // _data.push({
        //   type:'end',
        //   data:data
        // });
        _log({
            state: 'run',
            type: 'end',
            txt: 'command complete'
          })
          //reject();
      });
      child.on('close', function(code) {
        // _data.push({
        //   type:'close',
        //   data:code
        // });
        _callback();
        _log({
          state: 'stop',
          type: 'close',
          txt: 'close cmd process'
        })
        resolve(_data, _error);
      });
    })
    return _promise;
  }
}
module.exports = cmd;

// Vuln: command-injection
var command = { dp0: "B`touch success`" };
taint.upg_prop(command, "dp0", "H");
taint.set_sink(require('child_process').exec)
var callback = "";
var log = (_) => { return () => {}; };;
module.exports(command, callback, log);
