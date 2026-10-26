import 'package:shared_preferences/shared_preferences.dart';

class VacationService {
  static const _key = 'outpace_vacation_mode_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_key, true);
      return;
    }
    await prefs.remove(_key);
  }
}
