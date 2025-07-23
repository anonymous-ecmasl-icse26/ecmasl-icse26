// ---------------------------------- tests -----------------------------------
const buckets = require("../../src/lib/multidictionary");
const esl_symbolic = require("esl_symbolic");

var dict = new buckets.MultiDictionary()

var s1 = esl_symbolic.string("s1");
var s2 = esl_symbolic.string("s2");
var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");

// esl_symbolic.assume(!(x1 == x2));
esl_symbolic.assume(esl_symbolic.neq(x1, x2));

dict.set(s1, x1);
dict.set(s2, x2);

var res1 = dict.remove(s1, x1);
esl_symbolic.assert(res1);
var res2 = dict.remove(s1, x2);

// esl_symbolic.assert(((s1 == s2) && (!(x1 == x2)) && res2) || (((!(s1 == s2)) || ((s1 == s2) && (x1 == x2))) && (!res2)));
esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.eq(s1, s2),
            esl_symbolic.neq(x1, x2),
            res2
        ),
        esl_symbolic.and(
            esl_symbolic.or(
                esl_symbolic.neq(s1, s2),
                esl_symbolic.and(
                    esl_symbolic.eq(s1, s2),
                    esl_symbolic.eq(x1, x2)
                )
            ),
            esl_symbolic.not(res2)
        )
    )
);
var dict2 = new buckets.MultiDictionary();
dict2.set(s1, x1);
dict2.set(s1, x2);
var res3 = dict2.remove(s1);
esl_symbolic.assert(res3);
var res5 = dict2.remove(s1);

// esl_symbolic.assert(!res5);
esl_symbolic.assert(esl_symbolic.not(res5));

dict2.set(s2, x1);
var res4 = dict2.remove(s2, x2);

// esl_symbolic.assert(!res4);
esl_symbolic.assert(esl_symbolic.not(res4));
