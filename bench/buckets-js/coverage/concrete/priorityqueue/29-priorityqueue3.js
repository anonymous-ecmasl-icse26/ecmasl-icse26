const INPUT_DATA = {
  x1: {
    type: "real",
    value: -1.0,
  },
  x2: {
    type: "real",
    value: 0.0,
  },
  x3: {
    type: "real",
    value: 0.0,
  },
};

const INPUT_TYPES = {
  string: "str",
  integer: "int",
  float: "real",
  boolean: "bool",
};

const esl_symbolic = {
  getValue(varName, targetType) {
    const variable = INPUT_DATA[varName];
    if (!variable) return undefined;

    const type = variable.type;
    const value = variable.value;

    if (type !== targetType) {
      throw new Error(
        `ERROR: ${varName} has type ${type} but ${targetType} was expected`,
      );
    }
    return value;
  },

  number(varName) {
    const value = this.getValue(varName, INPUT_TYPES.float); // __esl_symbolic_number uses flt_symbol()
    return value ? value : 0.0;
  },

  index(varName) {
    const value = this.getValue(varName, INPUT_TYPES.float); // __esl_symbolic_index is a index(flt_symbol())
    return value ? value : 0.0;
  },

  string(varName) {
    const value = this.getValue(varName, INPUT_TYPES.string);
    return value ? value : "";
  },

  boolean(varName) {
    const value = this.getValue(varName, INPUT_TYPES.boolean);
    return value ? value : true;
  },

  assume(_) {
    return;
  },

  assert(condition) {
    if (condition !== true) {
      throw new Error("Assert Failed");
    }
  },
};

const buckets = require("../../../src/lib/priorityqueue");

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
