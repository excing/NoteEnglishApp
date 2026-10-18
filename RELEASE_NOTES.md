## OtterJot (NoteEnglish) v0.0.4 发布说明

欢迎使用 **OtterJot v0.0.4**！本次版本带来了重大体验升级 —— **开箱即用的免密 AI 服务预设支持**，同时重构了 AI 服务提供商体系，让新用户无需配置繁琐的 API Key 即可即刻开始地道英语写作与全局划词润色。

---

### 🚀 新增功能与核心亮点 (New Features & Highlights)

#### 1. 开箱即用：内置 OVHcloud AI 免密大模型服务 (Keyless Out-of-the-Box AI)
- **免 API Key 极速体验**：默认预设接入 **OVHcloud AI 官方开放端点** 并预设 **`Qwen3.8-27B`** 大模型。
- **零门槛上手**：新下载安装的用户无需注册任何账号或绑定信用卡，打开软件即可直接体验水獭主编的 5 大结构化分析、地道重塑以及 macOS 全局划词润色功能。

#### 2. 内置 AI 服务商单一信源与智能切换 (Built-in AI Service Providers)
- **多服务商预设**：AI 设置面板新增「内置可选 AI 服务 / 预设服务商」下拉选择器，涵盖：
  - **OVHcloud AI (免 API Key)**：自带绿色「免Key」徽章，默认选用 `Qwen3.8-27B`，并预置 LLaMA 3.1 70B、Mistral 7B 等开源模型；
  - **OpenAI 官方**：预设 `https://api.openai.com/v1` 与 `gpt-4o`、`gpt-4o-mini` 等模型；
  - **DeepSeek 官方**：预设 `https://api.deepseek.com/v1` 与 `deepseek-chat`、`deepseek-reasoner`；
  - **自定义 (OpenAI 兼容协议)**：支持任意中转或自建网关。
- **智能联动填充**：切换预设服务商时自动联动 Base URL、推荐默认模型，并自适应调整 API Key 的必填提示（免密服务提示「API Key (免密可选)」，可直接留空）。

---

### 💎 改进与优化 (Improvements & Fixes)

1. **防腐层协议适配（免密请求头过滤）**：
   - 适配免密开放端点与私有内网端点，当 API Key 留空时不发送 `Authorization: Bearer` 请求头，彻底解决无效/空 Token 引发的 HTTP 401/400 校验异常。
2. **AI 配置聚合根状态判定优化**：
   - 根据选中的服务商类型动态判定 `isApiKeyRequired` 与 `isConfigured`，免密服务无需输入密钥即判定为已就绪。
3. **macOS 全局快捷润色稳定性维护**：
   - 优化 `QuickPolishManager` 析构流程，规范系统状态栏常驻项的释放逻辑。
4. **测试套件与代码规范 100% 达成**：
   - 全面覆盖服务商单一信源解析测试、免密网关请求头断言测试与 UI 切换交互测试，全量 150 项自动化测试全绿，代码静态分析 0 警告 0 错误。

---

### 📦 各平台安装包下载与分发指引

下方的 **Assets** 附件提供了所有平台的独立安装包：

| 平台 | 产物文件名 | 说明 |
| :--- | :--- | :--- |
| **Android (APK)** | `OtterJot-NoteEnglish-Android-release.apk` | 安卓手机直接侧载安装测试（已配置签名） |
| **Android (AAB)** | `OtterJot-NoteEnglish-Android-release.aab` | Google Play 官方上架格式 |
| **iOS (未签名)** | `OtterJot-NoteEnglish-iOS-unsigned.ipa`<br>`OtterJot-NoteEnglish-iOS-Runner.app.zip` | 适用于 AltStore、TrollStore、爱思助手或企业重签名 |
| **macOS (DMG/ZIP)** | `OtterJot-NoteEnglish-macOS.dmg`<br>`OtterJot-NoteEnglish-macOS.zip` | 内置 Applications 拖拽快捷方式，支持一键安装 |
| **Windows (x64)** | `OtterJot-NoteEnglish-Windows-x64.zip` | 包含 Release 运行目录及所有依赖动态库 |
| **Linux (x64)** | `OtterJot-NoteEnglish-Linux-x64.tar.gz` | Linux x64 独立可执行 bundle |
| **Web 站点包** | `OtterJot-NoteEnglish-Web.zip` | 静态网页包，解压后可部署在 Nginx、Vercel 等服务器 |

> [!TIP]
> - **在线体验**：Web 端持续自动部署至 GitHub Pages：[https://excing.github.io/NoteEnglishApp/](https://excing.github.io/NoteEnglishApp/)
> - **macOS 首次打开安全提示**：如遇 Gatekeeper 拦截提示“无法验证开发者”，在终端运行 `xattr -cr /Applications/OtterJot.app` 或在「系统设置 -> 隐私与安全性」中点击「仍要打开」即可。
