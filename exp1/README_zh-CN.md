# exp1：智能电表信任评估实验

本实验评估正常智能电表（normal SMs）与失陷智能电表（compromised SMs）的信任值，考察测试数据发送概率 `P_T` 和失陷节点比例 `P_C` 对评价结果的影响。每个网络输出两张图：固定 `P_C` 下的信任值分布图，以及不同 `P_C` 下的平均信任值曲线图。

本目录是信任评估实验，主入口为 `main_trust_evaluation.m`。它不求解 GRA/GURA 资源分配问题，也不计算安全效用或攻击损失。

本文档对应本次提供的 `exp1.zip` 源码。**当前默认测试概率为 `[0.3 0.5 0.7 0.9]`，每组参数重复 1000 次，默认只运行随机网络。** 随包已有随机网络的结果文件，可以直接重绘。

## 1. 运行环境

- MATLAB，需支持 `tiledlayout`、`exportgraphics`、`savefig`、`jsonencode` 和隐式数组扩展等代码中使用的功能。
- 完整计算需要启用 MATLAB 的 Java 虚拟机：缓存摘要通过 Java 的 SHA-256 接口计算。不要使用 `-nojvm` 启动完整实验。
- 不调用 Optimization Toolbox 或 Parallel Computing Toolbox；条纹绘图函数已包含在源码中，无需另外安装条纹工具箱。
- 图形使用 Times New Roman 字体；系统缺少该字体时，显示效果可能不同。

本次 README 整理依据源码和随包图注核对入口、默认参数及统计定义，未重新执行完整仿真，也未验证最低兼容 MATLAB 版本。

## 2. 文件结构

```text
exp1/
├── README.md
├── main_trust_evaluation.m       # 完整计算、保存数据和绘图
├── main_plot_trust.m             # 读取已有结果，仅重绘
├── data/
│   ├── xy_net1_Random.mat
│   ├── xy_net2_Regular.mat
│   ├── xy_net3_Cluster.mat
│   └── xy_net4_Disconnected.mat
├── private/
│   ├── te_options.m              # 默认参数与输入检查
│   ├── te_load_network.m         # 由坐标生成邻接矩阵
│   ├── te_trustworthiness.m      # 信任评估算法
│   ├── te_run.m                  # 参数遍历、重复实验和缓存
│   ├── te_hash.m                 # 缓存键和随机种子摘要
│   ├── te_plot.m                 # 两类结果图及条纹绘制
│   ├── te_export.m               # 图形导出
│   └── te_write_tables.m         # CSV 与图注导出
└── results/
    ├── analysis_results.mat      # 汇总结果及运行参数
    ├── cache/                    # 每个完整参数组合的缓存
    ├── mean_trustworthiness.csv
    ├── trust_distribution.csv
    ├── figure_captions.txt
    └── 图形文件
```

保留 `private/` 与主函数之间的目录关系。不要把内部函数移到其他位置，也无需单独运行它们。压缩包中的 `__MACOSX/` 和 `.DS_Store` 是系统附加信息，不参与实验。

## 3. 快速开始

将 MATLAB 的“当前文件夹”切换到解压后的 `exp1` 目录。以下示例均以此为起点。

### 3.1 读取已有结果，只重新绘图

```matlab
results = main_plot_trust;
```

该入口默认读取 `results/analysis_results.mat`，显示图窗，并按保存结果中的参数重新生成两类图。**不会重新运行信任评估仿真。**

如果更换电脑或移动目录后提示 `Data folder does not exist`，请使用第 9 节的路径修复方法。

将重绘结果存入新目录：

```matlab
base = pwd;
plotOptions = struct;
plotOptions.visible = 'on';
plotOptions.outputDir = fullfile(base,'replots');
plotOptions.formats = {'pdf','svg','png','fig'};

results = main_plot_trust(fullfile(base,'results'),plotOptions);
```

`main_plot_trust` 只导出图形；它不会在 `replots` 中另存汇总 MAT、CSV 或图注文件。

### 3.2 按默认参数运行完整实验

```matlab
results = main_trust_evaluation;
```

默认复用匹配的缓存，缺少的参数组合才重新计算。默认 `visible='off'`，因此运行完成后可能没有图窗，但图形已导出至 `results/`。

需要计算时显示图窗，可运行：

```matlab
results = main_trust_evaluation(struct('visible','on'));
```

