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

    esl_symbolic.assume(!(x1 == x2));
    esl_symbolic.assume(!(x1 == x3));
    esl_symbolic.assume(!(x2 == x3));

    bst.add(x1);
    bst.add(x2);
    bst.add(x3);

    bst.clear();
    var res = bst.isEmpty();
    esl_symbolic.assert(res);
  });
});
