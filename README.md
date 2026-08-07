# FixupModule

中文完整接入文档请查看：[README.zh-CN.md](README.zh-CN.md)。

工程化文档：

- [中文完整接入文档](Docs/Integration.zh-CN.md)
- [App Store 审核准备](Docs/AppStoreReview.zh-CN.md)
- [隐私与权限说明](Docs/Privacy.zh-CN.md)
- [组件配置边界](Docs/ComponentSchema.zh-CN.md)

FixupModule is a closed-source iOS Swift Package for rendering native decoration
components. The public repository contains the package manifest, integration
documentation, and release metadata only. The implementation is distributed as
an XCFramework binary through GitHub Releases.

## Requirements

- iOS 14.0+
- Swift 5.9+
- Xcode 15+

## Installation

In Xcode, add the package repository:

```text
https://github.com/alding/fixup-native-sdk.git
```

For production applications, use a released tag instead of tracking `main`.

The package downloads `FixupModule.xcframework.zip` from the matching GitHub
Release. The checksum is pinned in `Package.swift`; consumers do not receive
the SDK implementation source code.

```swift
import FixupModule
```

## Recommended Setup

Create a typed configuration and validate it before presenting an SDK page:

```swift
let configuration = FixupModuleConfiguration(
    baseURL: "https://api.example.com",
    liveGWURL: "https://gateway.example.com",
    rewardURL: "https://reward.example.com",
    shopURL: "https://shop.example.com",
    livePayURL: "https://pay.example.com",
    chainBaseURL: "https://chain.example.com"
)

FixupModule.shared.configure(configuration)

guard FixupModule.shared.isConfigured else {
    print(FixupModule.shared.configurationErrors)
    return
}
```

`livePayURL` and `chainBaseURL` fall back to `baseURL` when omitted.
Only `http` and `https` endpoints with a host are accepted by validation.

The previous string-based overloads remain available for compatibility:

```swift
FixupModule.shared.configure(
    baseURL: "https://api.example.com",
    liveGWURL: "https://gateway.example.com",
    rewardURL: "https://reward.example.com",
    shopURL: "https://shop.example.com"
)
```

## Host Capabilities

The SDK does not own the host application's login, navigation, mini-program,
advertising, toast, or WebView implementation. The host supplies those
capabilities through `FixupModuleDependency`.

```swift
final class AppFixupDependency: FixupModuleDependency {
    var isDecorationEnabled: Bool { true }
    var shouldShowHomeWebActionButtons: Bool { true }

    func refreshHomePage(completion: (() -> Void)?) {
        completion?()
    }

    func currentLiveID() -> Int { 0 }
    func currentUserID() -> Int { 0 }
    func currentMallURL() -> String? { nil }
    func currentWebViewCookies() -> [[String: String]] { [] }
    func requestHeaders() -> [String: String] { [:] }

    func openHomeWebView(from viewController: UIViewController, urlString: String) {}
    func openTopicLivePage(from viewController: UIViewController, urlString: String) {}
    func launchMiniProgram(appId: String?, userName: String, path: String) {}

    func presentInterstitialAd(
        from viewController: UIViewController,
        appId: String,
        placementId: String,
        onClick: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {}

    func showToast(_ message: String) {}

    func handleScanHomeQRCode(
        from viewController: UIViewController,
        body: Any,
        completion: @escaping (String) -> Void
    ) {}

    func makeSettingsViewController() -> UIViewController {
        UIViewController()
    }

    func makeRoomListViewController() -> UIViewController {
        UIViewController()
    }
}

FixupModuleHost.setHost(AppFixupDependency())
```

When the host tears down the related session, it can remove the bridge:

```swift
FixupModuleHost.reset()
```

## Public Scope

The SDK owns:

- Native decoration component rendering
- Component and template model decoding
- Image loading and bundled resources
- Component lifecycle and rendering state
- Standard component actions and error states

The host app owns:

- Authentication and user session state
- Request headers and business authorization
- WebView and native page routing
- WeChat, mini-program, advertising, and QR capabilities
- Host analytics and business-specific telemetry

## App Review Notes

Remote configuration may provide component data, styles, images, and navigation
parameters for component types already implemented by the SDK. It must not
download or execute native code, scripts, or arbitrary plugins.

The host app should provide App Review with:

- A test account or review mode when login is required
- The exact navigation path to the decoration page
- Any required test environment information
- A description of the SDK's native component role

The package includes `PrivacyInfo.xcprivacy`. The SDK does not include
advertising, tracking, or host-app credentials. It uses app-scoped
`UserDefaults` for local component display and layout state. The host app must
review its own data collection and declare any additional capabilities it
provides through `FixupModuleDependency`.

## Versioning

Use semantic versioning:

- `1.0.0`: first stable public API
- `1.1.0`: compatible public API improvements and session-safe refresh
- `1.1.1`: backward-compatible native component fixes
- `1.2.0`: binary-only distribution with the synchronized native component implementation
- `1.0.x`: backward-compatible fixes
- `1.x.0`: backward-compatible features
- `2.0.0`: breaking public API changes

Production apps should depend on a tag or version range, not an unpinned branch.

## Release Checklist

Before publishing a new version:

1. Update the public API documentation.
2. Update `CHANGELOG.md`.
3. Run the iOS Simulator build and test commands from `CONTRIBUTING.md`.
4. Verify `PrivacyInfo.xcprivacy` and third-party notices.
5. Create a semantic-version tag and consume that tag from host applications.

## Repository Scope

This repository contains the public binary distribution of the `FixupModule`
Swift Package. It intentionally excludes the original host application, Pods,
project settings, app-specific bridge implementations, and SDK implementation
source code. Release assets are the distributable artifact; the package source
is not a source distribution.
