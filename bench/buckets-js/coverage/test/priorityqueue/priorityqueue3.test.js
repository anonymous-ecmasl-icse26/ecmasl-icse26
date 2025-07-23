// ------------------------------- our tests ----------------------------------
const buckets = require("./../../../src/lib/priorityqueue");
const esl_symbolic = require("./../../esl_symbolic");

// Get inputs from ../../inputs
const inputFiles = esl_symbolic.getInputs(__filename);

inputFiles.forEach((file) => {
  test(`Input file: ${file}`, () => {
    // Read input file
    esl_symbolic.readInputFile(file);

    var pqueue = new buckets.PriorityQueue();

    var x1 = esl_symbolic.number("x1");
    var x2 = esl_symbolic.number("x2");
    var x3 = esl_symbolic.number("x3");

    pqueue.enqueue(x1);
    pqueue.enqueue(x2);
    pqueue.enqueue(x3);

    var res1 = pqueue.size();
    esl_symbolic.assert(res1 == 3);
    pqueue.clear();
    var res2 = pqueue.isEmpty();
    esl_symbolic.assert(res2);
  });
});
