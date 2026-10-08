import 'package:shared_preferences/shared_preferences.dart';

class ActiveClubStore {
  const ActiveClubStore._();

  static const _key = 'active_club_id';

  static Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  static Future<void> write(String clubId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, clubId);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}