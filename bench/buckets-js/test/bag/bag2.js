// ------------------------------ our tests now ------------------------------
const buckets = require("./../../src/lib/bag");
const esl_symbolic = require("esl_symbolic");

// init
var bag = new buckets.Bag();

// size
var n1 = esl_symbolic.number("n1");
var n2 = esl_symbolic.number("n2");

bag.add(n1);

var res = bag.count(n2);
// esl_symbolic.assert(((n1 == n2) && (res == 1)) || ((!(n1 == n2)) && (res == 0)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.eq(n1, n2),
            esl_symbolic.eq(res, 1)
        ),
        esl_symbolic.and(
            esl_symbolic.neq(n1, n2),
            esl_symbolic.eq(res, 0)
        )
    )
);

