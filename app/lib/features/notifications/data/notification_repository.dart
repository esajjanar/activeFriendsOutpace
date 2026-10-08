import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Stream<int> watchUnreadCount() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(0);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((rows) => rows.where((row) => row['seen'] == false).length);
  }
}