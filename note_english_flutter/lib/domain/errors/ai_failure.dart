import 'package:equatable/equatable.dart';

/// AI 领域失败对象抽象
abstract class AiFailure extends Equatable implements Exception {
  final String message;
  const AiFailure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// 凭据鉴权失败 (HTTP 401/403)
class AiAuthenticationFailure extends AiFailure {
  const AiAuthenticationFailure([
    super.message = 'API Key 无效或未授权，请检查您的凭据配置',
  ]);
}

/// 网络通信故障或超时
class AiNetworkFailure extends AiFailure {
  const AiNetworkFailure([
    super.message = '无法连接到 AI 服务端点，请检查网络或代理地址',
  ]);
}

/// 指定模型不可用或端点不存在 (HTTP 404)
class AiModelNotAvailableFailure extends AiFailure {
  const AiModelNotAvailableFailure([
    super.message = '所选 AI 模型不可用或端点路径错误',
  ]);
}

/// 响应数据解析异常
class AiResponseParsingFailure extends AiFailure {
  const AiResponseParsingFailure([
    super.message = 'AI 返回的数据不符合预期的结构化协议',
  ]);
}

/// 服务商服务端故障 (HTTP 5xx)
class AiServerFailure extends AiFailure {
  final int? statusCode;
  const AiServerFailure({
    this.statusCode,
    String? message,
  }) : super(message ?? 'AI 服务商返回服务端异常 (${statusCode ?? '未知状态码'})');

  @override
  List<Object?> get props => [message, statusCode];
}

/// 未配置凭据异常
class AiConfigNotSetFailure extends AiFailure {
  const AiConfigNotSetFailure([
    super.message = '尚未配置 AI 接口，请在右上角设置中填写 Base URL 和 API Key',
  ]);
}
