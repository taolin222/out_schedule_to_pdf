class ModuleKeys {
  static const verbal = '言语理解';
  static const reasoning = '判断推理';
  static const quantity = '数量';
  static const dataAnalysis = '资料分析';
  static const politics = '政治常识';
  static const currentAffairs = '时政';
  static const shenlun = '申论';

  static const defaultOrder = [
    verbal, reasoning, quantity, dataAnalysis,
    politics, currentAffairs, shenlun,
  ];

  /// Parse stored comma-separated string into `List<String>`.
  /// Returns defaultOrder if input is null or empty.
  static List<String> fromStored(String? stored) {
    if (stored == null || stored.trim().isEmpty) return [...defaultOrder];
    final parts = stored.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    // Validate: only known keys, no duplicates, and only these 7 keys
    if (parts.length != defaultOrder.length) return [...defaultOrder];
    if (parts.toSet().length != parts.length) return [...defaultOrder];
    if (!parts.every((p) => defaultOrder.contains(p))) return [...defaultOrder];
    return parts;
  }

  /// Serialize order list to comma-separated string for storage.
  static String toStored(List<String> order) => order.join(',');
}
