const INPUT_DATA = {
  s1: {
    type: "str",
    value: "!0!",
  },
  s2: {
    type: "str",
    value: "!1!",
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

const buckets = require("../../../src/lib/dictionary");

var dict = new buckets.Dictionary();

var x1 = esl_symbolic.number("x1"); //1
var x2 = esl_symbolic.number("x2"); //2
var s1 = esl_symbolic.string("s1"); // "2"
var s2 = esl_symbolic.string("s2"); // "foo"

esl_symbolic.assume(!(s1 == s2));

dict.set(s1, x1);
dict.set(s2, x2);

var keys = dict.keys();
var l1 = keys.length;
esl_symbolic.assert(l1 == 2);
var t1 = keys[0];
var t2 = keys[1];
esl_symbolic.assert((t1 == s1 && t2 == s2) || (t1 == s2 && t2 == s1));

var values = dict.values();
var l2 = keys.length;
esl_symbolic.assert(l2 == 2);
var y1 = values[0];
var y2 = values[1];
esl_symbolic.assert((y1 == x1 && y2 == x2) || (y1 == x2 && y2 == x1));
