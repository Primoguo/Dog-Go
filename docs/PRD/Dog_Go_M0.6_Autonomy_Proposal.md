# Dog Go：关于“狗狗自主行动感”的产品与技术改造建议

**文档用途：** 提交给 Codex，作为 Dog Go 下一阶段产品与开发建议  
**建议阶段名称：** M0.6「自主生活闭环」  
**目标平台：** iOS 17+  
**现有技术栈：** SwiftUI、SwiftData、XCTest  
**核心目标：** 让狗狗从“会播放动画的图片”升级为“具有可感知动机、意图和行动过程的虚拟生命角色”。

---

## 1. 当前问题判断

Dog Go 当前已经具备以下基础能力：

- 狗狗状态模型；
- 离线生活事件；
- 用户回应与记忆写入；
- 后续事件引用旧记忆；
- 昼夜变化与环境痕迹；
- 正式柴犬角色资产；
- 呼吸、眨眼、转耳、摇尾、回头等分层动作；
- 观察、休息、玩耍等姿态切换；
- 叫名字、轻轻摸摸、安静陪伴等在线互动；
- 离线事件画面回放。

这些能力已经证明 Dog Go 的数据闭环、事件闭环和视觉基础可以工作。

但当前首页中的狗狗仍然容易被用户理解为：

> 一张会呼吸、眨眼、摇尾，并偶尔切换姿态的图片。

主要原因不是动画数量不足，而是缺少以下四层能力：

1. **明确动机：** 狗狗为什么要做这件事；
2. **持续意图：** 狗狗准备去哪里、完成什么；
3. **空间行动：** 狗狗在房间不同地点之间移动；
4. **行为过程：** 一个行为具有开始、过程、结果，而不是直接切换姿态。

因此，下一阶段不建议继续优先增加更多眨眼、摇尾或局部动作，而应建立狗狗的轻量自主行为系统。

---

## 2. 当前实现为什么仍然像图片

### 2.1 当前自主行为本质上仍是随机动画调度

现有逻辑大致表现为：

```text
等待随机时间
→ 触发眨眼、转耳或摇尾
→ 再等待随机时间
→ 切换到另一个姿态
```

这种方式能够避免狗狗完全静止，但无法建立行为因果。

用户看见的是：

```text
时间到了
→ 狗狗播放动作
```

而不是：

```text
窗帘移动
→ 狗狗听见或看见变化
→ 产生好奇
→ 抬头确认
→ 起身走向窗边
→ 观察一段时间
```

**动作不等于行动。**

真正的自主行动应包含：

```text
刺激或内部需求
→ 形成意图
→ 选择目标
→ 执行动作序列
→ 得到结果
→ 更新状态
```

---

### 2.2 有姿态，但缺少空间位置变化

当前狗狗已经有坐、趴、站立、玩耍等姿态，但大概率仍停留在一个固定角色舞台或固定锚点附近。

如果角色始终在原地：

- 坐着变成趴着；
- 趴着变成站着；
- 站着摇尾；
- 原地回头；

用户依然会将其理解为图片状态切换。

虚拟角色最直接的生命感来自：

- 从垫子走到窗边；
- 从窗边走向水碗；
- 靠近纸袋闻一闻；
- 把玩具移动到另一个位置；
- 自己选择新的休息位置。

第一阶段不需要自由寻路，只需要几个固定空间锚点，就可以明显改善生命感。

---

### 2.3 当前行为缺少可观察的“当下意图”

`DogBehavior` 目前可以表达观察、休息、玩耍，但这些概念仍然过于宽泛。

例如，“观察”应进一步拆成：

```text
发现窗外变化
→ 想确认发生了什么
→ 将窗边设为目标位置
→ 起身
→ 走到窗边
→ 坐下观察
→ 好奇心得到满足
→ 决定继续停留或返回垫子
```

如果系统只是把 `lie_rest` 切换为 `sit_window`，用户只能看到换图，无法看到狗狗的决定过程。

---

### 2.4 微动作已经较完整，宏观行动仍然不足

目前已经具备：

