// -------------------------------- tests -------------------------------------
const buckets = require("./../../../src/lib/set");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    var set = new buckets.Set();

    var x1 = esl_symbolic.number("x1");
    var x2 = esl_symbolic.number("x2");

    set.add(x1);
    var res = set.add(x2);

    var x3 = esl_symbolic.number("x3");
    var res2 = set.contains(x3);
  });
});
