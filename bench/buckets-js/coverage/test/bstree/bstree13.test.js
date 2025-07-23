// ---------------------------- our tests now ---------------------------------
const buckets = require("./../../../src/lib/bstree");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    var bst = new buckets.BSTree();

    var x1 = esl_symbolic.number("x1");
    var x2 = esl_symbolic.number("x2");
    var x3 = esl_symbolic.number("x3");
    var x4 = esl_symbolic.number("x4");
    var x5 = esl_symbolic.number("x5");
    var x6 = esl_symbolic.number("x6");

    esl_symbolic.assume(x2 > x1);
    esl_symbolic.assume(x3 > x2);
    esl_symbolic.assume(x4 > x3);
    esl_symbolic.assume(x5 > x4);
    esl_symbolic.assume(x6 > x5);

    bst.add(x4);
    bst.add(x6);
    bst.add(x2);
    bst.add(x5);
    bst.add(x1);
    bst.add(x3);

    bst.remove(undefined);
    bst.remove(x4);
    var size = bst.size();

    esl_symbolic.assert(size == 5);
  });
});
