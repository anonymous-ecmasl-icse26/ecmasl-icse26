// ------------------------------ our tests now ------------------------------
const buckets = require("./../../src/lib/bag");
const esl_symbolic = require("esl_symbolic");

// init
var bag = new buckets.Bag();

// size
var n1 = esl_symbolic.number("n1");
var n2 = esl_symbolic.number("n2");
//var n3 = esl_symbolic.number();
//var n4 = esl_symbolic.number();
//esl_symbolic.assume(n3 > 0);
//esl_symbolic.assume(n4 > 0);

bag.add(n1, 7);
bag.add(n2, 8);

var ar = bag.toArray();

var res1 = buckets.arrays.frequency(ar, n1);
var res2 = buckets.arrays.frequency(ar, n2);
// esl_symbolic.assert((((n1 == n2) && (res1 == 15) && (res2 == 15))) || (((!(n1 == n2)) && (res1 == 7) && (res2 == 8))));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.and(
                esl_symbolic.eq(n1, n2),
                esl_symbolic.eq(res1, 15)
            ),
            esl_symbolic.eq(res2, 15)
        ),
        esl_symbolic.and(
            esl_symbolic.and(
                esl_symbolic.neq(n1, n2),
                esl_symbolic.eq(res1, 7)
            ),
            esl_symbolic.eq(res2, 8)
        )
    )
);