### 3.3 先进行小规模试运行

```matlab
options = struct;
options.repetitions = 10;
options.attackRates = [0.1 0.5 0.9];
options.visible = 'on';
options.outputDir = fullfile(pwd,'results_quick');

results = main_trust_evaluation(options);
```

这是检查运行流程的快速配置，不是论文中每组 1000 次重复的正式配置。`attackRates` 必须包含 `distributionPC`，默认即 `0.5`。

## 4. 实验设置

### 4.1 网络与攻击生成

- 从 `data/` 读取固定的合成网络坐标；本实验不在每次重复中重新生成拓扑。
- 两个节点的欧氏距离严格小于 `radius` 时建立无向链路，对角线置零。
- 节点数由坐标矩阵的行数决定；随包随机网络结果使用 `N=100`。
- 网络可以有多个连通分量，但当前实现要求每个节点至少有一个邻居。
- 每次重复从全部 `N` 个节点中均匀、不放回地选取 `floor(P_C*N)` 个失陷节点。因此，自定义网络上实际失陷比例为 `floor(P_C*N)/N`。
- 在默认 20 轮交互中，每轮以概率 `P_T` 决定是否采用测试数据；同一次重复中的各节点共享这组测试轮次标记。
- 失陷节点减少合作资源投入和产生异常行为的随机事件，按照 `maliciousProbability` 分别生成。正常节点未额外加入独立随机误报，但仍可能受到程序中的多数表决惩罚规则影响。

### 4.2 默认参数

所有参数可通过传入 `options` 覆盖；默认值集中在 `private/te_options.m`。

| 字段 | 默认值 | 含义 |
|---|---|---|
| `networks` | `{'Random'}` | 运行的网络 |
| `testRates` | `[0.3 0.5 0.7 0.9]` | 测试数据发送概率 `P_T` |
| `attackRates` | `0.05:0.05:0.95` | 失陷节点比例 `P_C` |
| `distributionPC` | `0.5` | 信任值分布图使用的 `P_C` |
| `repetitions` | `1000` | 每个 `(网络, P_T, P_C)` 组合的重复次数 |
| `rounds` | `20` | 每次重复的交互轮数 |
| `radius` | `30` | 通信距离阈值，单位与输入坐标一致 |
| `maliciousProbability` | `0.1` | 失陷节点产生对应恶意行为的概率 |
| `punishment` | `10` | 测试数据揭示异常行为时的惩罚系数 |
| `resource` | `1` | 正常合作时每条有向链路的资源投入 |
| `epsilon` | `1e-10` | 归一化和信任计算的分母稳定常数 |
| `seed` | `20260924` | 派生各参数组合随机种子的基础种子 |
| `binEdges` | `0:0.2:1` | 分布图的分箱边界 |
| `resume` | `true` | 是否读取匹配缓存 |
| `plotResults` | `true` | 完整计算后是否绘图 |
| `visible` | `'off'` | 完整运行时图窗是否显示 |
| `formats` | `{'pdf','svg','png','fig'}` | 图形导出格式 |
| `dataDir` | 主函数目录下的 `data/` | 输入数据位置 |
| `outputDir` | 主函数目录下的 `results/` | 输出和缓存位置 |

默认单个网络共有 `4 × 19 = 76` 个参数组合，对应 76,000 次随机仿真。分布图直接使用其中 `P_C=0.5` 的结果，不额外运行一套实验。

### 4.3 运行全部四个网络

```matlab
options = struct;
options.networks = {'Random','Regular','Clustered','Disconnected'};
options.outputDir = fullfile(pwd,'results_all_networks');

results = main_trust_evaluation(options);
```

每个网络分别输出两张图，四个网络共八张图，并非将四个网络合并到同一张图。`Clustered` 对应的数据文件名为 `xy_net3_Cluster.mat`，两者拼写不同是当前程序的既定映射。

### 4.4 修改测试概率或其他计算参数

例如，若需要使用 `P_T=[0.1 0.3 0.5 0.7]`：

```matlab
options = struct;
options.testRates = [0.1 0.3 0.5 0.7];
options.outputDir = fullfile(pwd,'results_PT_01357');

results = main_trust_evaluation(options);
```

修改参数后应调用 `main_trust_evaluation`；`main_plot_trust` 只允许覆盖 `visible`、`outputDir` 和 `formats`，不能改变实验参数或重新计算数据。

