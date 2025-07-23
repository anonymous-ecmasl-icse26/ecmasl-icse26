// ---------------------------------- tests ----------------------------------
const buckets = require("./../../src/lib/linkedlist");
const esl_symbolic = require("esl_symbolic");

var list = new buckets.LinkedList()

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");
var x3 = esl_symbolic.number("x3");
var x4 = esl_symbolic.number("x4");

// esl_symbolic.assume(!(x1 == x2));
// esl_symbolic.assume(!(x1 == x3));
// esl_symbolic.assume(!(x2 == x3));

esl_symbolic.assume(esl_symbolic.all_diff(x1, x2, x3));

list.add(x1)
list.add(x2);
list.add(x3, x4)

var res1 = list.contains(x3);

// esl_symbolic.assert((((x4 == 0) || (x4 == 1) || (x4 == 2)) && res1) || ((!(x4 == 0)) && (!(x4 == 1)) && (!(x4 == 2)) && (!res1)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.or(
                esl_symbolic.or(
                    esl_symbolic.eq(x4, 0),
                    esl_symbolic.eq(x4, 1)
                ),
                esl_symbolic.eq(x4, 2)
            ),
            res1
        ),
        esl_symbolic.and(
            esl_symbolic.and(
                esl_symbolic.neq(x4, 0),
                esl_symbolic.neq(x4, 1)
            ),
            esl_symbolic.neq(x4, 2),
            esl_symbolic.not(res1)
        )
    )
);


var res2 = list.contains(undefined);
// esl_symbolic.assert(!res2);
esl_symbolic.assert(esl_symbolic.not(res2));
