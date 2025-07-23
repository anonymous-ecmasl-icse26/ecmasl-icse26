const INPUT_DATA = {
  n1: {
    type: "real",
    value: -0.5,
  },
  n2: {
    type: "real",
    value: 0.5,
  },
  n3: {
    type: "real",
    value: 0.0,
  },
  n4: {
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

const buckets = require("../../../src/lib/bag");

// init
var bag = new buckets.Bag();

// size
var n1 = esl_symbolic.number("n1");
var n2 = esl_symbolic.number("n2");
var n3 = esl_symbolic.number("n3");
var n4 = esl_symbolic.number("n4");

var res1 = bag.isEmpty();
esl_symbolic.assert(res1);
var res2 = bag.size();
esl_symbolic.assert(res2 == 0);

bag.add(n1);
bag.add(n1, n2);
var res3 = bag.isEmpty();
esl_symbolic.assert(!res3);
bag.remove(n1);
bag.remove(n3, n4);
bag.clear();
var res4 = bag.isEmpty();
esl_symbolic.assert(res4);
