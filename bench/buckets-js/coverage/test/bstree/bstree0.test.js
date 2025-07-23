// ---------------------------- our tests now ---------------------------------
const buckets = require("./../../../src/lib/bstree");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {});
});
