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

    pqueue.dequeue();

    var res = pqueue.contains(x1);
    esl_symbolic.assert(
      ((x1 <= x2 || x1 <= x3) && res) || (x1 > x2 && x1 > x3 && !res),
    );
  });
});
