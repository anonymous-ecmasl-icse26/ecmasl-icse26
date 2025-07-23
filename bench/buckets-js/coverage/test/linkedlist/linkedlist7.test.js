// ---------------------------------- tests ----------------------------------
const buckets = require("./../../../src/lib/linkedlist");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    var list = new buckets.LinkedList();

    var x1 = esl_symbolic.number("x1");
    var x2 = esl_symbolic.number("x2");
    var x3 = esl_symbolic.number("x3");

    esl_symbolic.assume(!(x1 == x2));
    esl_symbolic.assume(!(x1 == x3));
    esl_symbolic.assume(!(x2 == x3));

    list.add(x1);
    list.add(x2);
    list.add(x3);

    list.clear();
    var res = list.isEmpty();
    esl_symbolic.assert(res);
  });
});
