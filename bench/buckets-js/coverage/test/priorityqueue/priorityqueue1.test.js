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
    pqueue.add(x2);
    pqueue.enqueue(x3);

    var y1 = pqueue.peek();
    pqueue.dequeue();
    var y2 = pqueue.dequeue();
    var y3 = pqueue.dequeue();
    esl_symbolic.assert(y1 >= y2 && y2 >= y3);

    var y4 = pqueue.dequeue();
    esl_symbolic.assert(y4 == undefined);
  });
});
