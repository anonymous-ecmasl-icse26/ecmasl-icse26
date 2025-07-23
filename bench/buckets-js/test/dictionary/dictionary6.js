// --------------------------------- tests -----------------------------------
const buckets = require("./../../src/lib/dictionary");
const esl_symbolic = require("esl_symbolic");

var dict = new buckets.Dictionary();

var x1 = esl_symbolic.number("x1"); //1
var x2 = esl_symbolic.number("x2"); //2
var s1 = esl_symbolic.string("s1"); // "2"
var s2 = esl_symbolic.string("s2"); // "foo"

dict.set(s1, x1);
dict.set(s2, x2);

var res1 = dict.size();

// esl_symbolic.assert(((s1 == s2) && (res1 == 1)) || ((!(s1 == s2)) && (res1 == 2)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.eq(s1, s2),
            esl_symbolic.eq(res1, 1)
        ),
        esl_symbolic.and(
            esl_symbolic.neq(s1, s2),
            esl_symbolic.eq(res1, 2)
        )
    )
);
var res2 = dict.isEmpty();

// esl_symbolic.assert(!res2);
esl_symbolic.assert(esl_symbolic.not(res2));

dict.clear();
var res3 = dict.isEmpty();
esl_symbolic.assert(res3);
var res4 = dict.size();

// esl_symbolic.assert(res4 == 0);
esl_symbolic.assert(esl_symbolic.eq(res4, 0));
