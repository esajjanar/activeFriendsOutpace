import 'package:supabase_flutter/supabase_flutter.dart';

class ClubSummary {
  const ClubSummary({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;
}

class ClubRepository {
  ClubRepository(this._client);

  final SupabaseClient _client;

  Future<ClubSummary> createClub(String name) async {
    final data = await _client.rpc('create_club_with_admin', params: {'club_name': name});
    return ClubSummary(id: data['id'] as String, name: data['name'] as String, role: 'admin');
  }

  Future<ClubSummary> joinWithInvite(String code) async {
    final data = await _client.rpc('join_club_with_invite', params: {'invite_code': code});
    return ClubSummary(id: data['id'] as String, name: data['name'] as String, role: 'member');
  }

  Future<String> createInviteCode(String clubId) async {
    final data = await _client.rpc('create_invite_code', params: {'target_club_id': clubId});
    return data['code'] as String;
  }

  Future<List<ClubSummary>> listMine() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];
    final data = await _client.from('club_members').select('role, clubs(id, name)').eq('user_id', user.id);
    return data.map((row) {
      final club = row['clubs'] as Map<String, dynamic>;
      return ClubSummary(id: club['id'] as String, name: club['name'] as String, role: row['role'] as String);
    }).toList();
  }
}