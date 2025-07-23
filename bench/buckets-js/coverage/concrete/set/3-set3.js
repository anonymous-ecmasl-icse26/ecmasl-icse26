const INPUT_DATA = {
  s1: {
    type: "str",
    value: "B",
  },
  s2: {
    type: "str",
    value: "",
  },
  s3: {
    type: "str",
    value: "B",
  },
  s4: {
    type: "str",
    value: "",
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

var x1 = esl_symbolic.string("s1");
var x2 = esl_symbolic.string("s2");
var x3 = esl_symbolic.string("s3");
var x4 = esl_symbolic.string("s4");

set1.add(x1);
set1.add(x2);

set2.add(x3);
set2.add(x4);

var res1 = set2.isSubsetOf(set1);

set1.union(set2);

var res2 = set1.contains(x3);
var res3 = set2.isSubsetOf(set1);

esl_symbolic.assert(
  (((x3 == x1 || x3 == x2) && (x4 == x1 || x4 == x2) && res1) ||
    (((!(x3 == x1) && !(x3 == x2)) || (!(x4 == x1) && !(x4 == x2))) &&
      !res1)) &&
    res2 &&
    res3,
);