- 呼吸；
- 眨眼；
- 转耳；
- 摇尾；
- 回头；
- 趴下；
- 起身。

这些动作适合用于“微生命感”。

但角色生命感应该分成三个层级：

```text
第一层：宏观行动
去哪里、做什么、持续多久

第二层：身体过程
起身、转向、移动、停下、趴下

第三层：微动作
呼吸、眨眼、转耳、尾巴、表情
```

当前第三层完成度较高，第一层明显不足，第二层主要依靠姿态切换或淡入淡出。

因此最终表现容易变成：

> 一张制作精良、会呼吸和眨眼的图片。

---

### 2.5 离线生活与在线生活仍然没有完全统一

离线事件引擎已经根据以下内容选择事件：

- 时间；
- 性格；
- 状态；
- 记忆；
- 连续事件；
- 重复惩罚；
- 稳定随机种子。

但首页在线待机仍然更接近随机动作播放器。

结果是：

- 离线时，狗狗有事实、有经历、有记忆；
- 在线时，狗狗主要随机播放动作。

下一阶段应让离线和在线共享同一套“狗狗为什么这样做”的基础逻辑。

---

## 3. 下一阶段目标

建议将下一阶段定义为：

# M0.6「自主生活闭环」

阶段目标不是让狗狗拥有真正的人工意识，也不是接入大模型，而是让用户能够从画面中感受到：

> 狗狗会因为自己的状态和环境变化，自主决定做什么，并把行动完成。

建议阶段闭环：

```text
狗狗感知环境与自身状态
→ 形成短期需求
→ 选择当前意图
→ 确定目标位置或目标物体
→ 执行一段连续行动
→ 完成或被合理打断
→ 更新状态、场景和记忆
```

---

## 4. 建议新增核心模块

建议在现有 `LifeEngine` 与 `DogAnimationPlayer` 之间增加：

# `DogAutonomyEngine`

推荐结构：

```text
DogState
  ↓
DogPerception
  ↓
DogNeeds
  ↓
DogUtilityEvaluator
  ↓
DogIntention
  ↓
DogActionSequence
  ↓
DogAnimationPlayer
  ↓
DogState / SceneState 更新
```

职责边界：

- `LifeEngine`：负责较长时间尺度的生活事件、离线事件和记忆；
- `DogAutonomyEngine`：负责在线状态下的短期自主行为；
- `DogAnimationPlayer`：只负责表现动作，不负责决定做什么；
- SwiftUI View：只负责渲染状态和发送用户动作，不包含行为决策逻辑。

---

## 5. 内部需求模型

第一版建议仅实现 5 个需求值：

```swift
struct DogNeeds: Equatable, Sendable {
    var rest: Double
    var curiosity: Double
    var play: Double
    var comfort: Double
    var social: Double
}
```

数值建议范围：

```text
0.0 ... 1.0
```

需求变化示例：

- 活力下降时，`rest` 上升；
- 长时间没有刺激时，`curiosity` 缓慢上升；
- 玩具长时间未使用时，`play` 上升；
- 当前姿势或位置持续较久时，`comfort` 上升；
- 用户回到 App 或呼唤名字时，`social` 临时上升；
- 夜间提高休息需求；
- 纸袋、玩具位移、窗帘变化等环境刺激提高好奇需求。

注意：

- 不要让需求值快速跳变；
- 不要让所有需求同时高频更新；
- 不要把需求直接展示给用户；
- 不要引入饥饿、惩罚、死亡、连续签到等压力机制。

---

## 6. 环境感知模型

建议新增：

```swift
enum SceneStimulus: Equatable, Sendable {
    case curtainMoved
    case birdOutside
    case toyAvailable
    case toyMoved
    case paperBagAppeared
    case sunlightChanged
    case hallwaySound
    case userReturned
    case userCalledName
    case userTouched
}
```

狗狗每次决策时，不应只读取随机数，还应读取：

- 当前时间段；
- 房间内可见物品；
- 最近环境变化；
- 当前所在位置；
- 用户是否在线；
- 用户最近一次互动；
- 当前需求；
- 当前情绪和精力；
- 当前意图是否完成。

