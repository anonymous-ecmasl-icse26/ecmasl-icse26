const esl_symbolic = require("esl_symbolic");

var s1 = esl_symbolic.string("s1");
var s2 = esl_symbolic.string("s2");

esl_symbolic.eq(s1 + "a", s2 + "b");
