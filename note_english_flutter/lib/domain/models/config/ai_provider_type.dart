/// AI 接口提供商类型
enum AiProviderType {
  openAiCompatible('OpenAI 兼容协议 (支持第三方中转/自建)'),
  anthropic('Anthropic Claude 协议'),
  gemini('Google Gemini 协议');

  final String displayName;
  const AiProviderType(this.displayName);
}
