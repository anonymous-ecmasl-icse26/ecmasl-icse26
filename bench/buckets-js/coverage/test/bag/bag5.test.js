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

    bag.add(n1);
    bag.add(n2);

    var set = bag.toSet();
    var l = set.size();
    esl_symbolic.assert((n1 == n2 && l == 1) || (!(n1 == n2) && l == 2));
  });
});
