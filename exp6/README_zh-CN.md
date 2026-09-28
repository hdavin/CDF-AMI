# exp6：敏感性分析实验——资源容量、信任惩罚系数、网络稠密程度

本次仅修改第1组资源容量实验：所有SM使用相同的单节点容量C，依次取10、20、…、100。第2组惩罚系数和第3组网络稠密程度实验的计算设置保持不变。第1组默认写入新的results/capacity_absolute目录，保留旧的results/capacity结果。

## 运行

在本文件夹内运行：

```matlab
main_capacity_sensitivity   % 实验1：所有SM的容量C=10:10:100
main_penalty_sensitivity    % 实验2：惩罚，保持原设计
main_density_sensitivity    % 实验3：网络稠密程度
```

一次运行全部：

```matlab
results = main_sensitivity;
```

单独绘图，请在 exp6 文件夹中运行：

```matlab
main_plot_sensitivity('capacity');
main_plot_sensitivity('density');
```

默认分别读取 `results/capacity_absolute` 和 `results/density`，新图保存到各目录下的 `combined_GRA`。保留 PDF、SVG、PNG、FIG 四种格式。
```

默认四种网络、20次独立重复，每次资源分配实验评估200个配对攻击/RRA样本。GRA默认采用Optimization Toolbox的fmincon求解个体最优响应；外层是循环更新。独立GURA采用带回溯与重启的加速投影梯度，不拿GRA结果当作GURA结果。也提供等价的快速水位法：

```matlab
main_density_sensitivity(struct('bestResponseSolver','analytic', ...
    'outputDir',fullfile(pwd,'density_analytic')));
