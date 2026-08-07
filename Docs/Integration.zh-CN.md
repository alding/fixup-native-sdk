# FixupModule 中文接入文档

本文档是 `FixupModule` 公开 Swift Package 的完整接入示例。SDK 适合被多个独立 iOS App 接入，每个宿主 App 都必须提供自己的业务身份、登录态、页面路由和隐私声明。

## 一、依赖 SDK

在 Xcode 中选择 `File > Add Package Dependencies...`，填写：

```text
https://github.com/alding/fixup-native-sdk.git
```

生产工程选择明确版本，例如：

```text
1.1.1
```

不要把生产工程绑定到 `main` 分支。版本 tag 可以保证宿主工程在后续构建时仍然解析到同一份 SDK 二进制发布物。

## 二、配置接口地址

建议在 App 启动完成、首次创建装修页面之前配置：

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
    let reason = FixupModule.shared.configurationErrors
        .compactMap(\.errorDescription)
        .joined(separator: "\n")
    assertionFailure(reason)
    return
}
```

也可以直接传入 `URL`：

```swift
let configuration = FixupModuleConfiguration(
    baseURL: URL(string: "https://your-live-liveapi.example.com")!,
    liveGWURL: URL(string: "https://your-live-gw.example.com")!,
    rewardURL: URL(string: "https://your-reward.example.com")!,
    shopURL: URL(string: "https://your-shop.example.com")!
)
FixupModule.shared.configure(configuration)
```

`livePayURL` 和 `chainBaseURL` 省略时使用 `baseURL`。所有地址都必须是带 host 的 `http` 或 `https` 地址。

## 三、实现宿主能力桥

SDK 不持有宿主 App 的登录、微信、广告、WebView、扫码和业务页面控制器。宿主通过 `FixupModuleDependency` 注入这些能力：

```swift
import UIKit
import FixupModule

final class AppFixupDependency: FixupModuleDependency {
    var isDecorationEnabled: Bool {
        true
    }

    var shouldShowHomeWebActionButtons: Bool {
        true
    }

    func refreshHomePage(completion: (() -> Void)?) {
        // 关注、绑定或其他组件操作成功后，刷新宿主业务页面。
        completion?()
    }

    func currentLiveID() -> Int {
        // 返回当前直播间 ID；未准备好时返回 0。
        0
    }

    func currentUserID() -> Int {
        // 未登录返回 0。
        0
    }

    func currentMallURL() -> String? {
        // 返回当前商城地址。SDK 会读取其中的 generalizeShopId。
        nil
    }

    func currentWebViewCookies() -> [[String: String]] {
        // 返回宿主需要注入商城 WebView 的 cookie。
        []
    }

    func requestHeaders() -> [String: String] {
        [
            "packagename": Bundle.main.bundleIdentifier ?? "",
            "njyq-userid": "宿主生成的用户标识",
            "Authorization": "Bearer 宿主运行时 token"
        ]
    }

    func openHomeWebView(from viewController: UIViewController, urlString: String) {
        // 使用宿主自己的 WebView 控制器打开地址。
    }

    func openTopicLivePage(from viewController: UIViewController, urlString: String) {
        // 使用宿主自己的导航栈打开话题或直播详情。
    }

    func launchMiniProgram(appId: String?, userName: String, path: String) {
        // 使用宿主微信 SDK 打开小程序。
    }

    func presentInterstitialAd(
        from viewController: UIViewController,
        appId: String,
        placementId: String,
        onClick: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        // 使用宿主广告 SDK。加载失败也必须回调 onFinish。
        onFinish()
    }

    func showToast(_ message: String) {
        // 使用宿主 Toast。
    }

    func handleScanHomeQRCode(
        from viewController: UIViewController,
        body: Any,
        completion: @escaping (String) -> Void
    ) {
        // 使用宿主扫码能力；成功或失败都应结束宿主自己的扫码流程。
        completion("")
    }

    func makeSettingsViewController() -> UIViewController {
        UIViewController()
    }

