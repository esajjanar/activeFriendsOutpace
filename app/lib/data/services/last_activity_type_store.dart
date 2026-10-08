import 'package:shared_preferences/shared_preferences.dart';

class LastActivityTypeStore {
  const LastActivityTypeStore._();

  static const _key = 'last_activity_type';

  static Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  static Future<void> write(String type) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, type);
  }
}
