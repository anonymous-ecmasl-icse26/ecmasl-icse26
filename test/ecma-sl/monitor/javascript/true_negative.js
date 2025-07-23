var o = {};
o.p = 42;
taint.set_sink(eval);
eval(o.p);
