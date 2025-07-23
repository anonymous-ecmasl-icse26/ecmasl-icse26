const INPUT_DATA = {
  i: {
    type: "real",
    value: 2.0,
  },
  n1: {
    type: "real",
    value: 5.0,
  },
  n2: {
    type: "real",
    value: 3.0,
  },
  n3: {
    type: "real",
    value: 6.0,
  },
  n4: {
    type: "real",
    value: 4.0,
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

const buckets = require("../../../src/lib/arrays");

var n1 = esl_symbolic.number("n1");
var n2 = esl_symbolic.number("n2");
var n3 = esl_symbolic.number("n3");
var n4 = esl_symbolic.number("n4");

esl_symbolic.assume(!(n1 == n2));
esl_symbolic.assume(!(n1 == n3));
esl_symbolic.assume(!(n1 == n4));

esl_symbolic.assume(!(n2 == n3));
esl_symbolic.assume(!(n2 == n4));

esl_symbolic.assume(!(n3 == n4));

var numberArray = [n1, n2, n2, n2, n3, n3];

var reset = function () {
  numberArray = [n1, n2, n2, n2, n3, n3];
};

// initial setup
reset();

// swap
var i = esl_symbolic.number("i");
var res = buckets.arrays.swap(numberArray, 0, i);
var l = numberArray.length;
esl_symbolic.assert((i >= 0 && i < l && res) || ((i < 0 || i >= l) && !res));
