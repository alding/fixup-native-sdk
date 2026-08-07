# FixupModule 原生装修组件 SDK

FixupModule 是一个面向 iOS 应用的二进制 Swift Package，用于接入原生装修首页及其组件。SDK 负责模板数据解析、原生组件渲染、图片和资源加载、组件交互以及装修页面状态管理；宿主应用负责账号、请求头、页面跳转、微信/小程序、广告和扫码等应用能力。公开仓库不包含 SDK 实现源码，实际实现通过 GitHub Release 的 XCFramework 分发。

配套文档：

- [完整中文接入文档](Docs/Integration.zh-CN.md)
- [App Store 审核准备](Docs/AppStoreReview.zh-CN.md)
- [隐私与权限说明](Docs/Privacy.zh-CN.md)
- [组件配置边界](Docs/ComponentSchema.zh-CN.md)

## 1. 环境要求

- iOS 14.0 及以上
- Swift 5.9 及以上
- Xcode 15 及以上
- Swift Package Manager

## 2. 安装 SDK

在 Xcode 中选择 `File > Add Package Dependencies...`，填写：

```text
https://github.com/alding/fixup-native-sdk.git
```

生产环境建议选择版本：

```text
1.2.0
```

不要依赖 `main` 分支。分支会随开发变化，版本 tag 才是可复现的生产依赖。

在使用文件中导入：

```swift
import FixupModule
```

## 3. 初始化配置

应用启动后、第一次创建装修页面前配置 SDK：

```swift
import FixupModule

let configuration = FixupModuleConfiguration(
    baseURL: "https://your-live-liveapi.example.com",
    liveGWURL: "https://your-live-gw.example.com",
    rewardURL: "https://your-reward.example.com",
    shopURL: "https://your-shop.example.com",
    livePayURL: "https://your-live-play.example.com",
    chainBaseURL: "https://your-chain.example.com"
)

FixupModule.shared.configure(configuration)

guard FixupModule.shared.isConfigured else {
    let messages = FixupModule.shared.configurationErrors
        .compactMap(\.errorDescription)
        .joined(separator: "\n")
    assertionFailure(messages)
    return
}
```

`livePayURL` 和 `chainBaseURL` 可以省略，省略时自动使用 `baseURL`。所有地址必须是带 host 的 `http` 或 `https` URL。

旧版字符串配置接口仍然保留：

```swift
FixupModule.shared.configure(
    baseURL: baseURL,
    liveGWURL: liveGWURL,
    rewardURL: rewardURL,
    shopURL: shopURL,
    livePayURL: livePayURL
)
```

## 4. 实现宿主能力桥接

SDK 不直接依赖宿主应用的登录、WebView、微信、广告和业务控制器。宿主需要实现 `FixupModuleDependency`：

```swift
final class AppFixupDependency: FixupModuleDependency {
    var isDecorationEnabled: Bool {
        true
    }

    var shouldShowHomeWebActionButtons: Bool {
        true
    }

    func refreshHomePage(completion: (() -> Void)?) {
        // SDK 内组件完成关注、绑定等操作后，
        // 宿主在这里刷新自己的页面或重新拉取业务数据。
        completion?()
    }

    func currentLiveID() -> Int {
        // 返回当前直播间 ID。
        0
    }

    func currentUserID() -> Int {
        // 未登录时返回 0。
        0
    }

    func currentMallURL() -> String? {
        // 返回当前商城 URL。SDK 会从其中读取 generalizeShopId。
        nil
    }

    func currentWebViewCookies() -> [[String: String]] {
        // 返回需要注入商城 WebView 的 cookie。
        []
    }

    func requestHeaders() -> [String: String] {
        // 返回装修接口需要的业务请求头。
        [
            "packagename": Bundle.main.bundleIdentifier ?? "",
            "njyq-userid": "当前用户加密 ID"
        ]
    }

    func openHomeWebView(from viewController: UIViewController, urlString: String) {
        // 使用宿主自己的 WebView 控制器打开 URL。
    }

    func openTopicLivePage(from viewController: UIViewController, urlString: String) {
        // 打开话题或直播详情页。
    }

    func launchMiniProgram(appId: String?, userName: String, path: String) {
        // 使用宿主的微信 SDK 打开小程序。
    }

    func presentInterstitialAd(
        from viewController: UIViewController,
        appId: String,
        placementId: String,
        onClick: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        // 使用宿主广告 SDK 展示广告。
        onFinish()
    }

    func showToast(_ message: String) {
        // 使用宿主 Toast 组件提示。
    }

    func handleScanHomeQRCode(
        from viewController: UIViewController,
        body: Any,
        completion: @escaping (String) -> Void
    ) {
        // 使用宿主扫码能力。扫码成功后回调。
        completion("")
    }

    func makeSettingsViewController() -> UIViewController {
        // 返回宿主设置页面。
        UIViewController()
    }

    func makeRoomListViewController() -> UIViewController {
        // 返回宿主直播间列表页面。
        UIViewController()
    }
}
```

