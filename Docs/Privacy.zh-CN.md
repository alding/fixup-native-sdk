# 隐私与权限说明

## 一、SDK 当前行为

FixupModule 是一个原生装修组件 Swift Package。SDK 当前：

- 通过宿主提供的接口地址访问装修模板和组件业务数据。
- 通过宿主提供的请求头携带业务鉴权信息。
- 使用包内字体和图片资源渲染组件。
- 使用 `UserDefaults` 保存少量组件尺寸、展示日期和页面状态缓存。
- 不包含广告 SDK、统计 SDK、登录账号系统或宿主 Bundle ID。
- 不主动申请相机、相册、定位、通讯录或通知权限。
- 不在后台下载或执行原生代码、动态库或脚本。

SDK 自己不声明跟踪和收集的用户数据；宿主通过 `FixupModuleDependency` 注入的功能可能拥有额外数据处理行为，必须由宿主单独评估。

## 二、PrivacyInfo.xcprivacy

SDK 发布物包含 `PrivacyInfo.xcprivacy`，声明了 SDK 使用 UserDefaults 的 Required Reason API 访问。

宿主归档后仍应检查最终 App 包中的隐私清单，确保宿主自身和其他第三方 SDK 的声明已经合并并且真实。

## 三、宿主需要自行申报的能力

以下能力不由 SDK 代替宿主申报：

- 宿主自己的账号、手机号、设备标识或业务用户 ID
- 宿主注入的 Authorization、Cookie 和 WebView 数据
- 微信登录、微信小程序和二维码扫码
- 广告展示、广告点击、转化和第三方分析
- 相册保存、相机扫描或其他系统权限
- 宿主页面中的支付、订单和交易信息

如果宿主实现了这些能力，宿主需要同步更新隐私政策、App Store Connect 隐私标签、权限用途文案和审核备注。

## 四、数据最小化建议

- 只在请求期间提供必要的请求头。
- 不要把明文 token、私钥或完整用户资料写入装修配置。
- `currentMallURL()` 只返回当前业务需要的地址。
- 不需要使用 WebView cookie 时返回空数组。
- 账号切换或退出登录时调用 `FixupModuleHost.reset()`。
- 生产环境关闭详细请求日志，避免日志中出现 token、Cookie 或用户标识。
