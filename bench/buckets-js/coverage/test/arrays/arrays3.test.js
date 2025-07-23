// ------------------------------ our test now -------------------------------
const buckets = require("./../../../src/lib/arrays");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    var n1 = esl_symbolic.number("n1"); // 1
    var n2 = esl_symbolic.number("n2"); // 8
    var n3 = esl_symbolic.number("n3"); // 10
    var n4 = esl_symbolic.number("n4"); // 42

    esl_symbolic.assume(!(n1 == n2));
    esl_symbolic.assume(!(n1 == n3));
    esl_symbolic.assume(!(n1 == n4));

    esl_symbolic.assume(!(n2 == n3));
    esl_symbolic.assume(!(n2 == n4));

    esl_symbolic.assume(!(n3 == n4));

    var numberArray = [n1, n2, n2, n2, n3, n3];

    var reset = function () {
      numberArray = [n1, n2, n2, n2, n3, n3];
    };

    // initial setup
    reset();

    // contains
    var res6 = buckets.arrays.contains(numberArray, n1);
    var res7 = buckets.arrays.contains(numberArray, n4);
    esl_symbolic.assert(res6);
    esl_symbolic.assert(!res7);
  });
});
