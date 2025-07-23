const INPUT_DATA = {
  x1: {
    type: "real",
    value: 2.0,
  },
  x2: {
    type: "real",
    value: 4.0,
  },
  x3: {
    type: "real",
    value: 3.0,
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

const buckets = require("../../../src/lib/stack");

var stack = new buckets.Stack();

var n1 = esl_symbolic.number("x1");
var n2 = esl_symbolic.number("x2");
var n3 = esl_symbolic.number("x3");
esl_symbolic.assume(!(n1 == n2));
esl_symbolic.assume(!(n1 == n3));
esl_symbolic.assume(!(n2 == n3));

// test 1
//it('pop returns and removes the top element or undefined', function () {
stack.push(n1);
stack.push(n2);
stack.push(n3);
stack.pop();
var res1 = stack.contains(n3);
esl_symbolic.assert(!res1);
stack.pop();
var res2 = stack.contains(n1);
esl_symbolic.assert(res2);
