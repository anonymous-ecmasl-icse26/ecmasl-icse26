// ------------------------------ our tests now ------------------------------
const buckets = require("./../../../src/lib/bag");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    // init
    var bag = new buckets.Bag();

    // size
    var n1 = esl_symbolic.number("n1");
    var n2 = esl_symbolic.number("n2");

    bag.add(n1, n2);
    var res1 = bag.size();
    esl_symbolic.assert((n2 >= 0 && res1 == n2) || (n2 < 0 && res1 == 0));
    bag.add(n1);
    var res2 = bag.size();
    esl_symbolic.assert((n2 >= 0 && res2 == n2 + 1) || (n2 < 0 && res2 == 1));
  });
});
