// -------------------------------- tests -------------------------------------
const buckets = require("../../src/lib/set");
const esl_symbolic = require("esl_symbolic");

var set = new buckets.Set();

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");

set.add(x1);
set.add(x2);

var arr = set.toArray();
var len = arr.length;
esl_symbolic.assert(esl_symbolic.eq(len, 2));

