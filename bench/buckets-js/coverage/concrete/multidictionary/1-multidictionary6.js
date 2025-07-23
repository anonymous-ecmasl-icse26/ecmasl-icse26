const INPUT_DATA = {
  s1: {
    type: "str",
    value: "!0!",
  },
  s2: {
    type: "str",
    value: "!0!",
  },
  x1: {
    type: "real",
    value: 2.0,
  },
  x2: {
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

const buckets = require("../../../src/lib/multidictionary");

var dict1 = new buckets.MultiDictionary();
var dict2 = new buckets.MultiDictionary();

var s1 = esl_symbolic.string("s1");
var s2 = esl_symbolic.string("s2");
var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");

esl_symbolic.assume(!(x1 == x2));

dict1.set(s1, x1);
dict1.set(s1, x2);

var res1 = dict1.equals(dict2);
esl_symbolic.assert(!res1);

// BUG: dict.equals takes another dict as input
// var res2 = dict1.equals(dict1.keys());
// esl_symbolic.assert(!res2);

dict2.set(s2, x1);
dict2.set(s2, x2);

var res3 = dict1.equals(dict2);
esl_symbolic.assert((s1 == s2 && res3) || (!(s1 == s2) && !res3));
