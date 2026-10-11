/// 语料掌握状态枚举
enum MasteryStatus {
  encountered('初遇', '🌱'),
  practicing('练习中', '🌿'),
  internalized('已内化', '🌳');

  final String label;
  final String icon;

  const MasteryStatus(this.label, this.icon);

  static MasteryStatus fromString(String? value) {
    if (value == null) return MasteryStatus.encountered;
    return MasteryStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label == value,
      orElse: () => MasteryStatus.encountered,
    );
  }
}
