# Dog Go 场景生产化与跨场景自主行为实施建议

**文档用途：** 提交给 Codex，作为 Dog Go 从视觉概念稿进入可运行场景、分层资产、跨场景移动与自主行为开发阶段的实施说明。  
**当前优先范围：** 客厅窗边 + 玄关与门口  
**目标平台：** iOS 17+  
**现有技术栈：** SwiftUI、SwiftData、XCTest  
**核心目标：** 将已经确认的场景设计稿转化为可运行、可交互、可留痕、可跨场景移动的 App 场景，而不是继续停留在静态概念图阶段。

---

## 1. 当前阶段判断

目前已经完成的内容属于：

```text
视觉概念稿
+ 场景规则稿
+ 氛围与锚点设计
```

这些设计稿已经可以用于：

- 冻结视觉风格；
- 明确场景布局；
- 确定狗狗可行动区域；
- 确定互动对象；
- 确定事件痕迹；
- 明确场景之间的关系；
- 指导后续生产资产与代码实现。

但这些设计稿还不能直接作为最终运行资产使用。

下一阶段不应继续扩展更多新场景，而应优先完成：

```text
设计冻结
→ 资产分层
→ 场景数据化
→ 锚点与出口实现
→ 跨场景移动
→ 自主行为闭环
```

---

## 2. 第一步：冻结视觉设计

先确认以下五个场景的整体视觉方向已经通过：

1. 客厅窗边；
2. 玄关与门口；
3. 卧室床边；
4. 餐厨与水碗角落；
5. 阳台植物角。

冻结重点不是每件小物是否最终完美，而是确认以下内容：

- 五个场景色调统一；
- 狗狗始终是视觉中心；
- 场景适合狗狗移动；
- 每个场景都有明确锚点；
- 场景之间存在可理解的出口；
- 背景细节低于角色；
- 视觉方向符合“温暖轻绘本”；
- 场景可以支持事件痕迹和昼夜变化。

所有场景设计稿应定义为：

```text
视觉参考稿
不是直接运行资产
```

后续生产资产必须遵循这些设计稿，但不能简单把整张概念图直接放进 App。

---

## 3. 第二步：建立场景分层资产

Codex 不应直接使用整张场景设计稿作为唯一背景。

每个场景必须拆分为独立图层，才能支持：

- 昼夜变化；
- 光影移动；
- 窗帘和门的动画；
- 玩具位置变化；
- 事件痕迹；
- 狗狗从家具前后穿过；
- 前景遮挡；
- 场景状态持久化。

---

## 4. 客厅窗边资产清单

建议至少拆分为：

```text
scene_livingroom_background
scene_livingroom_city
scene_livingroom_window
scene_livingroom_curtain_back
scene_livingroom_curtain_front
scene_livingroom_floor
scene_livingroom_rug
scene_livingroom_dog_bed
scene_livingroom_furniture_left
scene_livingroom_furniture_right
scene_livingroom_sun_patch
scene_livingroom_front_overlay
```

事件痕迹单独拆分：

```text
trace_livingroom_toy_moved
trace_livingroom_paper_bag
trace_livingroom_nose_mark
trace_livingroom_feather
trace_livingroom_blanket_shifted
trace_livingroom_bed_indent
```

动态元素必须独立：

- 窗帘；
- 光斑；
- 小鸟；
- 玩具；
- 纸袋；
- 小毯子；
- 羽毛；
- 鼻印。

---

## 5. 玄关与门口资产清单

建议至少拆分为：

```text
scene_entry_background_wall
scene_entry_front_door
scene_entry_door_light
scene_entry_floor
scene_entry_door_mat
scene_entry_shoe_cabinet
scene_entry_shoe_rack
scene_entry_coat_area
scene_entry_umbrella_stand
scene_entry_livingroom_exit
scene_entry_front_overlay
```

事件与物品单独拆分：

```text
trace_entry_shoes_moved
trace_entry_keys_dropped
trace_entry_bag_left
trace_entry_toy_near_door
trace_entry_mat_shifted
trace_entry_wet_paw_prints
trace_entry_nose_mark
```

