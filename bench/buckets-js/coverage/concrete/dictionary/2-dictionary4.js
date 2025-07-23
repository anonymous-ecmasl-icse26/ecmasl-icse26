const INPUT_DATA = {
  "s1": {
    "type": "str",
    "value": "B"
  },
  "s2": {
    "type": "str",
    "value": ""
  },
  "s3": {
    "type": "str",
    "value": "B"
  }
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

const buckets = require("../../../src/lib/dictionary");

var dict = new buckets.Dictionary();

var x1 = esl_symbolic.number("x1"); //1
var x2 = esl_symbolic.number("x2"); //2
var s1 = esl_symbolic.string("s1"); // "2"
var s2 = esl_symbolic.string("s2"); // "foo"

esl_symbolic.assume(!(s1 == s2));

dict.set(s1, x1);
dict.set(s2, x2);

var res1 = "";
var res2 = 0;
var s3 = esl_symbolic.string("s3");

dict.forEach(function (k, v) {
  if (k === s3) {
    return false;
  }
  res1 = res1 + k;
  res2 = res2 + v;
});

var c1 = s1 + s2;
var c2 = s2 + s1;
esl_symbolic.assert(
  (!(s3 == s1 || s3 == s2) && (res1 == c1 || res1 == c2)) ||
  ((s3 == s1 || s3 == s2) && (res1 == s1 || res1 == s2 || res1 == "")),
);

var y = x1 + x2;
esl_symbolic.assert(
  (!(s3 == s1 || s3 == s2) && res2 == y) ||
  ((s3 == s1 || s3 == s2) && (res2 == x1 || res2 == x2 || res2 == 0)),
);