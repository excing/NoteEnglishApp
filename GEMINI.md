# 项目开发与构建规范 (NoteEnglishApp)

## 1. 构建与测试产物路径规范
- **禁止使用默认全局目录**：编译和测试时，严禁使用 Xcode 默认全局路径（`~/Library/Developer/Xcode/DerivedData`）。
- **统一构建输出路径**：所有编译、测试、归档产物必须统一定向到 `./NoteEnglishMac/build` 目录（即使用 `-derivedDataPath ./NoteEnglishMac/build`）。
- **禁止污染源码目录**：
  - 产物目录为外层的 `NoteEnglishMac/build/`。
  - 严禁将 build 目录指定到内层源码目录（`NoteEnglishMac/NoteEnglishMac/`），以防止 Xcode 文件系统同步组（Synchronized Root Group）将编译缓存错误扫描为源码。

## 2. 常用终端命令规范

### 编译应用 (Build)
```bash
xcodebuild -project NoteEnglishMac/NoteEnglishMac.xcodeproj \
           -scheme NoteEnglishMac \
           -destination 'platform=macOS' \
           -derivedDataPath ./NoteEnglishMac/build \
           build
```

### 运行自动化测试 (Test)
```bash
xcodebuild test -project NoteEnglishMac/NoteEnglishMac.xcodeproj \
                -scheme NoteEnglishMac \
                -destination 'platform=macOS' \
                -derivedDataPath ./NoteEnglishMac/build
```

### 启动可执行文件 (Run)
```bash
# 方式 A：前台运行（查看控制台日志与 print 输出）
./NoteEnglishMac/build/Build/Products/Debug/NoteEnglishMac.app/Contents/MacOS/NoteEnglishMac

# 方式 B：后台独立窗口拉起
open ./NoteEnglishMac/build/Build/Products/Debug/NoteEnglishMac.app
```

## 3. 版本控制 (Git) 规范
- `./NoteEnglishMac/build/` 属于临时构建缓存，必须包含在 `.gitignore` 中，严禁提交到代码仓库。
