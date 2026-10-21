import 'dart:io';

import 'package:activefriends/features/feedback/data/feedback_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackRepository {
  FeedbackRepository(this._client);

  final SupabaseClient _client;

  /// Submit new feedback. Returns the created item.
  Future<FeedbackItem> submit({
    required FeedbackCategory category,
    required FeedbackArea screen,
    required String description,
    List<String> screenshotPaths = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');

    // Upload screenshots (up to 3)
    final screenshotUrls = <String>[];
    for (final path in screenshotPaths) {
      final file = File(path);
      final ext = path.split('.').last;
      final storagePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${screenshotUrls.length}.$ext';
      await _client.storage
          .from('feedback-screenshots')
          .uploadBinary(
            storagePath,
            await file.readAsBytes(),
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: false,
            ),
          );
      screenshotUrls.add(
        _client.storage
            .from('feedback-screenshots')
            .getPublicUrl(storagePath),
      );
    }

    // Gather device metadata
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    final osVersion = Platform.operatingSystemVersion;

    final data = await _client
        .from('feedback')
        .insert({
          'user_id': user.id,
          'category': category.dbValue,
          'screen': screen.dbValue,
          'description': description.trim(),
          'screenshot_urls': screenshotUrls,
          'app_version': appVersion,
          'platform': platform,
          'os_version': osVersion,
        })
        .select()
        .single();

    return FeedbackItem.fromJson(data);
  }

  /// Fetch current user's feedback, newest first.
  Future<List<FeedbackItem>> myFeedback() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];
    final data = await _client
        .from('feedback')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return data.map((row) => FeedbackItem.fromJson(row)).toList();
  }

  /// Count of feedback submitted today (IST) by the current user.
  Future<int> todayCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    // Calculate IST start-of-day in UTC
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final istStartOfDay = DateTime(now.year, now.month, now.day);
    final utcStartOfDay =
        istStartOfDay.subtract(const Duration(hours: 5, minutes: 30));

    final data = await _client
        .from('feedback')
        .select('id')
        .eq('user_id', user.id)
        .gte('created_at', utcStartOfDay.toIso8601String());
    return (data as List).length;
  }
}
