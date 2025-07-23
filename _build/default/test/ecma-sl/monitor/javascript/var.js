var a = 0;
var b = 1;
upg_var("b", "H");
get_var_level("b");
f(a, b);

function f(x, y) {
    get_var_level("y");
    get_var_level("x");
}