---

## 7. 场景锚点与可行动对象

第一版不做自由寻路。

建议将客厅定义为 5 个固定锚点：

```swift
enum SceneAnchorID: String, Codable, CaseIterable {
    case bed
    case roomCenter
    case window
    case toyArea
    case userSide
}
```

建议结构：

```swift
struct SceneAnchor: Identifiable, Equatable, Sendable {
    let id: SceneAnchorID
    let normalizedPosition: CGPoint
    let availableAffordances: Set<DogAffordance>
}
```

可供性：

```swift
enum DogAffordance: Hashable, Sendable {
    case rest
    case observe
    case play
    case investigate
    case approachUser
}
```

示例：

```text
bed
- rest
- comfort

window
- observe
- investigate

toyArea
- play
- investigate

userSide
- approachUser
- rest

roomCenter
- transition
- investigate
```

锚点位置使用归一化坐标，不要直接写死具体机型像素值。

---

## 8. 意图系统

建议新增：

```swift
struct DogIntention: Identifiable, Equatable, Sendable {
    let id: UUID
    let goal: DogGoal
    let targetAnchor: SceneAnchorID?
    let startedAt: Date
    let minimumDuration: TimeInterval
    let maximumDuration: TimeInterval
    let interruptibility: Double
    let reason: DogIntentionReason
}
```

目标类型：

```swift
enum DogGoal: Equatable, Sendable {
    case rest
    case inspectWindow
    case investigateObject(SceneObjectID)
    case playWithToy
    case seekUser
    case relocateForComfort
    case remainQuietly
}
```

原因类型：

```swift
enum DogIntentionReason: Equatable, Sendable {
    case internalNeed
    case environmentStimulus
    case userInteraction
    case eventContinuation
}
```

核心原则：

1. 狗狗一次只保留一个主意图；
2. 意图建立后，不能每几秒重新随机抽取；
3. 意图至少持续一个最短时间；
4. 高优先级事件可以打断低优先级意图；
5. 用户互动可以影响狗狗，但不必强制控制狗狗；
6. 行为结束后才重新评估下一意图；
7. 同一个目标连续重复时应有冷却或重复惩罚。

---

## 9. 行为效用评分

第一版建议采用 Utility AI，而不是复杂行为树或生成式 Agent。

每个候选行为计算一个分数：

```swift
score =
    needScore
  + stimulusScore
  + traitScore
  + timeScore
  + memoryScore
  + locationScore
  - repetitionPenalty
  - transitionCost
```

示例：

```text
inspectWindow
= curiosity × 0.45
+ curtainMoved × 0.30
+ curiousTrait × 0.15
+ daytime × 0.10
- recentlyInspectedWindow × 0.25
```

```text
rest
= restNeed × 0.50
+ lowEnergy × 0.25
+ nighttime × 0.15
+ bedNearby × 0.10
```

```text
seekUser
= socialNeed × 0.40
+ userReturned × 0.35
+ positiveMemory × 0.15
- currentlyBusy × 0.20
```

不要让最高分行为直接瞬间执行。

建议加入：

- 最低触发阈值；
- 当前意图保持奖励；
- 行为冷却；
- 同类行为重复惩罚；
- 轻量稳定随机扰动；
- 最短承诺时间。

这样可以避免角色频繁改变主意。

---

## 10. 行动序列

建议将每个意图展开为动作序列，而不是直接切换姿态。

示例：

```swift
enum DogActionStep: Equatable, Sendable {
    case pause(TimeInterval)
    case turnToward(SceneAnchorID)
    case changePose(DogPose)
    case moveTo(SceneAnchorID, duration: TimeInterval)
    case playCue(DogAnimationCue)
    case wait(TimeInterval)
    case interactWith(SceneObjectID)
    case complete
}
```

例如 `inspectWindow`：

```text
pause
→ 转耳
→ 抬头
→ 起身
→ 转向窗边
→ 移动到窗边
→ 切换 sit_window
→ 观察
→ 偶尔眨眼与转耳
→ 完成
```

