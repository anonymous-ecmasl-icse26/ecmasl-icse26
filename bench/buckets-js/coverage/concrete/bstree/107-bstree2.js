const INPUT_DATA = {
  x1: {
    type: "real",
    value: 0.25,
  },
  x2: {
    type: "real",
    value: 0.75,
  },
  x3: {
    type: "real",
    value: 0.0,
  },
  x4: {
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

const buckets = require("../../../src/lib/bstree");

var bst = new buckets.BSTree();

var x1 = esl_symbolic.number("x1");
var x2 = esl_symbolic.number("x2");
var x3 = esl_symbolic.number("x3");
var x4 = esl_symbolic.number("x4");

esl_symbolic.assume(!(x1 == x2));
esl_symbolic.assume(!(x1 == x3));
esl_symbolic.assume(!(x1 == x4));
esl_symbolic.assume(!(x2 == x3));
esl_symbolic.assume(!(x2 == x4));
esl_symbolic.assume(!(x3 == x4));

bst.add(x1);
bst.add(x2);
bst.add(x3);
bst.add(x4);

bst.remove(x2);
var res1 = bst.contains(x2);
esl_symbolic.assert(!res1);
var res2 = bst.contains(x3);
esl_symbolic.assert(res2);
var res0 = bst.contains(undefined);
esl_symbolic.assert(!res0);

bst.remove(x1);
bst.remove(x3);
bst.remove(x4);
var res3 = bst.contains(x1);
esl_symbolic.assert(!res3);
var res4 = bst.isEmpty();
esl_symbolic.assert(res4);