可互动对象：

- 入户门；
- 鞋子；
- 钥匙扣；
- 包袋；
- 牵引绳；
- 小地垫；
- 玩具；
- 雨伞桶。

---

## 6. 每个场景需要的生产交付物

每个场景至少应具备以下交付物。

### 6.1 无角色场景母版

要求：

- 不出现狗狗；
- 不出现 UI；
- 不把事件痕迹烘焙进去；
- 保留完整空间关系；
- 适配 iPhone 竖屏。

### 6.2 独立透明图层

每个动态对象、遮挡对象、事件对象单独输出透明 PNG。

### 6.3 锚点标注图

需要标出：

- 狗狗可以站在哪里；
- 可以走到哪里；
- 哪些位置可以停留；
- 哪些位置属于过渡点；
- 哪些区域会被前景家具遮挡；
- 哪些位置通向相邻场景。

### 6.4 图层顺序表

推荐基础顺序：

```text
背景
→ 远景
→ 建筑结构
→ 地板
→ 后景家具
→ 后景动态元素
→ 狗狗阴影
→ 狗狗
→ 事件物品
→ 前景家具
→ 前景动态元素
→ 光影
→ UI
```

### 6.5 资产命名规范

所有场景使用统一命名：

```text
scene_<scene>_<depth>_<element>_<variant>
trace_<scene>_<event>
object_<scene>_<object>
```

示例：

```text
scene_livingroom_mid_window_day
scene_livingroom_front_curtain
trace_livingroom_nose_mark
object_entry_keys
```

---

## 7. 第三步：建立可运行场景数据结构

每个场景不应只是一组图片，而应有可运行定义。

建议新增：

```swift
struct SceneDefinition: Identifiable, Equatable, Sendable {
    let id: SceneID
    let anchors: [SceneAnchor]
    let exits: [SceneExit]
    let interactiveObjects: [SceneObject]
    let traces: [SceneTraceDefinition]
    let timeProfiles: [TimeOfDay: SceneAppearance]
}
```

---

## 8. 场景锚点模型

建议定义：

```swift
struct SceneAnchor: Identifiable, Equatable, Sendable {
    let id: SceneAnchorID
    let normalizedPosition: CGPoint
    let facing: DogFacing
    let defaultPose: DogPose
    let allowedGoals: Set<DogGoal>
    let neighbors: [SceneAnchorID]
    let canStay: Bool
    let occlusionGroup: SceneOcclusionGroup?
}
```

每个锚点至少包含：

- 归一化坐标；
- 朝向；
- 默认姿态；
- 可执行行为；
- 相邻路径；
- 是否允许停留；
- 遮挡关系。

不应直接写死具体机型像素值。

---

## 9. 客厅锚点

建议配置：

```text
window
bed
rugCenter
toyArea
userSide
exitToHallway
```

示例：

```swift
SceneAnchor(
    id: .window,
    normalizedPosition: CGPoint(x: 0.52, y: 0.58),
    facing: .left,
    defaultPose: .sit,
    allowedGoals: [.inspectWindow, .rest],
    neighbors: [.rugCenter],
    canStay: true,
    occlusionGroup: nil
)
```

---

## 10. 玄关锚点

建议配置：

```text
frontDoor
doorMat
shoeCabinet
hallwayCenter
livingRoomExit
userFeet
```

示例：

```swift
SceneAnchor(
    id: .frontDoor,
    normalizedPosition: CGPoint(x: 0.50, y: 0.42),
    facing: .forward,
    defaultPose: .sit,
    allowedGoals: [.inspectDoor, .waitForUser],
    neighbors: [.doorMat, .hallwayCenter],
    canStay: true,
    occlusionGroup: nil
)
```

---

## 11. 场景出口模型

建议新增：

```swift
struct SceneExit: Identifiable, Equatable, Sendable {
    let id: SceneExitID
    let fromScene: SceneID
    let fromAnchor: SceneAnchorID
    let toScene: SceneID
    let entryAnchor: SceneAnchorID
    let transitionStyle: SceneTransitionStyle
}
```