`testRates` 和 `attackRates` 应严格递增；每个攻击比例下均须至少存在一个正常节点和一个失陷节点。建议不同实验配置使用不同输出目录，避免同名汇总文件和图形相互覆盖。

## 5. 统计指标与图形含义

### 5.1 信任值分布图

文件名：`trust_distribution_<Network>.*`。

- 固定 `P_C=distributionPC`；各子图对应不同 `P_T`。
- 正常 SM 使用蓝色斜线底纹，失陷 SM 使用红色交叉底纹。
- 对应分箱为 `[0,0.2)`、`[0.2,0.4)`、`[0.4,0.6)`、`[0.6,0.8)`、`[0.8,1]`。
- 收集所有重复中的邻居对目标节点的评价分数，再按目标属于正常或失陷类别分别统计百分比。两类分布各自归一化至 100%。

### 5.2 平均信任值曲线图

文件名：`mean_trustworthiness_<Network>.*`。

- 横轴是 `P_C`，各子图对应不同 `P_T`。
- 蓝色圆点曲线表示正常 SM，红色方块曲线表示失陷 SM。
- 每次重复先对同一类别目标收到的所有有效邻接评价求平均，再对重复实验的均值取平均。
- 误差棒为重复实验均值之间的一个样本标准差（`std(...,0,1)`），不是标准误或置信区间。

这里采用**评价边加权**的统计方式，并包含正常和失陷两类评价者。一个目标获得的邻居评价越多，对汇总均值的权重越大；不是先给每个目标求均值后再对目标等权平均，也不是仅使用正常评价者。应在论文中保持同一统计定义。

## 6. 输出文件与结果读取

| 输出 | 内容 |
|---|---|
| `analysis_results.mat` | 变量 `results`，包括选项、拓扑、汇总统计和每次重复的类别均值 |
| `mean_trustworthiness.csv` | 各网络、`P_T`、`P_C` 下两类均值、标准差和重复次数 |
| `trust_distribution.csv` | 各分箱中两类目标的评价百分比及边界含义 |
| `figure_captions.txt` | 根据实际运行参数生成的英文图注 |
| `trust_distribution_<Network>.*` | 信任值分布图 |
| `mean_trustworthiness_<Network>.*` | 平均信任值曲线图 |
| `cache/<Network>_<hash>.mat` | 单个参数组合的结果和对应配置 |

PDF 和 SVG 按矢量方式导出，PNG 分辨率为 300 dpi，FIG 保留 MATLAB 图形对象。

读取随机网络结果：

```matlab
z = load(fullfile(pwd,'results','analysis_results.mat'),'results');
results = z.results;
r = results.Random;

results.options.testRates     % 本次实际使用的 P_T
results.options.attackRates   % 本次实际使用的 P_C
results.groupOrder            % {'Normal','Compromised'}
r.meanTrust(:,:,1)            % 正常 SM 的均值
r.meanTrust(:,:,2)            % 失陷 SM 的均值
r.stdTrust                   % 重复实验均值之间的标准差
r.pointSeeds                 % 各参数组合的随机种子
```

设攻击比例数为 `np`、测试概率数为 `nt`、分箱数为 `nb`、重复次数为 `R`：

| 字段 | 数组维度 |
|---|---|
| `meanTrust`、`stdTrust` | `np × nt × 2` |
| `trialMeans` | `R × np × nt × 2` |
| `histCounts`、`histPercent` | `nb × nt × 2` |
| `distributionObservations` | `nt × 2` |
| `pointSeeds` | `np × nt` |

最后一维始终按正常、失陷排列。完整逐边信任矩阵 `T` 不会为每次重复单独保存。

## 7. 缓存与复现

缓存以完整参数组合为单位保存。中断后以相同配置再次运行，可以复用已经完成的组合；尚未完整保存的组合需要重新运行。

缓存键包含网络邻接关系、`P_T`、`P_C`、重复次数、分箱边界、主要模型参数及信任函数源码摘要。只修改图形格式不会使计算缓存失效。修改 `te_trustworthiness.m` 的内容会改变对应摘要，下一次完整运行会使用新的缓存键；**直接重绘仍然读取已有汇总结果，不会自动重新计算。**

不同参数组合的随机种子由配置摘要分别派生，因此本程序没有为不同 `P_T` 或 `P_C` 强制共享同一组攻击节点和随机交互历史。相同配置、邻接关系与信任函数源码用于复现相同的随机计算流程；各点种子保存在 `pointSeeds` 中。

