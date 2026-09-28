# Exp4: 相对损失对比实验

运行 `analysis = main_fig10;`。可选 `main_fig10(struct('visible','on'))`。不再输入 eta；需要 Optimization Toolbox。`replot_figures` 仅重绘已有结果。

GRA 使用无成本的循环个体最佳响应（fmincon）；GURA 集中最大化无成本总安全效用；RRA 保留原来的满容量随机分配，无成本扣减。仅生成图9，不新增其他图。图9指标为相对系统损失 Delta L_A，原图没有 Total net security utility 标签。

沿用上传 exp2 的四个网络、随机种子20260921、200次实验、10%随机受攻击节点；每轮三种策略共享同一攻击集合。系统损失保持原 Lsm.m 定义，kappa=100。


GRA/GURA优化总安全效用，并非直接最小化攻击损失；相对损失可以为负，保留原值。