例如：

```swift
SceneExit(
    id: .livingRoomToEntry,
    fromScene: .livingRoom,
    fromAnchor: .exitToHallway,
    toScene: .entry,
    entryAnchor: .livingRoomExit,
    transitionStyle: .walkThrough
)
```

---

## 12. 场景切换要求

场景切换不能像换壁纸一样瞬间发生。

正确流程：

```text
狗狗形成跨场景意图
→ 走向当前场景出口
→ 到达出口
→ 播放离场动作
→ 切换场景
→ 从新场景入口出现
→ 保持当前位置、朝向和意图连续
→ 继续执行剩余动作
```

必须遵守：

- 狗狗必须先走向出口；
- 当前意图不能在切换时丢失；
- 不允许切换场景后重新随机选择行为；
- 新场景进入位置必须与出口关系一致；
- 进入后继续原动作序列；
- 场景切换过程不能篡改长期生活记录；
- 狗狗不能瞬移。

---

## 13. 第四步：先开发两个场景

不要同时把五个场景全部接入。

第一阶段只完成：

1. 客厅窗边；
2. 玄关与门口。

原因：

- 两个场景已足够验证跨场景移动；
- 可以复用现有“第一次短暂分别”事件；
- 可以验证用户离开和归来；
- 可以验证意图跨场景保持；
- 可以控制开发复杂度；
- 可以减少场景资产和动画同时返工。

---

# 14. 第一条跨场景自主行为

本阶段只验证一条完整行为链：

```text
用户离开
→ 狗狗从客厅走向玄关
→ 在门口确认
→ 听见楼道声音
→ 短暂等待
→ 没有进一步变化
→ 自己转身
→ 返回客厅
→ 选择垫子或窗边休息
```

这条链应由狗狗自主系统驱动，不依赖用户点击完成。

---

## 15. 行为链拆解

### 阶段一：感知用户离开

```text
userLeft
→ social 或 vigilance 发生变化
→ 生成 inspectDoor 候选目标
```

### 阶段二：从客厅走向玄关

```text
当前位置：bed / window / rugCenter
→ 移动到 exitToHallway
→ 离开客厅
→ 从 livingRoomExit 进入玄关
```

### 阶段三：门口确认

```text
走向 frontDoor
→ 转耳
→ 抬头
→ 短暂等待
```

### 阶段四：自主返回

```text
等待结束
→ 没有新刺激
→ waitForUser 效用下降
→ rest 或 inspectWindow 效用上升
→ 创建 returnToLivingRoom 意图
```

### 阶段五：返回客厅休息

```text
走向 livingRoomExit
→ 切换回客厅
→ 进入 exitToHallway
→ 选择 bed 或 window
→ 趴下或坐下
→ 行为完成
```

---

## 16. Codex 第一阶段开发任务

请基于已经确认的五个场景设计稿，只完成“客厅窗边”和“玄关门口”两个场景的生产化设计与技术接入。

### 本阶段目标

实现以下跨场景自主行为：

```text
用户离开
→ 狗狗从客厅走向玄关
→ 在门口确认并短暂等待
→ 自主返回客厅
→ 选择垫子或窗边休息
```

### 必须交付

1. 两个场景的分层资产结构；
2. 两个场景的场景定义；
3. 锚点配置；
4. 出口配置；
5. 跨场景移动状态；
6. 当前意图跨场景保持；
7. 场景切换动画；
8. 事件痕迹独立开关；
9. 昼夜参数；
10. 单元测试。

---

## 17. 本阶段明确不做

暂不开发：

- 卧室；
- 餐厨；
- 阳台；
- 多场景同时加载；
- 自由寻路；
- 复杂骨骼动画；
- 生成式 AI；
- 大规模新增事件；
- 多犬；
- 商店与装扮；
- 饥饿或惩罚系统。

---

## 18. 代码结构建议