忽略现有缓存并重新计算：

```matlab
options = struct;
options.resume = false;
options.outputDir = fullfile(pwd,'results_fresh');

results = main_trust_evaluation(options);
```

若修改了 `te_run.m` 中的统计逻辑，仅修改该文件不会自动改变信任函数的源码摘要。此时应使用新的输出目录或 `resume=false`，避免复用旧逻辑产生的缓存。

## 8. 当前算法版本说明

本压缩包保留了原上传信任算法的多数表决和 TOPSIS 处理规则，包括对多数表决条件成立的行整体赋值，以及部分理想解在整行上取值。相关实现位于 `private/te_trustworthiness.m`，本 README 没有修改这些规则。

当前代码最后一步为：

```matlab
T = (Adj.*dn)./(dn+dp+o.epsilon);
```

因此，邻接位置的信任值为

\[
\tau_{ij}=\frac{d_{ij}^{-}}{d_{ij}^{+}+d_{ij}^{-}+\varepsilon}.
\]

**分子不包含 `epsilon`。** 当两种距离均为零时，本实现返回零；它没有将这种情况设为 0.5 或 1。分母稳定常数也不保证所有邻接信任值严格为正。

如果论文采用了“分子也加 `epsilon`”、只在邻居集合内计算理想解或其他平局规则，则属于不同的算法版本，需要同步实现并重新计算相关结果，不能仅修改图注。本目录 README 如实描述当前压缩包中的版本。

## 9. 常见问题

### 9.1 运行后没有图窗

完整实验默认 `visible='off'`，用于自动导出。可设置 `visible='on'`，或运行 `main_plot_trust` 显示已有结果。

对已经保存但可见性为关闭状态的 FIG：

```matlab
fig = openfig(fullfile(pwd,'results','trust_distribution_Random.fig'), ...
    'new','visible');
set(fig,'MenuBar','figure','ToolBar','figure');
plotedit(fig,'on');
```

分布图中的底纹由独立线段和矩形构成，部分对象关闭了鼠标选取。统一修改字体、条纹或配色时，建议修改 `private/te_plot.m` 后重新绘图；不要把底纹当作一个普通 `bar` 对象编辑。

### 9.2 更换电脑后，仅重绘提示数据目录不存在

`analysis_results.mat` 保存了原运行时的绝对路径，而 `main_plot_trust` 会检查保存的 `dataDir`。即使只绘图，新机器上也可能因为旧路径失效而报错。

以下操作在新目录中保存一份仅修正路径的结果副本，不修改原始汇总文件或数值数据：

```matlab
base = pwd;  % 当前文件夹应为解压后的 exp1
sourceDir = fullfile(base,'results');
replotDir = fullfile(base,'results_relocated');
if ~isfolder(replotDir), mkdir(replotDir); end

z = load(fullfile(sourceDir,'analysis_results.mat'),'results');
results = z.results;
results.options.dataDir = fullfile(base,'data');
results.options.outputDir = replotDir;
save(fullfile(replotDir,'analysis_results.mat'),'results','-v7');

main_plot_trust(replotDir,struct('visible','on'));
```

### 9.3 怎样调整字体、子图标识、底纹和导出质量？

- 坐标刻度和轴标题字号：修改 `te_plot.m` 的 `styleAxes`。
- 子图标识字号与位置：修改 `panelLabel`。
- 条纹间距、粗细及条形宽度：修改 `hatch.spacing`、`hatch.lineWidth`、`hatch.groupWidth`、`hatch.barFraction`。
- 导出设置：修改 `te_export.m`，或通过 `formats` 选择输出格式。
- 布局或窗口尺寸改变后，建议重新运行 `main_plot_trust`，使底纹根据最终轴尺寸重新生成。

这些绘图调整不需要重算信任值。

### 9.4 修改通信半径后出现孤立节点错误

当前模型要求每个 SM 至少有一个邻居。请检查输入坐标与 `radius`，不要直接删除断言后继续运行，因为后续信任统计依赖有效的邻接评价。

### 9.5 如何确认论文使用的是哪一组参数？

以实际结果文件中的 `results.options` 和同次运行生成的 `figure_captions.txt` 为准。文件名本身不包含 `P_T` 或重复次数，不能仅凭图名判断参数版本。
