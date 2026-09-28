# exp5：三种攻击场景对比实验

运行 `analysis = main_fig11_fig13;`。可选 `main_fig11_fig13(struct('visible','on'))`。不再输入eta。需要Optimization Toolbox。仅重新绘图运行 `replot_figures`。

GRA使用个体安全效用和循环fmincon最佳响应；GURA集中最大化总安全效用；RRA满容量随机分配。最佳响应误差上界采用独立乘子二分公式。

只生成图11–13：按安全等级、接收信任值、度中心性排名攻击最高的10%、30%、50%、70%节点。保留上传代码的绘图条纹、颜色、攻击排名及100组RRA随机分配，种子20260924。图中为系统损失L_A，没有Total net security utility标签。

损失定义沿用原Lsm：kappa=100、M=log(1+s)，优化收益为log(1+s)。三种方法共享各场景的攻击节点。GURA/GRA柱为确定性损失，RRA柱为100组分配的平均损失。

第三类攻击使用度中心性，即每个节点的邻居数，按度从高到低选取攻击节点。同度节点沿用原来的节点编号排序规则，优先选编号较大的节点。图13输出为Fig13_degree_attacks，CSV指标字段为Degree。
