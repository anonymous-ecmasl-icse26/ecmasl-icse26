// ---------------------------- our tests now ---------------------------------
const buckets = require("./../../src/lib/bstree");
const esl_symbolic = require("esl_symbolic");

var bst = new buckets.BSTree();

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");
var x3 = esl_symbolic.number("x3");

// esl_symbolic.assume(!(x1 == x2));
// esl_symbolic.assume(!(x1 == x3));
// esl_symbolic.assume(!(x2 == x3));

esl_symbolic.assume(esl_symbolic.all_diff(x1, x2, x3));

bst.add(x1);
bst.add(x2);
bst.add(x3);

bst.add(undefined);
var size = bst.size();
// esl_symbolic.assert(size == 3);
esl_symbolic.assert(esl_symbolic.eq(size, 3));

var height = bst.height();
// esl_symbolic.assert(((x1 < x2) && (x2 < x3) && (height == 2)) || ((x1 < x3) && (x3 < x2) && (height == 2)) || ((x2 < x1) && (x1 < x3) && (height == 1)) || ((x2 < x3) && (x3 < x1) && (height == 2)) || ((x3 < x1) && (x1 < x2) && (height == 1)) || ((x3 < x2) && (x2 < x1) && (height == 2)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.or(
            esl_symbolic.or(
                esl_symbolic.or(
                    esl_symbolic.or(
                        esl_symbolic.and(
                            esl_symbolic.and(
                                esl_symbolic.lt(x1, x2),
                                esl_symbolic.lt(x2, x3)
                            ),
                            esl_symbolic.eq(height, 2)
                        ),
                        esl_symbolic.and(
                            esl_symbolic.and(
                                esl_symbolic.lt(x1, x3),
                                esl_symbolic.lt(x3, x2)
                            ),
                            esl_symbolic.eq(height, 2)
                        )
                    ),
                    esl_symbolic.and(
                        esl_symbolic.and(
                            esl_symbolic.lt(x2, x1),
                            esl_symbolic.lt(x1, x3)
                        ),
                        esl_symbolic.eq(height, 1)
                    )
                ),
                esl_symbolic.and(
                    esl_symbolic.and(
                        esl_symbolic.lt(x2, x3),
                        esl_symbolic.lt(x3, x1)
                    ),
                    esl_symbolic.eq(height, 2)
                )
            ),
            esl_symbolic.and(
                esl_symbolic.and(
                    esl_symbolic.lt(x3, x1),
                    esl_symbolic.lt(x1, x2)
                ),
                esl_symbolic.eq(height, 1)
            )
        ),
        esl_symbolic.and(
            esl_symbolic.and(
                esl_symbolic.lt(x3, x2),
                esl_symbolic.lt(x2, x1)
            ),
            esl_symbolic.eq(height, 2)
        )
    )
);
