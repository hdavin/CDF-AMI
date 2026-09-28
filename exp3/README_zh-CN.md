# exp3：监控资源分配实验

运行 `analysis = main_fig8_fig9;`。可选 `main_fig7_fig8(struct('visible','on'))`。不再输入 eta。需要 Optimization Toolbox。

GRA：各节点按固定顺序使用 fmincon 最大化自身安全效用；GURA：集中最大化 sum_j SL_j log(1+s_j)；RRA：满容量随机分配，以同一安全效用评价。图7纵轴为 Total security utility。图8保持 GRA 接收资源与安全水平关系。

均衡误差检查采用最佳响应的乘子二分公式与凹函数上界。有效信任系数及安全权重正性在运行时检查。

GRA 的均衡误差与 GURA 的全局最优性误差分别校验。两者安全效用应接近。
