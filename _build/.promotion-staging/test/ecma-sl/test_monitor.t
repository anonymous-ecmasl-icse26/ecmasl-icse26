Test monitor in ecma-sl:  
  $ ecma-sl interpret --monitor tt monitor/ecma-sl/upg_var.esl
  Variable y has level (Base of low)
  Variable y has level (Base of high)
  $ ecma-sl interpret --monitor tt monitor/ecma-sl/assign.esl
  Variable x has level (Base of high)
  $ ecma-sl interpret --monitor tt monitor/ecma-sl/calls.esl
  Variable z has level (Base of high)
  Adding sink eval
  HALT!!!
  Property p has level (Base of high)
  HALT!!!
  $ ecma-sl interpret --monitor tt monitor/ecma-sl/object.esl
  Property a has level (Base of low)
  Property b has level (Base of low)
  Property a has level (Base of high)
  Variable x has level (Base of low)
  Variable x has level (Base of high)
  Variable x has level (Base of low)
  Property b has level (Base of high)
  $ ecma-sl interpret --monitor tt monitor/ecma-sl/list.esl
  (Base of high)
  (Base of low)
  (Rec of [(Base of high); (Base of low); (Base of low)])
Test monitor in JavaScript:
  $ ecma-sl execute --monitor tt monitor/javascript/var.js
  monitor/javascript/
  monitor/javascript/var.js
  upg_var
  b
  H
  get_var_level
  Variable b has level (Base of high)
  get_var_level
  Variable y has level (Base of high)
  get_var_level
  Variable x has level (Base of low)
  $ ecma-sl execute --monitor tt monitor/javascript/true_negative.js
  monitor/javascript/
  monitor/javascript/true_negative.js
  set_sink
  Adding sink PerformEval
  $ ecma-sl execute --monitor tt monitor/javascript/true_positive.js
  monitor/javascript/
  monitor/javascript/true_positive.js
  get_prop_level
  Property p has level (Base of low)
  upg_prop
  High
  get_prop_level
  Property p has level (Base of high)
  set_sink
  Adding sink PerformEval
  HALT!!!
  $ ecma-sl execute --monitor tt monitor/javascript/eval_in_function.js
  monitor/javascript/
  monitor/javascript/eval_in_function.js
  upg_prop
  H
  get_prop_level
  Property x has level (Base of low)
  get_prop_level
  Property y has level (Base of high)
  set_sink
  Adding sink PerformEval