例如 `playWithToy`：

```text
看向玩具区
→ 起身
→ 移动到玩具区
→ play_bow
→ 鼻子触碰玩具
→ 玩具产生轻微位移
→ 玩耍数秒
→ 停止
→ 更新玩具位置或场景痕迹
```

例如 `rest`：

```text
判断当前地点是否舒适
→ 必要时移动到垫子
→ 旋转调整方向
→ lie_rest
→ 呼吸
→ 低频眨眼
→ 逐渐安静
```

---

## 11. 移动表现

第一版不需要复杂骨骼动画，也不需要真实导航。

建议采用：

```text
固定锚点
+ 预设路径
+ 简化步行循环
+ 接触阴影跟随
+ 到达时姿态过渡
```

最低实现方式：

1. 从当前姿态切换到 `stand_turn`；
2. 轻微转向目标；
3. 播放 2–4 帧简化步行动画，或使用轻微上下位移；
4. 沿预设二次贝塞尔曲线移动；
5. 接近目标时减速；
6. 到达后切换目标姿态；
7. 阴影始终保持在地板接触点；
8. 移动时控制角色缩放，模拟空间远近；
9. 避免角色穿过家具和 UI。

即使第一版步行表现不复杂，只要狗狗明确从一个地点移动到另一个地点，生命感也会比增加更多局部动作更明显。

---

## 12. 第一条必须完成的实时自主行为链

建议首先制作：

# “窗帘动了，狗狗自己去看看”

完整链路：

```text
狗狗趴在垫子上
→ 前景或后景窗帘发生低幅变化
→ 一只耳朵先转向窗户
→ 延迟 0.3–1 秒
→ 狗狗抬头
→ 保持短暂确认
→ curiosity 达到阈值
→ 创建 inspectWindow 意图
→ 起身
→ 转向窗边
→ 移动到窗边
→ 坐下
→ 观察城市或小鸟
→ 偶尔眨眼、转耳
→ curiosity 下降
→ 自主决定继续停留或回到垫子
```

关键要求：

- 不依赖用户点击；
- 不依赖文字解释；
- 用户只看画面也能理解因果；
- 行为可以被“用户回来”这种高优先级刺激合理打断；
- 行为完成后更新当前锚点和需求值；
- 同一行为短时间内不能重复触发。

---

## 13. 用户互动与自主性的关系

当前三种在线互动可以保留：

- 叫名字；
- 轻轻摸摸；
- 安静陪伴。

但互动不应始终强制覆盖当前行为。

建议规则：

### 叫名字

狗狗可能：

- 立即回头；
- 只转耳；
- 延迟后靠近用户；
- 正在专注时暂时忽略；
- 完成当前动作后再回应。

### 轻轻摸摸

狗狗可能：

- 接受并轻摇尾；
- 调整姿势；
- 靠近一点；
- 轻微避开后继续休息；
- 正在玩耍时只短暂看向用户。

### 安静陪伴

狗狗可以：

- 留在原位；
- 自己走到用户附近；
- 趴下；
- 保持低频微动作；
- 一段时间后自己换一个舒服位置。

设计目标：

> 用户能够影响狗狗，但不能像遥控器一样完全控制狗狗。

---

## 14. 状态持久化建议

需要区分：

### 长期持久化

保存在 SwiftData：

- 情绪；
- 活力；
-性格权重；
- 长期需求基线；
- 最近完成的生活事件；
- 重要记忆；
- 当前场景痕迹；
- 最近所在锚点；
- 最近完成的自主目标类型。

### 短期运行状态

只保存在内存：

- 当前动作步骤；
- 当前动画进度；
- 当前路径进度；
- 本次待机随机扰动；
- 当前动作 token；
- 几秒级刺激；
- 临时 UI 反馈文案。

避免将每一次眨眼和每一帧动作写入 SwiftData。

---

## 15. 建议工程结构

