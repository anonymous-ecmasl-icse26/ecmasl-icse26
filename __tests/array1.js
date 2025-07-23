const esl_symbolic = require("esl_symbolic");

var n1 = esl_symbolic.number("n1");
var n2 = esl_symbolic.number("n2");
var n3 = esl_symbolic.number("n3");

var i = esl_symbolic.index("i");

esl_symbolic.assume(esl_symbolic.all_diff(n1, n2, n3));

var arr = [n1, n2, n3];
arr[i];
