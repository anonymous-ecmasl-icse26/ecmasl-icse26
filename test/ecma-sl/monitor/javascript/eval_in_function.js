var o = {};
o.x = 0;
o.y = 1;
taint.upg_prop(o, "y", "H");
taint.get_prop_level(o, "x");
taint.get_prop_level(o, "y");
taint.set_sink(eval);
f(o.x, o.y);

function f(x, y) {
    eval(x);
}