```text
DogGo/
  Domain/
    Autonomy/
      DogAutonomyEngine.swift
      DogNeeds.swift
      DogPerception.swift
      DogIntention.swift
      DogGoal.swift
      DogUtilityEvaluator.swift
      DogActionSequence.swift
      DogActionPlanner.swift
      DogAutonomyPolicy.swift

    Scene/
      SceneAnchor.swift
      SceneObject.swift
      SceneStimulus.swift
      SceneNavigationGraph.swift

  Features/
    Home/
      HomeStore.swift
      HomeSceneState.swift
      DogRuntimeState.swift

  DesignSystem/
    DogAnimation/
      DogAnimationPlayer.swift
      DogMovementRenderer.swift
      DogPoseRenderer.swift
```

职责约束：

- SwiftUI View 不进行候选行为评分；
- 动画播放器不决定下一行为；
- 效用评分不直接修改 SwiftData；
- 场景锚点和路径配置化；
- 时间与随机源可注入；
- 自主引擎可以在单元测试中无 UI 运行。

---

## 16. 建议新增状态模型

```swift
struct DogRuntimeState: Equatable, Sendable {
    var currentAnchor: SceneAnchorID
    var currentPose: DogPose
    var currentIntention: DogIntention?
    var currentActionIndex: Int
    var activeStimuli: [SceneStimulus]
    var needs: DogNeeds
    var isMoving: Bool
}
```

建议不要将 `DogBehavior` 删除，而是调整其层级：

```text
DogBehavior
= 长期或较粗粒度生活状态

DogIntention
= 当前几秒到几十秒的行动目标

DogActionStep
= 当前正在执行的具体动作
```

示例：

```text
DogBehavior: observing
DogIntention: inspectWindow
DogActionStep: moveTo(window)
```

---

## 17. 调度频率

不建议每一帧运行决策。

建议：

- 动画渲染：系统正常刷新；
- 动作步骤推进：由动画完成回调或轻量定时器驱动；
- 感知更新：环境变化时立即触发；
- 需求更新：每 5–15 秒或按时间差计算；
- 意图评估：当前意图结束、可打断刺激出现、App 回到前台时执行；
- 不要每秒重新选择目标。

推荐逻辑：

```text
存在不可打断意图
→ 继续执行

存在高优先级刺激
→ 评估是否打断

当前意图完成
→ 更新需求
→ 选择下一意图

无意图
→ 选择下一意图
```

---

## 18. 测试要求

### 18.1 单元测试

至少覆盖：

- 同一状态与同一种子产生稳定候选结果；
- 夜间低精力时，休息行为分数高于玩耍；
- 出现纸袋时，调查行为权重上升；
- 当前意图未达到最短时间时不会被低优先级行为替换；
- 用户回来可以打断普通休息，但不一定打断关键事件；
- 相同目标短时间内受到重复惩罚；
- 到达目标锚点后正确更新当前位置；
- 行动序列按顺序执行；
- 行动完成后正确降低对应需求；
- 减少动态效果开启后，逻辑不变，只替换表现形式。

### 18.2 视觉与手工测试

至少验证：

- 用户不操作时，狗狗能自主完成一条完整行为链；
- 用户能够说出狗狗为什么移动；
- 移动过程中脚部不漂浮；
- 阴影与角色保持接地；
- 狗狗不穿透家具；
- 行动不会在中间无原因跳变；
- 两分钟内不会出现明显随机动作拼接；
- 用户呼唤时，狗狗的回应与当前意图一致；
- 行为完成后场景或状态产生合理变化；
- 小屏 iPhone 上路径与 UI 不冲突。

---

## 19. M0.6 建议验收标准

同时满足以下条件，才视为 M0.6 完成：

