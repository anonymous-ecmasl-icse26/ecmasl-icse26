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
list.add(x2)
list.add(x3);

var res = list.remove(x4);

// esl_symbolic.assert((((x4 == x1) || (x4 == x2) || (x4 == x3)) && res) || ((!((x4 == x1) || (x4 == x2) || (x4 == x3)) && (!res))));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.or(
                esl_symbolic.or(
                    esl_symbolic.eq(x4, x1),
                    esl_symbolic.eq(x4, x2)
                ),
                esl_symbolic.eq(x4, x3)
            ),
            res
        ),
        esl_symbolic.and(
            esl_symbolic.not(
                esl_symbolic.or(
                    esl_symbolic.or(
                        esl_symbolic.eq(x4, x1),
                        esl_symbolic.eq(x4, x2)
                    ),
                    esl_symbolic.eq(x4, x3)
                )
            ),
            esl_symbolic.not(res)
        )
    )
);

list.remove(x1);
list.remove(x2);
list.remove(x3);
var res2 = list.size();
// esl_symbolic.assert(res2 == 0);
esl_symbolic.assert(esl_symbolic.eq(res2, 0));
