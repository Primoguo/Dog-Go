# Dog Go 视觉真源

本目录冻结 Dog Go 当前阶段的三层视觉真源。后续角色、场景、动画和界面生产应先与这里的基线对齐。

## 1. 角色唯一真源

文件：[`character/chestnut-character-master.png`](character/chestnut-character-master.png)

- 主角为柴犬“栗子”；
- 栗子的头身比例、脸型、毛色分区、耳朵、尾巴、绿色围巾和整体角色气质以该定装稿为准；
- 场景设计图中出现的其他犬种只用于行为和空间关系示意，不得作为角色生产依据；
- 新姿态、表情与动画分层必须保持栗子的跨姿态一致性。

## 2. 五个场景的空间真源

文件：

1. [`scenes/scene-01-living-room-window.png`](scenes/scene-01-living-room-window.png)
2. [`scenes/scene-02-entryway.png`](scenes/scene-02-entryway.png)
3. [`scenes/scene-03-bedroom.png`](scenes/scene-03-bedroom.png)
4. [`scenes/scene-04-kitchen.png`](scenes/scene-04-kitchen.png)
5. [`scenes/scene-05-balcony.png`](scenes/scene-05-balcony.png)

这些设计图是以下内容的真源：

- 空间构图与连接关系；
- 行动锚点和出入口；
- 可互动对象；
- 可持久化事件痕迹；
- 时间光照与场景主色调；
- 场景承担的生活及情绪功能。

图中的狗狗造型仅为行为示意，正式角色必须替换为栗子。

## 3. 产品原型布局参考

文件：[`prototype-reference/product-prototype-layout-reference.png`](prototype-reference/product-prototype-layout-reference.png)

该图仅用于参考：

- 页面布局与信息层级；
- 沉浸式首页构图；
- 暖色绘本视觉；
- 场景切换、日常回顾和事件详情的页面形态；
- 导航及低干扰互动入口的大致位置。

以下内容属于视觉占位，不进入当前产品逻辑：

- 爱心与金币；
- 商店；
- 饥饿、口渴等显性状态条；
- 装扮购买；
- 签到、资源损失或照料惩罚。

产品机制以 [`docs/PRD/Dog_Go_PRD_v3_Prototype_Redesign.md`](../../docs/PRD/Dog_Go_PRD_v3_Prototype_Redesign.md) 为准。

## 使用原则

当不同设计材料发生冲突时，采用以下优先级：

```text
v3 PRD 的产品原则
→ 栗子定装稿的角色定义
→ 五个场景图的空间定义
→ 产品原型图的布局参考
→ 旧版生产资产
```

旧版 `design/production/day12` 和 `day13` 资产继续保留，但在重新核对栗子定装和场景真源前，不应直接扩展为新版生产资产。
