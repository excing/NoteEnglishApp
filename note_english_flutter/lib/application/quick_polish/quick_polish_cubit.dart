import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_state.dart';
import 'package:note_english_flutter/domain/gateways/quick_polish_platform_gateway.dart';
import 'package:note_english_flutter/domain/services/quick_polish_service.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

/// 全局快捷润色业务状态管理 (Application Cubit)
class QuickPolishCubit extends Cubit<QuickPolishState> {
  static const String _storageKeyEnabled = 'quick_polish_enabled';

  final IQuickPolishPlatformGateway _platformGateway;
  final QuickPolishService _quickPolishService;
  final IStorageEngine? _storageEngine;

  QuickPolishCubit({
    required IQuickPolishPlatformGateway platformGateway,
    required QuickPolishService quickPolishService,
    IStorageEngine? storageEngine,
  })  : _platformGateway = platformGateway,
        _quickPolishService = quickPolishService,
        _storageEngine = storageEngine,
        super(const QuickPolishState()) {
    _platformGateway.setQuickPolishHandler(_handleQuickPolishRequest);
  }

  /// 初始化常驻托盘与全局快捷键
  Future<void> initialize() async {
    await _platformGateway.initialize();

    var isEnabled = false; // 默认关闭桌面菜单栏与全局快捷润色
    if (_storageEngine != null) {
      final storedVal = await _storageEngine.readString(_storageKeyEnabled);
      if (storedVal != null) {
        isEnabled = storedVal.toLowerCase() == 'true';
      }
    }

    emit(state.copyWith(isEnabled: isEnabled));
    await _platformGateway.setQuickPolishEnabled(isEnabled);

    if (isEnabled) {
      await checkAccessibilityPermission();
    }
  }

  /// 切换全局快捷润色功能的开启/关闭
  Future<void> toggleEnabled(bool enabled) async {
    emit(state.copyWith(isEnabled: enabled));
    if (_storageEngine != null) {
      await _storageEngine.writeString(_storageKeyEnabled, enabled.toString());
    }
    await _platformGateway.setQuickPolishEnabled(enabled);

    // 开启时，主动检测相关系统权限是否已就绪
    if (enabled) {
      await checkAccessibilityPermission();
    }
  }

  /// 检查辅助功能权限
  Future<void> checkAccessibilityPermission() async {
    final granted = await _platformGateway.isAccessibilityGranted();
    emit(state.copyWith(isAccessibilityGranted: granted));
  }

  /// 请求系统授予辅助功能权限
  Future<void> requestAccessibilityPermission() async {
    await _platformGateway.requestAccessibilityPermission();
  }

  /// 在访达 (Finder) 中定位并高亮 OtterJot 应用 Bundle
  Future<void> openAppInFinder() async {
    await _platformGateway.openAppInFinder();
  }

  /// 处理从系统全局快捷键传入的选中文本
  Future<String> _handleQuickPolishRequest(String selectedText) async {
    // 若功能已被用户关闭，则直接忽略并保留原文本
    if (!state.isEnabled) {
      return selectedText;
    }

    final trimmed = selectedText.trim();
    if (trimmed.isEmpty) {
      return selectedText;
    }

    emit(state.copyWith(
      status: QuickPolishStatus.processing,
      errorMessage: null,
    ));

    try {
      final result = await _quickPolishService.executeQuickPolish(selectedText);

      emit(state.copyWith(
        status: QuickPolishStatus.success,
        lastResult: result,
      ));

      // 若有新沉淀的语料，提示用户
      final corpusMsg = result.extractedCorpus.isNotEmpty
          ? ' (已沉淀 ${result.extractedCorpus.length} 条生动语料)'
          : '';

      await _platformGateway.showNotification(
        title: 'OtterJot 润色完成',
        body: '已替换为母语级地道英文$corpusMsg',
      );

      return result.polishedText;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(
        status: QuickPolishStatus.failure,
        errorMessage: errorMsg,
      ));

      await _platformGateway.showNotification(
        title: 'OtterJot 润色提示',
        body: errorMsg,
      );

      // 异常时返回原文，保障用户输入内容绝对不丢失
      return selectedText;
    }
  }

  /// 手动直接触发润色（供调试或 UI 快捷调用）
  Future<String> polishText(String text) => _handleQuickPolishRequest(text);
}
