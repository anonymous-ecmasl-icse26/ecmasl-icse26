// ---------------------------------- tests -----------------------------------
const buckets = require("./../../../src/lib/multidictionary");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    var dict1 = new buckets.MultiDictionary();
    var dict2;

    var s1 = esl_symbolic.string("s1");
    var s2 = esl_symbolic.string("s2");
    var x1 = esl_symbolic.number("x1");
    var x2 = esl_symbolic.number("x2");

    esl_symbolic.assume(!(x1 == x2));

    dict1.set(s1, x1);
    dict1.set(s1, x2);

    var res1 = dict1.equals(dict2);
    esl_symbolic.assert(!res1);

    dict2 = new buckets.MultiDictionary();

    dict2.set(s2, x1);
    dict2.set(s2, x2);

    var res3 = dict1.equals(dict2);
    esl_symbolic.assert((s1 == s2 && res3) || (!(s1 == s2) && !res3));
  });
});
