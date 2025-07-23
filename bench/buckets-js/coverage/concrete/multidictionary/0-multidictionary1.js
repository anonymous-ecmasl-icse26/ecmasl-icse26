const INPUT_DATA = {
  s1: {
    type: "str",
    value: "",
  },
  s2: {
    type: "str",
    value: "",
  },
  s3: {
    type: "str",
    value: "B",
  },
  x1: {
    type: "real",
    value: -1.0,
  },
  x2: {
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

const buckets = require("../../../src/lib/multidictionary");

var dict = new buckets.MultiDictionary();

var s1 = esl_symbolic.string("s1");
var s2 = esl_symbolic.string("s2");
var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");

dict.set(s1, x1);
dict.set(s2, x2);

var res1 = dict.set(s1, undefined);
esl_symbolic.assert(!res1);

var s3 = esl_symbolic.string("s3");
esl_symbolic.assume(!(s1 == s3));
esl_symbolic.assume(!(s2 == s3));
var res2 = dict.get(s3).length;
esl_symbolic.assert(res2 == 0);

var res = dict.get(s1).length;

esl_symbolic.assert(
  (s1 == s2 && !(x1 == x2) && res == 2) ||
    (s1 == s2 && x1 == x2 && res == 1) ||
    (!(s1 == s2) && res == 1),
);
