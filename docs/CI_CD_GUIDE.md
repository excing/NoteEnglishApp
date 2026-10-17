# NoteEnglish 全平台打包与 CI/CD 自动化指南

本文档详细说明如何使用 GitHub Actions 为 NoteEnglish 构建并分发覆盖移动端、桌面端与 Web 端的全平台安装包。

---

## 一、工作流概览

工作流文件位于根目录下：
1. **全平台打包与发布工作流**：[`.github/workflows/build-and-release.yml`](../.github/workflows/build-and-release.yml)
2. **日常代码质量校验工作流**：[`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

### 各平台产物清单

| 平台 | 操作系统 Runner | 产物格式 | 产物文件名 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **Android (移动端)** | `ubuntu-latest` | `.apk` | `OtterJot-NoteEnglish-Android-release.apk` | 适合侧载/真机直接安装测试 |
| **Android (移动端)** | `ubuntu-latest` | `.aab` | `OtterJot-NoteEnglish-Android-release.aab` | Google Play 官方分发格式 |
| **iOS (移动端)** | `macos-latest` | `.ipa` / `.zip` | `OtterJot-NoteEnglish-iOS-unsigned.ipa`<br>`OtterJot-NoteEnglish-iOS-Runner.app.zip` | 未签名包，支持 AltStore / TrollStore / 个人免费证书或签名工具重签 |
| **macOS (桌面端)** | `macos-latest` | `.dmg` / `.zip` | `OtterJot-NoteEnglish-macOS.dmg`<br>`OtterJot-NoteEnglish-macOS.zip` | 包含独立可运行的 Mac 应用程序及磁盘映像（支持拖拽安装） |
| **Windows (桌面端)** | `windows-latest` | `.zip` | `OtterJot-NoteEnglish-Windows-x64.zip` | 包含 Release 运行目录与依赖动态库 |
| **Linux (桌面端)** | `ubuntu-latest` | `.tar.gz` | `OtterJot-NoteEnglish-Linux-x64.tar.gz` | Linux x64 独立运行 bundle |
| **Web** | `ubuntu-latest` | `.zip` | `OtterJot-NoteEnglish-Web.zip` | 生产静态网页包，解压后可部署在 Nginx、Vercel、GitHub Pages 等 |

---

## 二、触发与使用方式

### 方式 1：打 Tag 自动发布全平台 Release（推荐正式发版使用）

当在 Git 中推送形如 `v*` 的版本 Tag 时，工作流会自动触发所有平台编译，并在成功后创建 GitHub Release，将上述所有安装包作为 Release 附件直接提供下载。

```bash
# 本地打 tag 并推送到 GitHub
git tag v1.0.0
git push origin v1.0.0
```

### 方式 2：在 GitHub 网页手动一键触发（适合随时打包测试）

1. 打开 GitHub 仓库页面，点击顶部导航栏的 **Actions** 选项卡。
2. 在左侧工作流列表中选择 **Build and Release Multi-Platform Packages**。
3. 点击右侧 **Run workflow** 下拉按钮：
   - **Branch**: 默认选择 `main`。
   - **Release Tag name (optional)**：
     - 若**留空**：仅构建所有平台，产物以 **Artifacts** 形式保存在本次 Action 详情页面，提供 90 天内直接下载。
     - 若**填写版本号**（例如 `v1.0.0-beta1`）：除了在 Artifacts 中保存外，还会自动在仓库的 Releases 页面创建该版本的 Release 并挂载全部安装包。
   - **Create draft release**：可选是否生成草稿 Release。
   - **Create pre-release**：可选是否标记为预发布版本。
4. 点击 **Run workflow** 按钮启动构建。

---

## 三、移动端签名补充说明

### 1. Android 签名配置指南

代码工程已支持**正式密钥自动适配 + debug 降级保护**（见 [`android/app/build.gradle.kts`](../note_english_flutter/android/app/build.gradle.kts)）：
- **未配置密钥时**：自动使用 debug 密钥签名，保证任何人在任何机器上都能直接编译运行；
- **配置密钥后**：自动无缝启用正式 Release 签名。

#### 步骤 1：本地生成签名密钥库（Keystore）

在终端中执行以下命令（可在 `note_english_flutter/android/app/` 目录下执行，或任意安全位置）：

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias note_english_key
```

> **注意**：请妥善备份生成的 `upload-keystore.jks` 文件及输入的密码，密钥一旦丢失将无法更新已上架的应用。
> 该文件已被 `android/.gitignore` 自动忽略，**切勿将密钥库提交到任何公共 Git 仓库**。

#### 步骤 2：本地开发环境配置（可选）

若在本地也希望以正式密钥打包，请在 `note_english_flutter/android/key.properties` 中创建文件（该文件已被 git 忽略）：

```properties
storePassword=你的密钥库密码
keyPassword=你的别名密码
keyAlias=note_english_key
storeFile=upload-keystore.jks
```

#### 步骤 3：配置 GitHub Secrets（供 GitHub Actions 自动签名使用）

1. **将密钥库转换为 Base64 编码字符串**：
   在终端运行：
   - macOS / Linux:
     ```bash
     base64 -i upload-keystore.jks | tr -d '\n' | pbcopy
     # 或者输出到文件：
     base64 -i upload-keystore.jks > keystore_base64.txt
     ```
   - Windows (PowerShell):
     ```powershell
     [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
     ```

2. **在 GitHub 仓库添加 Secrets**：
   - 打开 GitHub 仓库页面，点击 **Settings** -> **Secrets and variables** -> **Actions**。
   - 点击 **New repository secret**，依次添加以下 4 项：
     - `ANDROID_KEYSTORE_BASE64`：填入上面复制的 Base64 字符串。
     - `ANDROID_KEYSTORE_PASSWORD`：密钥库密码（storePassword）。
     - `ANDROID_KEY_ALIAS`：别名（如 `note_english_key`）。
     - `ANDROID_KEY_PASSWORD`：别名密码（keyPassword）。

3. **生效效果**：
   配置好上述 Secrets 后，GitHub Actions 运行 `build-android` 任务时会自动将证书安全解码还原，构建出具备官方商业签名的 `.apk` 和 `.aab` 安装包！若未配置 Secrets，则自动安全回退至测试签名。

### 2. iOS 签名机制
- **当前默认状态**：由于 GitHub 公共 Runner 上未内置 Apple 开发者证书，工作流采用了 `--no-codesign` 模式编译，并自动封装为标准未签名 IPA 结构（`NoteEnglishApp-iOS-unsigned.ipa`）。
- **安装方式**：
  1. 使用 **TrollStore**（免重签神器，针对特定 iOS 版本）；
  2. 使用 **AltStore** / **Sideloadly** 配合个人免费 Apple ID 进行自签安装；
  3. 使用企业证书签名服务直接对未签名 IPA 进行重签名分发。
- **配置商用 Apple 开发者账号（可选进阶）**：
  若需生成正式 Distribution 签名包并自动上传至 TestFlight / App Store，可结合 Fastlane 或通过 Apple Developer API Key / P12 证书及 MobileProvision 文件进行自动签名注入。