配置桥接：

```swift
FixupModuleHost.setHost(AppFixupDependency())
```

建议将桥接对象作为宿主单例持有，确保登录状态、当前直播间和请求头始终来自同一份业务状态。

## 5. 创建和展示原生装修首页

完成 SDK 配置和桥接后，直接使用公开协调器创建页面：

```swift
let homeViewController = FixupModuleHost.makeHomeViewController(
    options: FixupHomeOptions(
        title: "首页",
        automaticallyRefresh: true
    )
)

navigationController?.pushViewController(homeViewController, animated: true)
```

页面会立即返回并显示加载状态，SDK 在后台请求模板和组件数据，成功后自动更新已经展示的页面。

如果宿主希望自己控制首次请求，可以关闭自动刷新：

```swift
let homeViewController = FixupModuleHost.makeHomeViewController(
    title: "首页",
    automaticallyRefresh: false
)

FixupModuleHost.refresh(force: true) { result in
    switch result {
    case .success:
        print("装修首页刷新成功")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

## 6. 刷新和会话切换

切换直播间时强制刷新：

```swift
FixupModuleHost.refresh(force: true) { result in
    if case .failure(let error) = result {
        print("刷新失败：\(error.localizedDescription)")
    }
}
```

用户退出登录、切换账号或销毁装修业务时：

```swift
FixupModuleHost.reset()
```

`reset()` 会移除宿主能力桥接、清空 SDK Store、清除页面缓存状态并停止继续更新旧页面。重新进入业务前，需要再次调用 `FixupModuleHost.setHost(...)`。

## 7. 公开能力边界

SDK 负责：

- 原生装修组件和模板渲染
- 后台组件模型解析
- 页面背景、主题色和灰度状态
- 图片、字体和 SDK 随包资源
- 组件内标准交互和请求
- 装修页面刷新和会话状态清理

宿主应用负责：

- 登录态、用户 ID 和鉴权请求头
- 当前直播间和商城 URL
- WebView、直播详情、设置、直播间列表
- 微信小程序、扫码和广告
- Toast、业务埋点和宿主自己的隐私合规

SDK 不下载或执行原生代码、脚本、动态插件或任意远程模块。后台只能下发 SDK 已实现组件的数据、样式、图片和跳转参数。

## 8. 请求头约定

请求头由 `requestHeaders()` 统一提供。常见字段包括：

| 字段 | 说明 |
| --- | --- |
| `packagename` | 宿主应用 Bundle ID |
| `wxappId` / `wxappid` | 业务微信 App ID |
| `njyq-userid` | 当前用户加密 ID |
| `Authorization` | 宿主鉴权 token，建议使用 `Bearer xxx` |
| `appname` | 业务应用标识 |

不要在 SDK 中写死账号、token、密钥或宿主 Bundle ID。请求头中的敏感值应由宿主运行时提供。

## 9. App Store 审核准备

提交审核前建议准备：

1. 在审核备注中提供可访问装修首页的导航路径。
2. 如果必须登录，提供审核账号或审核专用免登录环境。
3. 说明装修页面使用的是包内原生组件，远程接口只返回业务数据和配置。
4. 在宿主 App 的隐私清单中补充宿主自己收集的数据类型。
5. 检查宿主提供的广告、微信、扫码和 WebView 能力是否有对应的权限说明和隐私声明。
6. 验证所有远程图片、网页和接口在无网络、超时、空数据和登录失效时都有可结束的错误状态。
7. 不要通过后台配置下载可执行代码，不要使用动态脚本改变 App 功能。

SDK 包含 `PrivacyInfo.xcprivacy`，声明了 SDK 使用的 `UserDefaults` 访问原因，未声明 SDK 自己收集的用户数据和广告跟踪。宿主仍需根据自身实现完成最终隐私申报。

## 10. 日志和问题排查

开发环境可以打开 SDK 日志：

```swift
FixupLogger.shared.logLevel = .debug
FixupLogger.shared.showTimestamp = true
FixupLogger.shared.showCategory = true
```

生产环境建议关闭详细网络日志：

```swift
FixupLogger.shared.logLevel = .warning
```

重点检查：

- `FixupModule.shared.isConfigured` 是否为 `true`
- `FixupModuleHost.dependency` 是否已经配置
- `currentLiveID()` 是否返回正确直播间 ID
- `requestHeaders()` 是否包含业务鉴权信息
- `currentMallURL()` 中的 `generalizeShopId` 是否正确
- 宿主页面是否在主线程展示和刷新 UIKit 控制器

## 11. 版本策略

SDK 使用语义化版本：

- `1.0.x`：向后兼容的修复
- `1.x.0`：向后兼容的新功能
- `2.0.0`：破坏性 API 变化

生产项目应固定到明确 tag，例如：

```text
https://github.com/alding/fixup-native-sdk.git @ 1.1.1
```

完整 API 和审核材料请以 `Docs/` 目录为准。
