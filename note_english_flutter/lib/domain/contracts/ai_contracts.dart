/// AI 结构化交互协议 - 单一信源 (SSOT)
class AiContracts {
  AiContracts._();

  // ================= 随笔梳理结构化字段键名 =================
  static const String keyNonEnglish = 'nonEnglishTranslations';
  static const String keyIncorrectExpressions = 'incorrectExpressions';
  static const String keyOriginalStyleVersion = 'originalStyleEnglishVersion';
  static const String keyUnnaturalExpressions = 'unnaturalExpressions';
  static const String keyAuthenticAdvancedVersion = 'authenticAdvancedVersion';
  static const String keyExtractedCorpus = 'extractedCorpus';

  // ================= 追问结构化字段键名 =================
  static const String keyInquiryReply = 'reply';
  static const String keyInquiryKeyTakeaway = 'keyTakeaway';
  static const String keyInquiryExamples = 'examples';

  // ================= 通用语料项字段键名 =================
  static const String keyCorpusExpression = 'expression';
  static const String keyCorpusPhonetic = 'phonetic';
  static const String keyCorpusMeaning = 'meaning';
  static const String keyCorpusUsageContext = 'usageContext';

  // ================= 默认系统主编提示词 (用户可自定义覆盖，但不可侵入协议) =================
  static const String defaultEditorialSystemPrompt =
      '你是一位温和、富有洞察力、文学素养极高的纽约客（The New Yorker）杂志双语主编。'
      '你的任务是帮助英语学习者通过随笔写作提升母语级地道语感。'
      '收起教导主任式的刻板语法批改，用温暖优雅的笔触，提供原汁原味的英文重塑与思维桥梁。';

  // ================= 随笔梳理的不可篡改系统底座协议 =================
  static const String diaryAnalysisSchemaInstruction = '''
【重要约束：输出格式协议】
你必须且只能返回纯 JSON 对象，严禁包含任何 Markdown 格式代码块围栏（如 ```json），严禁输出任何多余的解释文字。
JSON 必须严格遵循以下结构规范：
{
  "$keyNonEnglish": [
    {
      "original": "非英文字词原文 (若日记正文中完全没有中文或其他非英语汇，此列表必须为空数组 [])",
      "meaning": "英文翻译与对应词义",
      "explanation": "简短的使用场景或文化背景"
    }
  ],
  "$keyIncorrectExpressions": [
    {
      "original": "原句中包含的语法/拼写错误或硬伤表述",
      "correction": "语法修正后的英文",
      "explanation": "温和指出病因与语法规则解析"
    }
  ],
  "$keyOriginalStyleVersion": "完全保留作者随笔本真口吻、情感色彩与语气的英文自然版本",
  "$keyUnnaturalExpressions": [
    {
      "original": "语法没错但不地道/中式思维的表述",
      "naturalAlternative": "地道母语者口吻的表达方式",
      "mindsetBridge": "思维桥梁：剖析中文母语思维与英文母语思维的转换逻辑"
    }
  ],
  "$keyAuthenticAdvancedVersion": "高质感、地道进阶版（使用生动动词、文学化质感搭配重塑整篇随笔）",
  "$keyExtractedCorpus": [
    {
      "$keyCorpusExpression": "提取的高价值核心词汇或固定搭配短语",
      "$keyCorpusPhonetic": "国际音标 (如 /klɒk aʊt/)",
      "$keyCorpusMeaning": "精准中文释义",
      "$keyCorpusUsageContext": "在本篇日记中的生动语境用法与精妙之处"
    }
  ]
}
''';

  // ================= 追问的不可篡改系统底座协议 =================
  static const String inquirySchemaInstruction = '''
【重要约束：追问输出格式协议】
你必须且只能返回纯 JSON 对象，严禁包含任何 Markdown 格式代码块围栏（如 ```json），严禁输出任何多余的解释文字。
JSON 必须严格遵循以下结构规范：
{
  "$keyInquiryReply": "针对用户追问的详尽、温和、富有启发性的自然语言解答",
  "$keyInquiryKeyTakeaway": "1-2句高度凝练的认知重点或规则提炼",
  "$keyInquiryExamples": [
    "生活场景延伸应用例句1",
    "生活场景延伸应用例句2 (若无则返回空数组 [])"
  ],
  "$keyExtractedCorpus": [
    {
      "$keyCorpusExpression": "追问解答中涉及的高价值核心词汇或搭配 (若无则返回空数组 [])",
      "$keyCorpusPhonetic": "国际音标",
      "$keyCorpusMeaning": "精准中文释义",
      "$keyCorpusUsageContext": "核心用法说明"
    }
  ]
}
''';
}
