## OtterJot (NoteEnglish) v0.0.5 发布说明

欢迎使用 **OtterJot v0.0.5**！本次版本带来了重磅的 **深度思考模式（Deep Thinking）**、**上下文追问交互全流程进化** 以及 **领域核心服务统一重构**，并针对移动端（Android & iOS）进行了一系列极致的用户体验打磨，在智能化程度、交互流畅性与工程架构稳固性上迈上了全新的台阶。

---

### 🚀 新增功能与核心亮点 (New Features & Highlights)

#### 1. 🧠 深度思考模式与思维链提取展示 (Deep Thinking Mode)
- **大模型思考过程可视化**：支持在 AI 设置中开启「深度思考模式」，主编分析面板以温润琥珀色（Warm Amber）折叠卡片形式展现 AI 思考推理过程，从母语心理思维桥梁到地道语感重塑的推导路径一目了然。
- **广泛协议兼容与自适应降级**：网关层适配 OpenAI / DeepSeek / Claude 标准思维协议参数（`thinking`、`reasoning_effort`、`enable_thinking`），并在第三方端点不支持时自动降级重试，兼顾兼容性与稳定性。
- **双模解析保障**：同时支持 API 原生 `reasoning_content` 与结构化 JSON 思维链提取。

#### 2. 💬 上下文追问交互全流程进化 (Optimistic Inquiry Flow)
- **乐观即时上屏**：发送追问后，用户提问瞬间上屏呈现，告别白屏等待。
- **独立思考加载动效**：追问卡片带有微光动态指示，思考状态优雅呈现。
- **就地重试与草稿恢复保护**：若因网络抖动或 API 配额导致追问失败，提供直接就地「重试追问」及「恢复草稿」至输入框机制，彻底杜绝灵感与提问文字意外丢失。

#### 3. 🌐 用户母语偏好个性化定制 (Customizable User Native Language)
- **专属母语桥梁**：新增母语偏好配置（中文、英语、日语、韩语、德语、法语等），AI 批改与思维桥梁分析自动针对用户的母语进行针对性地道对比与文化视角解构。

---

### 💎 移动端体验优化与稳定性修复 (Mobile UX & Stability)

1. **移动设备屏幕方向锁定为竖屏 (Portrait Orientation Lock)**：
   - 解决手机端持握或躺卧时界面意外翻转横屏的问题，强制保持竖屏专注书写排版。
   - 建立单一信源 `AppDeviceOrientation`并在入口层强制锁定 Preferred Orientations，同时在 Android (`MainActivity`) 与 iOS (`Info.plist`) 双端完成系统级限制。
2. **Android 输入法与候选词联想体验恢复 (IME & Typing UX)**：
   - 修复此前因关闭输入建议导致搜狗/百度/Gboard 等第三方输入法将编辑区误判为「密码安全键盘」的问题，恢复输入法候选词与联想能力，保留中英文顺畅输入与不强制纠错的沉浸手感。
3. **Android Release 网络通信与权限补全**：
   - 在 Android Release 清单中补全 `INTERNET` 权限声明，确保正式发布包中实时天气与 AI 请求畅通无阻。
4. **地理位置与天气预报高可用容错 (Weather Resilience)**：
   - 基于 FreeIPAPI 实现无感知精确定位当前城市并拉取天气，在离线或公共接口波动时平滑降级至默认安全坐标，保证写作体验不中断。
5. **视觉层次与字体字阶精修 (App Typography)**：
   - 重塑全局字阶规范（`AppTypography`），大幅增强了标题、正文文本以及微注释之间的视觉节奏与阅读舒适感。
6. **全量自动化测试与工程质量保证**：
   - 测试套件全量扩充（涵盖设备方向配置、`EditorialAnalysisService`、天气网关、母语解析、思维链、追问状态机及 UI 组件），全量测试 100% 通过，代码静态分析 0 警告 0 错误。

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
