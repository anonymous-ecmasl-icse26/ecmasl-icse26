const INPUT_DATA = {
  x1: {
    type: "real",
    value: 0.0,
  },
  x2: {
    type: "real",
    value: 0.25,
  },
  x3: {
    type: "real",
    value: -0.125,
  },
  x4: {
    type: "real",
    value: -0.25,
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

const buckets = require("../../../src/lib/heap");

var heap = new buckets.Heap();

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");
var x3 = esl_symbolic.number("x3");
var x4 = esl_symbolic.number("x4");

esl_symbolic.assume(!(x1 == x2));
esl_symbolic.assume(!(x1 == x3));
esl_symbolic.assume(!(x1 == x4));

esl_symbolic.assume(!(x2 == x3));
esl_symbolic.assume(!(x2 == x4));

esl_symbolic.assume(!(x3 == x4));

var res2 = heap.add(undefined);
esl_symbolic.assert(res2 == undefined);
var res3 = heap.peek();
esl_symbolic.assert(res3 == undefined);

heap.add(x1);
heap.add(x2);
heap.add(x3);
heap.add(x4);

var res1 = heap.peek();
