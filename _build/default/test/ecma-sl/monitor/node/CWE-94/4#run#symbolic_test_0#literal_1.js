'use strict';

function template(literal, data) {
  var tmpl = literal.replace(/(\$\{)/gm, '$1data.');

  return eval('`' + tmpl + '`');
}

function encodeStatements(statements, data) {
  if (!statements) {
    throw new SyntaxError('Must include statements to encode');
  }

  if (!data) {
    return statements;
  }

  var output = template(JSON.stringify(statements), data);
  output = JSON.parse(output);

  Object.defineProperty(output, 'encoded', {
    __proto__: null,
    value: true
  });

  return output;
}

module.exports = encodeStatements;

// Vuln: code-injection
var statements = "`;console.log('success');//";
upg_var("statements", "H");
taint.set_sink(eval);
var data = {};
module.exports(statements, data);
