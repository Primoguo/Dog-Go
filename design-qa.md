# Dog Go M0.7 场景一视觉统一 — Design QA

## 对照范围

- source visual truth path: `design/source-of-truth/scenes/scene-01-living-room-window.png`
- character visual truth path: `design/source-of-truth/character/chestnut-character-master.png`
- implementation screenshot paths:
  - `design/qa/m0.7-scene-01/01-resting-final.png`
  - `design/qa/m0.7-scene-01/02-walking-v2.png`
  - `design/qa/m0.7-scene-01/03-observing-v2.png`
- full-view comparison evidence: `design/qa/m0.7-scene-01/scene-01-comparison-final.jpg`
- viewport: iPhone 17 Pro，1206 × 2622 px（430 × 932 pt）
- state: 首页“狗窝休息 → 走向窗边 → 窗边观察”自主行为闭环

## Full-view comparison evidence

- 场景板、运行背景和三个真实 SwiftUI 状态已放入同一张比较图检查。
- 窗、薄纱、左侧植物与狗窝、中央地毯与玩具、右侧纸袋和书架保持场景真源的空间关系。
- 竖屏重构把窗景置于上部、活动区置于中部、交互区置于较安静的木地板区域，信息层级清楚。
- 栗子的暖色二维轮廓与新版背景一致，未出现旧版偏写实角色或场景叠层。

## Focused region comparison evidence

- 休息：栗子完整落入左侧狗窝内部，比例不再压过窝垫。
- 行走：过渡锚点位于狗窝与中央窗线之间，姿态与玩具没有遮挡冲突。
- 观察：栗子缩小并上移到窗边景深，和前景地毯形成明确层次。
- UI：标题、观察文案、片段卡片和三个互动按钮在暖色背景上均可读，未遮挡角色头部或关键物件。

## Findings

- 无剩余 P0/P1/P2 问题。
- [P3] 动态事件痕迹暂不显示
  - Location: 首页背景叠层。
  - Evidence: 旧 `TraceNoseMarkWindow` 在新画风中呈灰色污点，因此本轮移除了旧痕迹渲染。
  - Impact: 不影响自主行为和事件记录，但场景暂时缺少可视化生活痕迹。
  - Follow-up: 场景制作阶段按新画风重绘鼻印、纸袋移动和玩具移动三套透明资产后恢复。

## Required fidelity surfaces

- Fonts and typography: 使用现有 DogGo 字体层级；三个状态无截断、异常换行或对比度问题。
- Spacing and layout rhythm: 角色、观察文案和底部操作区保持稳定间距；安全区与 Dynamic Island 无冲突。
- Colors and visual tokens: 暖奶油、蜂蜜木色、橄榄绿与浅天蓝符合场景板；半透明卡片和主按钮沿用现有主题。
- Image quality and asset fidelity: 背景 2x/3x 资产清晰，无拉伸、接缝或错误透明边；栗子透明边缘干净。
- Copy and content: 保持观察性文案；未引入金币、爱心、饥渴、商店或购买逻辑。
- Icons and accessibility: 系统图标风格一致，主要按钮与调试入口保持足够触控尺寸；减少动态效果逻辑不变。

## Patches made

- 替换首页背景为场景一竖屏绘本版本；
- 移除旧画风阳光、窗帘和事件痕迹叠层；
- 新增狗窝、移动中、窗边三个空间锚点并修正比例与高度；
- 增加仅 DEBUG 使用的固定阶段参数，保证视觉回归可重复；
- 第二轮缩小并上移窗边姿态；
- 第三轮将休息姿态缩小并置入狗窝内部。

## Verification

- iPhone 17 Pro 构建成功；
- `DogAnimationPlayerTests`：6/6 通过；
- `HomeLifePresentationTests`：12/12 通过；
- 合计：18/18 通过。

## Follow-up Polish

- 按新场景画风重绘三套事件痕迹资产后恢复环境留痕。
- 场景二制作时复用本轮竖屏安全区、角色景深和 QA 截图流程。

final result: passed

---

# Dog Go M0.8 第一阶段最终验收

## 完成范围

- 首页改为 SwiftUI 界面叠加固定逻辑画布的 SpriteKit 场景。
- 栗子休息、察觉、起身、行走、观察均使用统一二维角色语言。
- 休息姿态新增同源睁眼、闭眼、单耳转动和轻抬头帧。
- 移除被否决的独立生成头身分件及狗窝前景叠层运行路径。
- 背景、事件痕迹、角色、预留前景、时间光照使用独立 SpriteKit 层级。
- 事件痕迹改为低对比代码绘制，不再显示旧灰色污块素材。
- 修复半屏 Sheet 转场时 SpriteKit `.resizeFill` 导致角色全屏放大的回归问题；场景改用固定 430 × 932 逻辑画布与 `.aspectFill`。

## 五阶段证据

