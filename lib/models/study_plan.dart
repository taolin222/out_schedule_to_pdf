class StudyPlan {
  final DateTime examDate;
  final DateTime planDate;
  final String verbalItems;    // 换行分隔的子项目，如 "逻辑填空\n语句衔接"
  final String reasoningItems; // 换行分隔的子项目

  const StudyPlan({
    required this.examDate,
    required this.planDate,
    required this.verbalItems,
    required this.reasoningItems,
  });

  /// 星期几的中文名称
  String get weekdayChinese {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[planDate.weekday - 1];
  }

  /// 距考试天数
  int get daysUntilExam => examDate.difference(planDate).inDays;

  /// 言语子项目列表（按行拆分）
  List<String> get verbalItemList =>
      verbalItems.split('\n').where((s) => s.trim().isNotEmpty).toList();

  /// 判断推理子项目列表（按行拆分）
  List<String> get reasoningItemList =>
      reasoningItems.split('\n').where((s) => s.trim().isNotEmpty).toList();
}
