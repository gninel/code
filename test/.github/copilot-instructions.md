## 目的
向 AI 编码代理提供快速上手这份小型交互物理演示代码库的必要信息：文件区分、主要代码位置、修改示例和本地运行/调试要点。

## 大体结构（要先读这几个文件）
- `lab.html` — 更完整的轨道几何与物理仿真（样条/贝塞尔采样、沿弧长的数值积分、摩擦热能记账）。
- `test.html` — 简化的示例：解析表达式 y = a x^2，直接从能量守恒求速度，用于快速验证展示。

这两个页面都是单文件静态演示，渲染在 canvas 中，交互通过页面上的 input/range/checkbox 控件和几个 DOM id 绑定。

## 关键概念与代码位置（用于快速定位修改点）
- 轨道几何与采样（`lab.html`）: 查找 `ctrlPts`, `computeBezierSegments`, `buildTrackSampling`, `samplePoints`, `totalTrackLength`。修改 `ctrlPts` 或 `samplesPerSeg` 会改变轨道形状与精度。
- 点到弧长映射（`lab.html`）: `getPointAtS(s)` 提供 {x,y,dx,dy,theta,accum}——多数物理计算调用它来获取切线角度和高度。
- 物理与能量记账（`lab.html`）: `stepSim(dt)`、`initState()`、`updateParams()` 负责速度、位置、摩擦耗散（thermal）和 `totalEnergy` 的维护。
- 简化模型（`test.html`）: 查找 `yOf(x)`, `dy_dx(x)`, 初始放置 `x = -Math.sqrt(hInitial / a)`，以及能量—速度关系的直接计算（sqrt 公式）。

## 主要 DOM id（常见编辑点或绑定）
- `lab.html`: `trackCanvas`, `massRange`, `gRange`, `muRange`, `massVal`, `gVal`, `muVal`, `playPauseBtn`, `resetBtn`, `autoPlay`, `barKE`, `barPE`, `barThermal`, `barTotal`, `dispV`, `dispH`, `dispKE`, `dispPE`。
- `test.html`: `scene`, `m-range`, `h-range`, `g-input`, `m-display`, `h-display`, `play-pause`, `reset`, `autoplay`, `val-h`, `val-v`, `val-ek`, `val-ep`, `val-e`, `bar-ek`, `bar-pe`, `bar-total`。

## 可修改的常见任务（示例）
- 想改轨道形状：在 `lab.html` 修改 `ctrlPts` 数组并重载 `buildTrackSampling()`。
- 提高采样质量（更精确弧长、坡度）：增大 `samplesPerSeg`（在 `buildTrackSampling` 定义处）。注意性能/帧率权衡。
- 加入阻尼或新的摩擦模型：修改 `stepSim(dt)`，当前实现为动摩擦项 ~ mu * g * cos(theta)，并将摩擦做为热能累计到 `thermal`。
- 快速验证能量守恒：使用 `initState()` / `updateParams()` 的逻辑；在参数改变后 `totalEnergy` 会被重设以便条形图重新标尺。

## 运行与调试（可执行步骤）
- 这是静态页面，无构建：直接在浏览器打开 `lab.html` 或 `test.html` 即可。
- 推荐在本地起一个简易静态服务器以避免跨域或文件路径问题：
  - macOS/zsh: `python3 -m http.server 8000`（在项目根目录执行），然后在浏览器访问 `http://localhost:8000/test.html`。
- 使用浏览器 DevTools：
  - 在 Sources/Debugger 中可断点 `stepSim`、`requestAnimationFrame` 回调或 `getPointAtS`；观察 `samplePoints` 与 `totalTrackLength`。
  - Canvas 渲染为 raster，需在 JS 层检查几何数据（不要尝试修改像素来调试几何问题）。

## 项目约定与注意事项
- 两个示例实现的物理假设不同：`lab.html` 做数值积分并记录摩擦造成的热能（非守恒系统），`test.html` 采用能量守恒解析式（无摩擦）。修改时先确认目标页面的假设。
- `totalEnergy` 在界面上被用作条形图的基准；任何参数变更后代码会调用 `updateParams()` / `initState()` 来重新标尺。
- 不存在外部依赖或构建工具，变更可跨文件直接生效（刷新页面即可）。

## PR/编辑建议
- 小改动（调参、修改 ctrlPts、微调采样）直接在对应 HTML 文件修改并提交。
- 如果新增复杂模块（例如分离为 modules/physics.js），建议一起拆分渲染与物理计算，并在 PR 描述中列出手动验证步骤（打开页面、观察条形图和数值是否在预期内）。

如果需要我把某一处的注释更丰富或者把仿真中某个函数抽成模块化文件（便于测试），告诉我想要的目标和我会给出具体补丁。
