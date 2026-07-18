import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _verbalKey = 'last_verbal_items';
  static const _reasoningKey = 'last_reasoning_items';

  static Future<String?> getLastVerbalItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_verbalKey);
  }

  static Future<String?> getLastReasoningItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reasoningKey);
  }

  static Future<void> saveVerbalItems(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_verbalKey, value);
  }

  static Future<void> saveReasoningItems(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reasoningKey, value);
  }
}