```text
Domain/
  Scene/
    SceneDefinition.swift
    SceneAnchor.swift
    SceneExit.swift
    SceneObject.swift
    SceneTraceDefinition.swift
    SceneAppearance.swift
    SceneNavigationGraph.swift

  Autonomy/
    DogIntention.swift
    DogActionStep.swift
    DogActionPlanner.swift
    DogAutonomyEngine.swift

Features/
  Home/
    HomeSceneStore.swift
    SceneRuntimeState.swift
    DogRuntimeState.swift

DesignSystem/
  Scene/
    SceneRenderer.swift
    SceneLayerRenderer.swift
    SceneTransitionRenderer.swift

  DogAnimation/
    DogMovementRenderer.swift
    DogAnimationPlayer.swift
```

职责：

- `SceneDefinition`：描述场景；
- `SceneNavigationGraph`：描述锚点与出口连接；
- `DogAutonomyEngine`：决定为什么移动；
- `DogActionPlanner`：生成行动序列；
- `DogMovementRenderer`：负责锚点之间移动；
- `SceneTransitionRenderer`：负责跨场景过渡；
- SwiftUI View 只负责显示，不负责自主决策。

---

## 19. 测试要求

### 19.1 单元测试

至少覆盖：

- 客厅锚点配置正确；
- 玄关锚点配置正确；
- 出口关系双向匹配；
- 狗狗只能从出口离开场景；
- 切换后从正确入口出现；
- 当前意图在场景切换后保持；
- 行动序列不会在切换时重置；
- 事件痕迹可以独立开关；
- 昼夜参数可以独立计算；
- 无效锚点不会导致崩溃；
- 场景切换失败时有安全降级。

### 19.2 手工测试

至少验证：

- 狗狗从客厅走向玄关；
- 狗狗不是瞬移；
- 狗狗离开画面和进入新场景方向一致；
- 玄关等待过程自然；
- 返回客厅后选择新的休息位置；
- 场景切换没有明显闪屏；
- 背景不会遮挡狗狗；
- 前景遮挡关系正确；
- 两个场景视觉风格一致；
- 小屏 iPhone 不出现路径穿过 UI。

---

## 20. 验收标准

同时满足以下条件，才视为本阶段完成：

- [ ] 客厅和玄关可以独立加载；
- [ ] 两个场景都使用分层资产；
- [ ] 狗狗可以在场景内部锚点之间移动；
- [ ] 狗狗可以在两个场景之间移动；
- [ ] 场景切换没有瞬移感；
- [ ] 当前意图跨场景保持；
- [ ] 行为链具有开始、过程和结束；
- [ ] 用户不操作时，狗狗能自主完成整条行为链；
- [ ] 事件痕迹可以独立开关；
- [ ] 昼夜参数可以改变场景外观；
- [ ] 前景家具不会错误遮挡狗狗；
- [ ] 两个场景的视觉风格一致；
- [ ] 减少动态效果开启后，逻辑不变；
- [ ] 核心锚点、出口与切换逻辑具有单元测试。

---

## 21. 重要原则

Codex 在本阶段必须遵守：

1. 不要直接把整张设计稿作为唯一背景；
2. 不要一次接入五个场景；
3. 不要用瞬间换背景代替跨场景移动；
4. 不要在场景切换时重置狗狗意图；
5. 不要把行为判断写进 SwiftUI View；
6. 不要让动画播放器决定下一步行为；
7. 不要为了赶进度跳过锚点和出口模型；
8. 不要把事件痕迹烘焙进基础场景；
9. 不要先做自由寻路；
10. 先完成一条真实跨场景生活闭环。

---

## 22. 最终结论

现在最重要的不是继续画第六个场景，而是把现有设计稿生产化。

正确顺序是：

```text
冻结视觉设计
→ 分层场景资产
→ 建立锚点与出口
→ 实现客厅和玄关
→ 完成跨场景行为链
→ 再扩展卧室、餐厨和阳台
```

当狗狗能够自己从客厅走向玄关、等待用户、再返回客厅休息时，Dog Go 才真正从“漂亮设计稿项目”升级为“有生活连续性的虚拟宠物 App”。
