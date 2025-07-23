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

var bst2;
var res1 = bst.equals(bst2);
esl_symbolic.assert(esl_symbolic.not(res1));
bst2 = new buckets.BSTree();
var res2 = bst.equals(bst2);
esl_symbolic.assert(esl_symbolic.not(res2));

var x4 = esl_symbolic.number("x4");

bst2.add(x2);
bst2.add(x3);
bst2.add(x4);

var res3 = bst.equals(bst2);
// esl_symbolic.assert(((x4 == x1) && res3) || ((!(x4 == x1)) && (!res3)));

esl_symbolic.assert(
    esl_symbolic.or(
        esl_symbolic.and(
            esl_symbolic.eq(x4, x1),
            res3
        ),
        esl_symbolic.and(
            esl_symbolic.not(esl_symbolic.eq(x4, x1)),
            esl_symbolic.not(res3)
        )
    )
);
