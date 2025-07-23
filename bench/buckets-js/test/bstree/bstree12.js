// ---------------------------- our tests now ---------------------------------
const buckets = require("./../../src/lib/bstree");
const esl_symbolic = require("esl_symbolic");

var bst = new buckets.BSTree();
var h = bst.height();
esl_symbolic.assert(esl_symbolic.eq(h, -1));

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");

bst.add(x1);
bst.add(x2);

var height = bst.height();
// esl_symbolic.assert((!(x1 == x2) && (height == 1)) || ((x2 == x1) && (height == 0)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.neq(x1, x2),
            esl_symbolic.eq(height, 1)
        ),
        esl_symbolic.and(
            esl_symbolic.eq(x1, x2),
            esl_symbolic.eq(height, 0)
        ),
    )
);
