var o = {};
o.p = 42;
taint.get_prop_level(o, "p");
taint.upg_prop(o, "p", "High"); 
taint.get_prop_level(o, "p");

taint.set_sink(eval);
eval(o.p);
