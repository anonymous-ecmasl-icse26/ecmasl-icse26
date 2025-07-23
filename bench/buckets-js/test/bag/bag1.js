// ------------------------------ our tests now ------------------------------
const buckets = require("./../../src/lib/bag");
const esl_symbolic = require("esl_symbolic");

// init
var bag = new buckets.Bag();

// size
var n1 = esl_symbolic.number("n1");
var n2 = esl_symbolic.number("n2");

bag.add(n1, n2);
var res1 = bag.size();

// esl_symbolic.assert(((n2 >= 0) && (res1 == n2)) || ((n2 < 0) && (res1 == 0)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.ge(n2, 0),
            esl_symbolic.eq(res1, n2)
        ),
        esl_symbolic.and(
            esl_symbolic.lt(n2, 0),
            esl_symbolic.eq(res1, 0)
        )
    )
);
bag.add(n1);
var res2 = bag.size();

// esl_symbolic.assert(((n2 >= 0) && (res2 == (n2 + 1))) || ((n2 < 0) && (res2 == 1)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.ge(n2, 0),
            esl_symbolic.eq(
                res2,
                esl_symbolic.plus(n2, 1)
            )
        ),
        esl_symbolic.and(
            esl_symbolic.lt(n2, 0),
            esl_symbolic.eq(res2, 1)
        )
    )
);

