## OtterJot (NoteEnglish) v0.0.3 发布说明

欢迎使用 **OtterJot v0.0.3**！本次版本带来了备受期待的 **全局划词润色（Global Quick Polish）** 重磅特性，并在全平台工程化、安装包命名规范与分发体验上进行了全面升级。

---

### 🚀 新增功能 (New Features)

#### 1. 全局划词润色与快捷键替换 (Global Quick Polish)
- **macOS 全局系统级快捷键**：默认支持 `fn + Space` 或 `⌥ + Space`（Option + Space）。
- **跨应用原地替换**：在 macOS 任意第三方应用程序（微信、Slack、邮件客户端、浏览器、代码编辑器等）中选中一段中英文文本，按下全局快捷键，即可立即调用 AI 大模型进行地道英语表达重塑，并直接就地替换选中内容。
- **语料资产静默沉淀**：划词润色过程中生成的优质短语与地道句式会自动分析并静默沉淀入库，在随笔主界面右侧专属语料库中可随时回顾与溯源。
- **辅助功能权限（Accessibility）智能引导**：设置弹窗内提供系统辅助功能权限状态实时检测、一键跳转 macOS「系统设置 -> 隐私与安全性 -> 辅助功能」、以及在访达中定位应用以方便拖入授权。
- **独立控制开关**：在 AI 设置弹窗中可随时开启或关闭划词润色常驻托盘与全局快捷键监听。

---

### 💎 改进与优化 (Improvements)

1. **macOS DMG 原生拖拽安装体验**：
   - DMG 挂载磁盘镜像中内置了指向系统 `/Applications` 文件夹的快捷方式软链接，双击打开后可直接拖拽 `OtterJot` 图标至右侧文件夹完成安装。
2. **各平台安装包统一命名规范**：
   - 所有平台安装包产物统一升级为 **产品名 + 项目名共存格式（`OtterJot-NoteEnglish-*`）**，便于识别与存档。
3. **全平台高清应用图标全面上线**：
   - 为 Android、iOS、macOS、Windows、Linux 和 Web 端生成并适配了全套高分辨率水獭主编图标。
4. **Web 端自动部署到 GitHub Pages**：
   - 每次发布新版本时，Web 端静态站点将自动部署更新至 GitHub Pages，支持在线免安装直接体验：[https://excing.github.io/NoteEnglishApp/](https://excing.github.io/NoteEnglishApp/)。
5. **划词润色随笔落库闭环与原生稳定性修复 (Bug Fixes & Enhancements)**：
   - **随笔笔记自动落库闭环**：全局划词润色在重塑地道表达的同时，会自动将该段内容作为随笔落库保存，并沉淀主编 5 大板块结构化分析及高价值语料，用户打开主界面即可随时回顾；
   - **多级 Accessibility 文本抓取增强**：新增原生辅助功能深层焦点元素穿透算法，显著提升第三方 App（浏览器、Slack、邮件、代码编辑器等）选中文本的识别率；
   - **现代化通知与时序优化**：采用 `UNUserNotificationCenter` 现代通知体系，优化剪贴板替换时序与防污染隔离保护机制。

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
> **macOS 首次打开安全提示**：如遇 Gatekeeper 拦截提示“无法验证开发者”，在终端运行 `xattr -cr /Applications/OtterJot.app` 或在「系统设置 -> 隐私与安全性」中点击「仍要打开」即可。
