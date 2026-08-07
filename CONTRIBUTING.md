# Contributing

## 发布物验证

源码构建和测试在私有构建环境中完成。公开仓库提交前至少验证消费者项目能够通过 XCFramework 接入并构建；发布压缩包必须使用 `swift package compute-checksum` 生成校验值并写入 `Package.swift`。

公开仓库不提交 SDK 实现源码。实现变更应在私有构建目录完成，生成新的 XCFramework Release 后再更新 manifest、文档和版本 tag。

消费者项目验证命令示例：

```bash
xcodebuild \
  -scheme FixupModule \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/FixupModuleBinaryConsumerDerivedData \
  build
```

## 变更边界

- 不把宿主 App、Pods、Bundle ID、AppDelegate 或业务单例放入 SDK。
- 不新增远程代码执行、动态插件或未审核的系统能力。
- 公开 API 优先使用强类型参数和 `Result` 错误。
- 修改公开 API 时同步更新 `README.zh-CN.md` 和 `Docs/Integration.zh-CN.md`。
- 组件数据变化必须保留未知类型的安全降级。
