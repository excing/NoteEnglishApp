# NoteEnglish 全平台架构实现与落地审计文档

## 一、架构落地概览 (DDD + TDD + SSOT)

本项目已严格按照领域驱动设计（DDD）分层模型落地，所有核心业务逻辑均有对应的单元测试与契约测试支撑，核心信源统一收口，杜绝硬编码与胶水代码。

### 1. 核心分层结构
- **Domain Layer (纯 Dart，无外部依赖)**：
  - **契约与单一信源 (`domain/contracts/ai_contracts.dart`)**：定义结构化 JSON Schema、系统底座不可篡改指示词与默认纽约客主编风格提示词。
  - **随笔上下文 (`domain/models/diary/`)**：`DiaryEntry` 聚合根、`DiaryMetadata`、`WeatherCondition`。
  - **梳理与追问实体 (`domain/models/analysis/`, `domain/models/inquiry/`)**：
    1. 非英文字词翻译及解释（`NonEnglishTranslationItem`，若无则不显示）
    2. 不正确的英文表达及解释（`ExpressionCorrectionItem`）
    3. 原文风格的英文版本（`originalStyleEnglishVersion`）
    4. 不地道的英文表达及解释与思维桥梁（`UnnaturalExpressionItem`）
    5. 地道英文表达进阶版本（`authenticAdvancedVersion`）
    6. 追问结构化响应（`InquiryStructuredResponse`，含自然语言回复、重点、示例）
  - **配置聚合根与内置预设服务 (`domain/models/config/`)**：`AiProfileConfig`、`AiProviderType`、`BuiltInAiService`（单一信源预设服务商，默认首选 OVHcloud AI 免 Key 开放端点配合 `Qwen3.8-27B` 开箱即用，并支持 OpenAI 官方、DeepSeek 与自定义兼容端点）。
  - **语料资产聚合 (`domain/models/corpus/`)**：`CorpusItem`、`CorpusSource`（情境原句与随笔溯源）、`MasteryStatus`。
  - **领域服务 (`domain/services/`)**：
    - `UserLanguageResolver`：操作系统语言解析单一信源（自动识别用户电脑系统语言，如中文、日文、法文等）。
    - `PromptTemplateEngine`：双层提示词引擎（保持原版提示词严密结构不变，将硬编码“中文/中式”原位替换为用户系统语言，释义与思维桥梁自动精准适配）。
    - `CorpusIngestionService`：语料自动去重与入库服务（梳理与追问抽取的语料隐蔽入库）。
  - **仓储与网关抽象**：`IDiaryRepository`、`ICorpusRepository`、`IAiConfigRepository`、`IAiGateway`。

- **Infrastructure Layer (基础设施与防腐层 ACL)**：
  - `OpenAiCompatibleAiGateway`：支持自定义任意第三方 OpenAI 兼容端点、API Key 与自定义 Headers，并原生适配免 API Key 开放端点（API Key 留空时不发送 Bearer 请求头，确保免密调用合规）。
  - `RobustJsonParser`：健壮的 JSON 清洗解析器，自动清洗 Markdown 围栏与多余闲聊字符。
  - `fetchAvailableModels`：支持向 `/models` 自动拉取第三方平台的可用模型列表。
  - `LocalDiaryRepository`、`LocalCorpusRepository`、`SecureAiConfigRepository`：全平台本地响应式仓储与安全存储。

- **Application Layer (应用状态管理)**：
  - `DiaryEditorialCubit`：日记草稿编辑、字数天气同步、呼叫主编结构化梳理、语料自动静默存库。
  - `InquiryCubit`：携带上下文追问、自然语言+重点+示例结构化解析、延伸语料自动入库。
  - `CorpusDeckCubit`：场景化语料卡片展示与掌握程度切换。
  - `AiSettingsCubit`：API 配置、内置预设服务切换与模型动态获取。

- **Presentation Layer (全平台极简极致体验 UI)**：
  - `WritingStudioPage`：沉浸式手账质感稿纸、无红色波浪线打扰、桌面端双栏与移动端自适应。
  - `EditorialInspectorView`：5 大结构化板块优雅渲染，非英文字词自适应隐藏。
  - `InquiryBottomSheet`：追问交互流。
  - `CorpusDeckPage`：专属生活语料库。
  - `AiSettingsDialog`：内置可选服务商切换、接口配置、模型获取与状态栏快捷润色设置。
  - `AppThemeTokens`：温润米白浅色与深烘焙深色双主题单一信源。

---

## 二、测试验证清单 (TDD)
1. `test/domain/contracts/ai_contracts_test.dart`：验证双层 Prompt 组装与结构化 JSON 解析。
2. `test/domain/services/corpus_ingestion_service_test.dart`：验证语料草稿提取、情境锚定与去重算法。
3. `test/infrastructure/adapters/robust_json_parser_test.dart`：验证 Markdown 围栏清洗与容错解析。
4. `test/infrastructure/adapters/openai_compatible_ai_gateway_test.dart`：验证第三方 API 契约与模型列表拉取。
5. `test/application/editorial/diary_editorial_cubit_test.dart`：验证梳理全流程与语料自动入库数据流。
6. `test/widget_test.dart`：验证主界面组件树正常挂载。

---

## 三、工程化与 CI/CD 自动化
- **全平台打包流水线**：[`.github/workflows/build-and-release.yml`](../.github/workflows/build-and-release.yml)
  - 覆盖平台：Android (`.apk`, `.aab`)、iOS (`.ipa`, `.zip`)、macOS (`.dmg`, `.zip`)、Windows (`.zip`)、Linux (`.tar.gz`)、Web (`.zip`)。
  - 触发方式：支持推送版本 Tag（如 `v1.0.0`）自动创建 GitHub Release，或通过 GitHub Actions 手动调度打包。
- **代码质量流水线**：[`.github/workflows/ci.yml`](../.github/workflows/ci.yml)
  - 针对 PR / push 触发，执行 `flutter analyze` 静态分析与全量单元测试。
- **详细操作手册**：参见 [`docs/CI_CD_GUIDE.md`](CI_CD_GUIDE.md)。
