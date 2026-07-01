# Dog Go M0.5 Day 20 验收报告

**日期：** 2026-06-29  
**状态：** 工程收尾已完成，真机签名验收待执行

## 本日交付

- 修复 SwiftData 测试夹具的生命周期：测试返回并持有 `ModelContainer`，避免 `ModelContext`、事件或状态仍在使用时容器提前释放。
- 同步加固离线模拟测试夹具，确保模型容器与测试场景同生命周期。
- 完成 Release iOS 通用设备构建，产物位于临时 DerivedData 的 `Release-iphoneos/DogGo.app`。
- 将 M0.5 阶段状态更新为工程收尾完成。

## 自动验证

- Debug App 与全部测试 Target 编译成功。
- Release、iOS 17+、arm64 通用设备构建成功：`** BUILD SUCCEEDED **`。
- 资源目录、Swift 6 编译、链接、App 元数据提取和 Bundle 校验均通过。

## 当前环境限制

- 当前 Xcode 未安装可用的 iOS Simulator Runtime，因此无法在模拟器执行 XCTest。
- 当前工程未配置 Development Team；Mac 上的 iPhone App 兼容运行目的地要求签名，测试宿主在安装阶段被系统拒绝。失败发生在测试执行前，不是用例断言失败。
- 当前没有可用真机目的地，故可安装签名包、真机视觉回归与演示录像不能在本次环境中产出。

## 真机验收清单

配置 Development Team 并连接 iPhone 后执行：

1. 运行全部 `DogGoTests`，确认无失败与 SwiftData 生命周期崩溃。
2. 从首次领养走到首页，确认 90 秒内完成且无横向溢出。
3. 推进时间并验证离线事件、环境痕迹、回应、记忆与后续引用闭环。
4. 连续停留 30 秒，检查呼吸、眨眼、转耳和姿态变化；开启“减少动态效果”后复测。
5. 检查 VoiceOver 的首页、生活片段、事件详情与“我们的日子”。
6. 录制一段完整内部演示，并由 Xcode Archive 导出签名安装包。

## 验收结论

工程代码与 Release 构建已达到 Day 20 的可交付状态；正式 M0.5 验收仍以签名真机上的全量 XCTest、视觉回归和演示录像为最终门槛。