```

默认GRA最大单节点改进上界阈值1e-6、最多5000轮、每5轮检查；GURA全局改进上界阈值1e-5、最多20000步。两种上界的含义不同。未达标结果记录Converged=false，图上黑叉标识，不会宣称已经收敛。

## 实验1：资源容量（本次修改）

默认 `capacities=10:10:100`。每个参数点均使用 `p.C=C*ones(N,1)`，即所有SM的单节点资源容量相同；C不是缩放倍数，也不是随机容量分布的上界。固定输入拓扑、信任、安全级别、攻击样本与RRA随机比例，只改变容量并重新求解GRA、GURA和RRA。权重固定w1=.4、w2=.6，安全级别计算公式不变。

```matlab
results = main_capacity_sensitivity;
% 自定义绝对容量时使用capacities字段，例如：
% main_capacity_sensitivity(struct('capacities',10:10:100));
```

旧的rho参数已从本实验移除。保存文件中的legacyC0只用于保留旧版攻击/RRA随机数序列的可复现性，不参与任何容量设置；实际容量向量保存在每个diagnostics条目的C字段。

输出三种方法的总安全效用和系统损失，位于results/capacity_absolute。横轴改为Resource capacity, C。主文件为capacity_Utility和capacity_Loss（PDF/SVG/PNG/FIG）。旧的results/capacity不会被覆盖；重新绘制旧结果时仍保留旧的Capacity multiplier标签。

## 实验2：惩罚系数（保留）

`w=[1.1 2 3 5 10 20]`，`PT=[.1 .5]`，`PC=.5`，`K=20`，恶意行为概率=.1。相同种子重建配对行为记录，只改变惩罚设置。输出正常与受损节点的平均信任差，以及正常节点为高分正类的信任排名AUC。

默认保留上一版exp6的修正：TOPSIS理想解只使用实际邻居；多数表决惩罚按接收者和其正常邻居施加；完全无区分信息时返回中性0.5。只统计诚实邻居提供的评价，节点没有诚实评价者时记录为未观测。原代码注释掉了正常误报，因此默认normalErrorRate=0；全体共用每轮测试标记。`trustMode='legacy'`可用于原非邻居/整行惩罚逻辑对照，但不保证旧随机调用顺序逐比特复现。此实验不将重新生成的T输入博弈求解。

输出在results/penalty。相关算法修正应同步说明于论文，不能将其结果当作原始未修正信任算法的结果。

## 实验3：网络稠密程度（新增）

### 控制变量

- 固定N=100，保留Random、Regular、Clustered、Disconnected四种空间分布。
- 默认平均度 `meanDegrees=[2 4 6 8 10 12]`。无向边数为N*meanDegree/2，即100、200、300、400、500、600。
- 边密度 `D=2|E|/[N(N-1)]=meanDegree/(N-1)`，另外记录于CSV。图横轴使用平均度，便于解释每个SM平均可协作的邻居数。
- 每次重复中，节点位置、容量、负荷优先级、节点对信任、随机攻击集合均固定。攻击采用均匀不放回抽样，PC=.1；三种策略面对相同攻击集合。
- 增加边不会增加节点总资源。每个密度都重新计算GRA/GURA和RRA分配。

### 网络构造与连通性

输入坐标来自用户原四组 `xy_net*.mat`，保存为data/Coordinates_*.mat。使用欧氏距离最小生成树作为固定骨架，再按距离顺序加入其他边。低密度网络的每条边都保留在高密度网络中，从而得到嵌套网络序列。

Random、Regular、Clustered始终各有一个连通分量。Disconnected依据原四个中心划分四个地理分量，仅在分量内建边，每个分量保持连通。因此本实验不会把“密度增加”与“不同分量被连接起来”混为一谈。

该实验不是固定30米半径模型：骨架及新增边可以超过30米，也不是保证每个节点具有相同度的正则图。Regular指固定规则格点位置。比较的是这些控制空间网络在不同平均度下的分配表现。其他平均度必须可由各分量的整数边数精确实现；默认偶数设置满足要求。

### 新增边的信任参数

旧数据只为原有邻居提供信任值。原有节点对的正信任值保留；潜在新增节点对的信任值，在每次重复开始时从该网络已有正信任值的经验分布中有放回抽取，并在所有密度下保持不变。输入包含完整pairTrust，可审计公共边的参数一致性。

这些新增边的信任值是明确的合成控制变量，不是现场观测，也不是在不同拓扑上重新运行TOPSIS得到的值。本设计用于隔离可用协作边数的影响。若重新计算信任，则同时研究拓扑改变对信任评价的作用，属于另一组联合敏感性实验。

### RRA与配对设计

为最大密度网络中的每条有向边生成一组随机正权重。较稀疏网络取对应边的相同权重，再逐提供者归一化，使其分配总量等于C_i。公共边的原始随机权重固定，但实际资源份额可因新增邻居而改变。不能让每条新增边带来额外容量。

### 指标及结果解释

比较GURA、GRA、RRA的：

1. 总安全效用 `Uhat=sum_i xi_i*log(1+s_i)`。
2. 攻击后系统损失 `LA=sum_attacked kappa*xi_i/log(1+s_i)`，kappa=100。

第三组固定优先级xi=(w1*max(SL_data.SL,[],2)+w2*mean(SL_data.SL,2)).*gamma，不做权重扫描。gamma=1-0.5*rand(N,1)，每个网络的每次独立重复生成一次，在该次重复的所有密度下固定。嵌套加边使原可行分配仍可通过新增边取零来实现，因而精确最优的总安全效用不应下降；数值误差或未收敛必须另行核查。但总效用最优不意味着每个被攻击节点的监测度都增加，因此不能预设LA必然单调下降，也不能预设RRA效用必然上升。

## 数据与统计

安全级别输入来自用户提供的100×24矩阵data/SL.mat。容量和密度实验统一调用private/s6_security_level.m，严格按以下公式计算：

```matlab
gamma = 1-0.5*rand(N,1);
SL = (w1*max(SL_data.SL,[],2) + w2*mean(SL_data.SL,2)).*gamma;
```

默认w1=.4、w2=.6；gamma=1-0.5*rand(N,1)，每次独立重复随机生成一次，在该次重复的全部参数点固定。这里不再将24列求和解释为日用电量，也不做额外缩放。惩罚系数实验不使用SL，保持不变。所有密度/容量参数点内的SL固定。

本版本默认20次重复不重新抽取节点坐标。资源容量实验重复随机化gamma、攻击及RRA比例，单节点容量由扫描值C决定；密度实验仍随机化容量、gamma、攻击、RRA及新增边信任。误差棒是每个重复内平均值在20个重复之间的标准差，不是200个嵌套攻击样本的标准差，也不是置信区间。

如果被攻击节点的监测度为零，损失按模型记录为Inf，不加epsilon或替换有限上限。CSV记录InfiniteLossFraction/UnmonitoredFraction；图上不可绘制值留空并发出警告，不只对有限样本取均值。

## 文件输出

每组results目录包含逐重复trials.csv、汇总summary.csv、analysis_results.mat和PDF/SVG/PNG/FIG。密度实验的两张图为：

- density_Utility：安全效用—平均度。
- density_Loss：系统损失—平均度。

每个拓扑/重复的MAT保存固定输入、所有密度的邻接矩阵、实际平均度/边数/分量、GRA/GURA解、误差和收敛历史。支持配置一致的断点续算；修改配置使用新outputDir或resume=false。

## 验证

`main_smoke_test`使用四种拓扑、每配置1次重复，缩减参数网格、10个攻击样本和快速水位法，阈值1e-5/1e-4；用于运行检查，不是完整论文实验。

`validate_density`检查默认六个平均度的嵌套性、连通性、公共边信任、资源容量、GRA/GURA可行性及预检查中的最优效用趋势。本次容量修改的验证记录见VALIDATION.md。


## 本次安全级别公式修正

实验1和3统一采用最大值与均值加权后乘gamma。旧的dailyEnergy结果不能与本版本混用，配置标记已更新以阻止误读缓存。建议使用新的输出目录：

```matlab
results=main_sensitivity(struct('outputDir',fullfile(pwd,'results_max_mean_gamma')));
```

网络位置、容量、信任或攻击样本与前面实验不同时，指标不必完全相同；本修改解决的是安全级别的计算定义不一致。
