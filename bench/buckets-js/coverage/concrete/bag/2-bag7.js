const INPUT_DATA = {
  n1: {
    type: "real",
    value: 0.0,
  },
  n2: {
    type: "real",
    value: 0.0,
  },
  n3: {
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

bag.add(n1);
bag.add(n2);

var bag2 = new buckets.Bag();

var res1 = bag.equals(bag2);
esl_symbolic.assert(!res1);

var res3 = bag.equals([n1, n2, n3]);
esl_symbolic.assert(!res3);

bag.forEach(function (x) {
  if (x == n3) {
    return false;
  }
  bag2.add(x);
});

var res2 = bag.equals(bag2);
esl_symbolic.assert(
  (!(n3 == n1) && !(n3 == n2) && res2) || ((n3 == n1 || n3 == n2) && !res2),
);
