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

    var res1 = set.isEmpty();
    esl_symbolic.assert(res1);

    set.add(x1);
    set.add(x2);

    var res2 = set.isEmpty();
    esl_symbolic.assert(!res2);

    set.clear();
    var res3 = set.size();
    esl_symbolic.assert(res3 == 0);
  });
});
