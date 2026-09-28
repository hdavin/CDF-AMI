# Net：四种 SM 网络数据集生成

根据附件 `net_generate.m` 整理，采用与前面实验相同的“主函数 + private 辅助函数 + results 输出”结构。包内包含已在 MATLAB 中生成的数据和图形。

## 运行

在 MATLAB 中将当前目录切换到本 `Net` 文件夹，运行：

```matlab
datasets = main_generate_networks;
```

默认生成 Random、Regular、Clustered、Disconnected 四种网络，每个网络 100 个节点，区域为 200×200 米。任意两节点的欧氏距离严格小于 30 米时连边，无向、无自环。无需 Optimization Toolbox 或 NIRA；使用 MATLAB 的 `graph`、`conncomp`、`tiledlayout` 和 `exportgraphics`。本包在 MATLAB R2026a 上验证。

其他入口：

```matlab
main_plot_networks;       % 只读取结果并重新绘图
main_validate_networks;   % 检查数据、保存格式和随机种子复现
```

使用新种子和新输出目录：

```matlab
datasets = main_generate_networks(struct( ...
    'seed',20260930, ...
    'visible','off', ...
    'outputDir',fullfile(pwd,'results_seed2')));

main_plot_networks(fullfile(pwd,'results_seed2'));
main_validate_networks(fullfile(pwd,'results_seed2'));
```

只生成一种网络：

```matlab
datasets = main_generate_networks(struct( ...
    'networks',{{'Random'}}, ...
    'outputDir',fullfile(pwd,'results_random')));
```

默认种子为 `20260929`。每种拓扑使用固定的种子偏移，因此生成某个网络的结果不会受到网络调用顺序影响。程序恢复调用者原有的随机数状态。同一输出目录再次生成时，会更新所选网络文件和本次运行的汇总文件；需要保留不同配置时，请使用不同的 `outputDir`。绘图和校验入口按最近一次汇总中的网络列表读取数据。

## 与附件的对应关系

| 网络 | 坐标生成规则 | 验收条件 |
|---|---|---|
| Random | 在 200×200 米区域内均匀随机采样 | 整体连通 |
| Regular | `linspace(15,185,10)` 构成 10×10 规则网格 | 整体连通 |
| Clustered | 中心为 (100,100)、(40,40)、(160,40)、(40,160)、(160,160)，每簇 20 个节点 | 整体连通 |
| Disconnected | 中心为 (40,40)、(40,160)、(160,40)、(160,160)，每簇 25 个节点 | 恰好 4 个连通分量，各簇内部连通、簇间无边 |

Clustered 和 Disconnected 均保留原代码的共享随机候选池（1000 个点）、每簇包含中心点、按候选池原顺序选择且不重复使用点的规则。其余节点距离簇中心分别在 `(0.3*Lim,1.2*Lim)` 和 `(0.3*Lim,1.7*Lim)` 内。坐标始终位于部署区域内。

修正了随机网络的未定义 `xy`、规则网络中误写坐标矩阵和未定义 `Edge` 等错误；移除了对附件未提供的 `isconnected`、`plot_net` 的依赖。

原脚本没有保证 Clustered 整体连通，也没有保证 Disconnected 恰好具有四个分量。本版本增加拒绝重采样：不符合表中连通性条件时重新生成整套坐标，不添加超过距离阈值的边，不缩小原采样半径。候选点不足时也重新采样；最多尝试 `maxAttempts=10000` 次，失败会明确报错，避免无限循环。论文描述应说明这些连通性筛选条件。

平均度由坐标和 30 米连接距离决定；本实验不强行控制平均度，也不是此前大规模实验的稀疏网络生成器。修改 `nodeCount`、`areaSize` 或 `radius` 会改变网络分布；规则网络要求节点数为完全平方数。改变区域尺寸时，规则网格与簇中心按区域尺寸同比缩放。

## 文件结构和数据字段

```text
Net/
  main_generate_networks.m
  main_plot_networks.m
  main_validate_networks.m
  private/                     生成、保存、绘图和校验辅助函数
  reference/net_generate_original.m
  results/
    data/
      Network_Random.mat       完整网络拓扑；其余三种网络同理
      Coordinates_Random.mat   坐标别名；其余三种网络同理
      xy_net1_Random.mat
      xy_net2_Regular.mat
      xy_net3_Cluster.mat
      xy_net4_Disconnected.mat
    figures/network_topologies.pdf/.svg/.png/.fig
    network_datasets.mat
    network_summary.csv
    validation_summary.csv
```

`Network_*.mat` 包含：`N`（节点数）、`xy`（N×2 坐标，米）、`Adj`（N×N 邻接矩阵）、`Lim`（连接距离）、`degree`（节点度）、`component`（连通分量编号）、`group`（采样簇编号）、`name` 和 `metadata`。元数据记录种子、尝试次数、分量大小、采样半径、MATLAB 版本等。

坐标文件均包含通用变量 `xy`，并保留原脚本坐标变量名作为别名，例如 `Net1_Random_xy` 和 `Net3_Cluster_xy`。`network_datasets.mat` 保存四组结构体、汇总表和选项。生成一种网络时只保存本次选择的网络。

读取示例：

```matlab
S = load(fullfile('results','data','Network_Random.mat'));
xy = S.xy;
Adj = S.Adj;
N = S.N;
```

## 用于后续实验

信任评估实验可将 `dataDir` 指向本包的 `results/data`，并使用同一连接距离。例如，在该信任评估实验文件夹运行：

```matlab
options = struct;
options.dataDir = fullfile('..','Net','results','data');
options.networks = {'Random','Regular','Clustered','Disconnected'};
options.radius = 30;
options.outputDir = fullfile(pwd,'results_new_networks');
analysis = main_trust_evaluation(options);
```

上例假设信任评估文件夹与 `Net` 同级，按实际目录调整路径。新数据应使用新的输出目录，避免读取旧拓扑的缓存。

本包依据附件生成的是**网络拓扑数据**。附件没有定义新的 `TV`、`SL`、`C` 或 `GAME`，因此本包不生成 `Parameter_*.mat` 或博弈 `Data_*.mat`。使用新拓扑进行资源分配实验前，需要针对该拓扑重新生成匹配的信任值、安全级别和容量；不能直接拼接旧拓扑的参数。密度实验使用 `Coordinates_*.mat` 时，也应保证其基准参数与所用节点和拓扑一致。

## 绘图

四种网络合并为一张 2×2 图。红色节点代表 SM，蓝色线代表通信链路，横纵轴均以米为单位。PDF 和 SVG 为矢量图，PNG 为 300 dpi，FIG 保留 MATLAB 原生可编辑对象，并保存为 `Visible='on'`。

```matlab
fig = openfig(fullfile('results','figures','network_topologies.fig'),'new','visible');
plotedit(fig,'on');
```

## 校验

校验包括坐标范围和唯一性、邻接矩阵对称性、无自环、所有边与严格距离规则完全一致、无孤立节点、各网络的连通性、分簇距离范围、文件别名一致性及固定种子重生成。具体运行结果见 `VALIDATION.md` 和 `results/validation_summary.csv`。
