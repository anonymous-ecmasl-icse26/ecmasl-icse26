const INPUT_DATA = {
  x1: {
    type: "real",
    value: 0.0,
  },
  x2: {
    type: "real",
    value: 0.0,
  },
  x3: {
    type: "real",
    value: 0.5,
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

const buckets = require("../../../src/lib/set");

var set1 = new buckets.Set();
var set2 = new buckets.Set();

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");
var x3 = esl_symbolic.number("x3");

esl_symbolic.assume(!(x1 == x3));

set1.add(x1);
set1.add(x2);

set2.add(x3);
set2.add(x2);

var res1 = set1.equals(set2);
esl_symbolic.assert(!res1);

set2.add(x1);
var res2 = set1.equals(set2);
esl_symbolic.assert((x2 == x3 && res2) || (!(x2 == x3) && !res2));

var ar = [];
set2.forEach(function (x) {
  ar.push(x);
});

var res3 = set2.equals(ar);
esl_symbolic.assert(!res3);