- [ ] 狗狗至少可以在 4 个场景锚点之间移动；
- [ ] 至少实现休息、观察、玩耍、靠近用户 4 类自主目标；
- [ ] 每个目标都包含开始、过程和结束；
- [ ] 行为由内部需求或环境刺激触发，不仅依赖随机定时器；
- [ ] 当前意图在行为完成前保持稳定；
- [ ] 至少完成“窗帘动了，狗狗去看看”的完整实时行为链；
- [ ] 用户不进行操作时，狗狗仍能自主生活；
- [ ] 用户互动可以影响狗狗，但不总是强制覆盖当前意图；
- [ ] 同一行为不会在短时间内机械重复；
- [ ] 用户只看画面，可以解释狗狗刚才为什么行动；
- [ ] 连续观看两分钟，没有明显随机动画拼接感；
- [ ] 减少动态效果开启后，行为逻辑保持一致；
- [ ] 自主决策、意图保持和行动序列具备单元测试；
- [ ] iPhone 常用尺寸运行流畅，无明显异常耗电。

---

## 20. 暂不建议进入的范围

M0.6 暂时不要加入：

- 生成式 AI 实时控制角色；
- 大模型 Agent；
- 自由文本对话；
- 无限制自由寻路；
- 复杂骨骼物理；
- 3D 场景；
- 多房间；
- 多只狗；
- 情绪惩罚；
- 饥饿死亡；
- 签到与任务；
- 商店和装扮；
- 大量新增事件内容。

原因：

当前最重要的是验证“轻量自主行为”是否能显著提升角色生命感，而不是扩大产品范围。

---

## 21. Codex 执行顺序建议

建议严格按以下顺序执行：

### Step 1：冻结 M0.6 数据结构

实现：

- `DogNeeds`
- `SceneAnchor`
- `SceneStimulus`
- `DogGoal`
- `DogIntention`
- `DogActionStep`
- `DogRuntimeState`

先写测试，不接 UI。

### Step 2：建立场景锚点

为当前客厅配置：

- bed
- roomCenter
- window
- toyArea
- userSide

完成坐标、路径和可供性配置。

### Step 3：实现效用评分

第一版只支持：

- rest
- inspectWindow
- playWithToy
- seekUser

提供确定性测试。

### Step 4：实现意图保持机制

加入：

- 最短持续时间；
- 打断优先级；
- 重复惩罚；
- 行为冷却；
- 当前意图保持奖励。

### Step 5：实现行动序列执行器

动作步骤必须按顺序执行，并通过回调推进。

### Step 6：实现锚点移动

先使用简化步行与路径平移，不追求复杂动画。

### Step 7：完成第一条完整行为链

实现：

> 窗帘变化 → 狗狗注意 → 起身 → 走向窗边 → 坐下观察。

### Step 8：接入现有互动

让叫名字、轻摸和安静陪伴进入刺激与意图系统。

### Step 9：接入现有 LifeEngine

让离线事件结果能够影响：

- 场景刺激；
- 当前锚点；
- 需求值；
- 下一次在线自主行为。

### Step 10：真机验证

重点验证：

- 行为因果是否能被用户理解；
- 移动是否自然；
- 是否仍有图片切换感；
- 是否出现行为频繁改变；
- 是否出现耗电与定时器问题。

---

## 22. 最终原则

Codex 在本阶段必须遵守以下原则：

1. **不要通过增加随机动画数量来伪装自主性。**
2. **不要让 SwiftUI View 承担行为决策。**
3. **不要每隔几秒重新随机选择行为。**
4. **狗狗必须先有意图，再有行动。**
5. **每个行动必须有开始、过程和结果。**
6. **空间位置变化优先于增加更多局部动作。**
7. **动画播放器只负责表现，不负责决策。**
8. **用户可以影响狗狗，但不能完全遥控狗狗。**
9. **自主行为必须可测试、可复现、可调试。**
10. **优先完成一条完整行为链，不要同时铺开大量行为。**

---

## 23. 一句话结论

Dog Go 当前缺少的不是更多动画，而是一层连接状态、环境、意图、空间和动作的轻量“狗狗大脑”。

下一阶段应暂停继续扩充局部动作，优先实现：

```text
需求
+ 感知
+ 意图
+ 场景锚点
+ 行动序列
```

当用户能够只通过画面看懂：

> “窗帘动了，所以它自己起身去窗边看看。”

Dog Go 的狗狗才真正从一张会动的图片，升级为一个拥有自主生活感的主角。