- `design/qa/m0.8-stage-01-final/resting.png`
- `design/qa/m0.8-stage-01-final/noticing.png`
- `design/qa/m0.8-stage-01-final/rising.png`
- `design/qa/m0.8-stage-01-final/walking.png`
- `design/qa/m0.8-stage-01-final/observing-final.png`
- 最终首页：`design/qa/m0.8-stage-01-final/stage-01-accepted.png`
- 半屏比例回归：`design/qa/m0.8-stage-01-final/quiet-company-scale-regression.png`
- 狗窝前沿遮挡：`design/qa/m0.8-stage-01-final/resting-bed-occlusion-accepted.png`

## 验证

- iPhone 17 Pro / iOS 26.5 模拟器构建成功。
- 完整测试：48/48 通过，0 失败，0 跳过。
- 休息与狗窝融合、察觉姿态、起身锚点、行走锚点、观察锚点均通过截图 QA。
- 半屏页打开后，底层角色保持正常比例。
- 休息姿态的前爪位于窝内，狗窝前沿从身体下方通过；围巾、毯子和窝沿不再发生错误连片。

final result: stage 01 passed

---

# Dog Go M0.9 第二阶段角色动画系统 — 最终验收

## 完成范围

- 建立 `Idle / Rest / Walk / Observe / Reaction` SpriteKit 状态映射。
- `Reaction` 改为短暂覆盖状态，眨眼、转耳、回头、摇尾结束后自动恢复基础状态。
- 完成休息呼吸、同源眨眼、单耳转动、轻抬头察觉帧。
- Walk A/B 与 360ms 行走步频同步，位移和身体起伏同时执行。
- 修复同一锚点换姿态时未重新计算显示比例的问题。
- 起身、观察等非步行姿态使用短淡入和 280ms 尺度过渡。
- 行走到窗边使用 1.8s 平滑位移，到达后恢复 Observe 呼吸。
- 用户互动 `turnEar / lookBack / wagTail / settle` 全部映射到对应姿态与动画 cue。
- Sheet 转场保持固定 430 × 932 逻辑画布，不再放大角色。

## 验收证据

- 五阶段静态证据：`design/qa/m0.8-stage-01-final/`
- 角色与狗窝遮挡：`design/qa/m0.8-stage-01-final/resting-bed-occlusion-accepted.png`
- 状态机 QA 目录：`design/qa/m0.9-animation-state-machine/`
- 自动行为因果链由 `HomeAutonomyReducer` 测试覆盖。
- Reaction 异步恢复由 SpriteKit 场景测试覆盖。

## 验证

- iPhone 17 Pro / iOS 26.5 构建成功。
- 完整测试：51/51 通过，0 失败，0 跳过。
- 无永久停留在 Reaction、姿态缩放沿用、Sheet 角色放大等回归。

final result: stage 02 passed

---

# Dog Go M1.0 第三阶段场景一 — 最终验收

## 完成范围

- 阳光层由硬边加色多边形改为 38pt 高斯柔化、低透明度 Alpha 混合，并缩小投射范围。
- 窗帘风迹只在 `noticingCurtain` 阶段出现，位置绑定窗帘区域；减少动态效果开启时停止循环动画。
- 玩具与纸袋使用场景对象锚点作为唯一坐标真源，事件痕迹不再使用旧的游离坐标。
- 玩具移动显示同画风对象状态，纸袋压皱改为原纸袋上的折痕反馈，避免重复摆放第二个纸袋。
- 玩具状态触发栗子摇尾，纸袋状态触发单耳转动；对象状态与角色 Reaction 形成反馈闭环。
- 时间模型由四档补齐为清晨、上午、下午、傍晚、夜晚五档，并提供仅 DEBUG 使用的固定时段参数。
- 修复对象反馈与姿态切换同帧发生时，cue 贴图恢复原始像素尺寸导致栗子全屏放大的回归；每次反应贴图切换后强制保持拟合尺寸。

## 验收证据

- 对象状态反馈：`design/qa/m1.0-scene-01/02-object-state-feedback.png`
- 窗帘风迹：`design/qa/m1.0-scene-01/03-curtain-breeze.png`
- 清晨：`design/qa/m1.0-scene-01/time-phases/dawn.png`
- 上午：`design/qa/m1.0-scene-01/time-phases/morning.png`
- 下午：`design/qa/m1.0-scene-01/time-phases/afternoon.png`
- 傍晚：`design/qa/m1.0-scene-01/time-phases/evening.png`
- 夜晚：`design/qa/m1.0-scene-01/time-phases/night.png`

## 验证

- iPhone 17 Pro / iOS 26.5 模拟器构建成功。
- 完整测试：55/55 通过，0 失败，0 跳过。
- 阳光层边缘与亮度通过静态截图复核；不再出现原先横跨地毯的硬亮多边形。
- 五时段均可独立强制预览，并使用独立背景资产：清晨粉紫天空、上午清蓝天空、下午高亮暖阳、傍晚城市初亮灯、夜晚深蓝天空与城市窗灯。
- 窗外昼夜变化来自五张同构图场景资产，不再依赖整屏暗色滤镜或矩形窗格遮罩；角色同时接受轻微环境染色。
- 对象反馈截图中栗子比例稳定、狗窝遮挡稳定，纸袋折痕附着原对象，玩具状态位于玩具区域。

final result: stage 03 passed