    func makeRoomListViewController() -> UIViewController {
        UIViewController()
    }
}
```

在配置地址后设置宿主桥：

```swift
FixupModuleHost.setHost(AppFixupDependency())
```

宿主应持有依赖对象，避免它在页面仍然展示时被释放。切换账号或销毁装修业务时调用：

```swift
FixupModuleHost.reset()
```

`reset()` 会清除 SDK 的页面状态、停止旧会话继续更新页面，并移除宿主能力桥。

## 四、创建原生装修首页

推荐使用带 options 的公开入口：

```swift
let options = FixupHomeOptions(
    title: "首页",
    automaticallyRefresh: true
)

let viewController = FixupModuleHost.makeHomeViewController(
    options: options
)

navigationController?.pushViewController(viewController, animated: true)
```

控制器会立即返回并显示加载状态。SDK 会请求模板、基础数据和组件数据，成功后更新已经展示的页面。

如果宿主要自己控制首次请求：

```swift
let viewController = FixupModuleHost.makeHomeViewController(
    options: FixupHomeOptions(
        title: "首页",
        automaticallyRefresh: false
    )
)

FixupModuleHost.refresh(force: true) { result in
    switch result {
    case .success:
        print("装修首页刷新成功")
    case .failure(let error):
        print("装修首页刷新失败：\(error.localizedDescription)")
    }
}
```

旧入口仍然可用：

```swift
let viewController = FixupModuleHost.makeHomeViewController(
    title: "首页",
    automaticallyRefresh: true
)
```

## 五、刷新、切换直播间和退出登录

当前直播间或用户发生变化时强制刷新：

```swift
FixupModuleHost.refresh(force: true) { result in
    if case .failure(let error) = result {
        print(error.localizedDescription)
    }
}
```

如果一次刷新期间发生了新的刷新、账号切换或 `reset()`，旧请求不会覆盖新会话的数据，并会以 `.cancelled` 结束回调。

退出登录或切换账号：

```swift
FixupModuleHost.reset()
```

重新进入装修页面前，需要重新调用 `FixupModuleHost.setHost(...)`，并确认 `FixupModule.shared` 已配置新的接口环境。

## 六、请求头和敏感信息

请求头只从 `requestHeaders()` 获取。SDK 不写死账号、token、密钥、Bundle ID 或微信 App ID。

常见字段：

| 字段 | 用途 |
| --- | --- |
| `packagename` | 宿主 App Bundle ID |
| `wxappId` / `wxappid` | 业务微信 App ID |
| `njyq-userid` | 宿主提供的用户标识 |
| `Authorization` | 宿主鉴权 token |
| `appname` | 宿主业务标识 |

不要把生产 token、私钥或固定账号提交到 SDK 仓库。

## 七、远程配置边界

后端可以下发：

- SDK 已实现的组件类型
- 组件文本、图片、颜色、尺寸和展示配置
- 已实现跳转动作的参数
- 页面背景、主题色和灰度状态

后端不能下发或执行：

- Swift、Objective-C、动态库或原生二进制
- JavaScript、Lua 或其他可执行脚本
- 任意第三方插件
- 未经审核的新业务流程

未知组件或未知跳转类型必须降级为空状态或安全提示，不能因为远程配置而改变 App 的可执行能力。

## 八、错误处理

公开刷新接口返回 `Result<Void, FixupAPIError>`：

- `.notConfigured`：没有配置接口地址，或配置地址不合法
- `.missingHostDependency`：没有设置宿主能力桥
- `.cancelled`：请求已被新会话、新刷新或重置取消
- `.networkError`：网络请求失败
- `.serverError` / `.serverMessage`：服务端返回错误
- `.parsingError`：服务端数据无法解析

宿主应该为无网络、超时、空数据、登录失效和接口错误提供可结束的页面状态。

## 九、审核前检查

提交宿主 App 前请阅读：

- [App Store 审核准备](AppStoreReview.zh-CN.md)
- [隐私与权限说明](Privacy.zh-CN.md)
- [组件配置边界](ComponentSchema.zh-CN.md)

SDK 本身不是 Apple 预审核认证。每个接入 SDK 的宿主 App 仍需独立满足自己的功能性、内容、隐私和审核要求。
