import 'package:activefriends/data/services/active_club_store.dart';
import 'package:activefriends/core/presentation/app_mark.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/clubs/presentation/invite_code_dialog.dart';
import 'package:activefriends/features/feedback/data/feedback_repository.dart';
import 'package:activefriends/features/feedback/presentation/feedback_screen.dart';
import 'package:activefriends/features/import/presentation/watch_import_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key, this.onActiveClubChanged});

  final ValueChanged<String>? onActiveClubChanged;

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final _repository = ClubRepository(Supabase.instance.client);
  final _feedbackRepo = FeedbackRepository(Supabase.instance.client);
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  late Future<List<ClubSummary>> _clubsFuture;
  late Future<bool> _shareRoutesFuture;
  late Future<int> _feedbackTodayCountFuture;
  var _joining = true;
  var _isSubmitting = false;
  var _shareRoutes = true;
  String? _activeClubId;
  String? _error;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _clubsFuture = _repository.listMine();
    _shareRoutesFuture = _loadRouteSharing();
    _feedbackTodayCountFuture = _feedbackRepo.todayCount();
    _restoreActiveClub();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    if (mounted) setState(() => _avatarUrl = profile?['avatar_url'] as String?);
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 640,
    );
    final user = Supabase.instance.client.auth.currentUser;
    if (image == null || user == null) return;
    setState(() => _isSubmitting = true);
    try {
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      final avatarUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', user.id);
      if (mounted) setState(() => _avatarUrl = avatarUrl);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[activeFriends][avatar] upload failed: $error');
      }
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile photo upload failed'),
            content: SelectableText('$error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _loadRouteSharing() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return true;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('share_routes')
        .eq('id', user.id)
        .maybeSingle();
    final shareRoutes = profile?['share_routes'] as bool? ?? true;
    if (mounted) setState(() => _shareRoutes = shareRoutes);
    return shareRoutes;
  }

  Future<void> _setRouteSharing(bool enabled) async {
    final user = Supabase.instance.client.auth.currentUser!;
    setState(() => _shareRoutes = enabled);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'share_routes': enabled})
          .eq('id', user.id);
    } catch (_) {
      if (mounted) {
        setState(() => _shareRoutes = !enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route sharing could not be updated.')),
        );
      }
    }
  }

  Future<void> _restoreActiveClub() async {
    final clubId = await ActiveClubStore.read();
    if (mounted) setState(() => _activeClubId = clubId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final club = _joining
          ? await _repository.joinWithInvite(_controller.text)
          : await _repository.createClub(_controller.text.trim());
      await _selectClub(club.id);
      if (mounted) {
        setState(() {
          _controller.clear();
          _clubsFuture = _repository.listMine();
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'That club could not be set up. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectClub(String clubId) async {
    await ActiveClubStore.write(clubId);
    if (!mounted) return;
    setState(() => _activeClubId = clubId);
    widget.onActiveClubChanged?.call(clubId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Active club updated.')));
  }

  Future<void> _deleteClub(ClubSummary club) async {
    // Step 1: warning dialog
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete club?'),
        content: Text(
          'This will permanently delete "${club.name}" and:\n\n'
          '• Remove all members\n'
          '• Delete the leaderboard / weekly snapshot history\n'
          '• Invalidate all invite codes\n\n'
          'Activities are kept — they just won\'t be tied to this club.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<AppColors>()!.danger,
            ),
            child: const Text('I understand, continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    // Step 2: type-to-confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        var typedName = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final matches = typedName == club.name;
            return AlertDialog(
              title: const Text('Type club name to confirm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type "${club.name}" exactly to delete:'),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: club.name,
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setDialogState(() => typedName = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: matches
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).extension<AppColors>()!.danger,
                    disabledBackgroundColor:
                        Theme.of(context).extension<AppColors>()!.danger.withValues(alpha: 0.3),
                  ),
                  child: const Text('Delete permanently'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await _repository.deleteClub(club.id);
      if (!mounted) return;
      final clubs = await _repository.listMine();
      if (!mounted) return;
      if (_activeClubId == club.id) {
        final next = clubs.firstOrNull;
        if (next != null) {
          await _selectClub(next.id);
        } else {
          await ActiveClubStore.write('');
          setState(() => _activeClubId = null);
          widget.onActiveClubChanged?.call('');
        }
      }
      setState(() => _clubsFuture = Future.value(clubs));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Club "${club.name}" deleted.')),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not delete the club. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _leaveClub(ClubSummary club) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        var typedName = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final matches = typedName == club.name;
            return AlertDialog(
              title: const Text('Leave club?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You will be removed from "${club.name}". '
                    'Your activities will remain but won\'t appear in this club\'s '
                    'leaderboard or feed for other members.\n\n'
                    'You can rejoin later with a new invite code.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Type the club name exactly to confirm:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: club.name,
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setDialogState(() => typedName = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: matches
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).extension<AppColors>()!.danger,
                    disabledBackgroundColor:
                        Theme.of(context).extension<AppColors>()!.danger.withValues(alpha: 0.3),
                  ),
                  child: const Text('Leave'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await _repository.leaveClub(club.id);
      if (!mounted) return;
      // If the user left the active club, clear it and pick another.
      final clubs = await _repository.listMine();
      if (!mounted) return;
      if (_activeClubId == club.id) {
        final next = clubs.firstOrNull;
        if (next != null) {
          await _selectClub(next.id);
        } else {
          await ActiveClubStore.write('');
          setState(() => _activeClubId = null);
          widget.onActiveClubChanged?.call('');
        }
      }
      setState(() => _clubsFuture = Future.value(clubs));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You left "${club.name}".')),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not leave the club. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createInviteCode(String clubId) async {
    setState(() => _isSubmitting = true);
    try {
      final code = await _repository.createInviteCode(clubId);
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => InviteCodeDialog(code: code),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'An invite code could not be created. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final email = currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 8, top: 7),
            child: AppMark(size: 36, showName: true),
          ),
        ],
      ),
      body: FutureBuilder<List<ClubSummary>>(
        future: _clubsFuture,
        builder: (context, snapshot) {
          final clubs = snapshot.data ?? [];
          final activeClub = clubs
              .where((club) => club.id == _activeClubId)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _isSubmitting ? null : _pickAvatar,
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      backgroundImage: _avatarUrl == null || _avatarUrl!.isEmpty
                          ? null
                          : NetworkImage(_avatarUrl!),
                      child: _avatarUrl == null || _avatarUrl!.isEmpty
                          ? Text(
                              email.isEmpty
                                  ? '?'
                                  : email.substring(0, 1).toUpperCase(),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My clubs',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _SectionLabel(
                      label: clubs.isEmpty ? 'GET STARTED' : 'MY CLUBS',
                    ),
                  ),
                  if (activeClub?.role == 'admin')
                    OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _createInviteCode(activeClub!.id),
                      icon: const Icon(Icons.key_outlined, size: 18),
                      label: const Text('Invite Code'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (clubs.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.primary),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _activeClubId ?? activeClub?.id,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            borderRadius: BorderRadius.circular(10),
                            icon: Icon(
                              Icons.expand_more,
                              color: theme.colorScheme.primary,
                            ),
                            items: clubs
                                .map(
                                  (club) => DropdownMenuItem(
                                    value: club.id,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            club.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: club.role == 'admin'
                                                ? theme.colorScheme.primary
                                                : colors.border,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            club.role,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: club.role == 'admin'
                                                      ? Colors.white
                                                      : colors.textMuted,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (clubId) =>
                                      clubId == null ? null : _selectClub(clubId),
                          ),
                        ),
                      ),
                    ),
                    if (activeClub != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _leaveClub(activeClub),
                        tooltip: 'Leave club',
                        icon: Icon(
                          Icons.exit_to_app,
                          size: 24,
                          color: colors.danger,
                        ),
                      ),
                      if (activeClub.role == 'admin') ...[
                        const SizedBox(width: 2),
                        IconButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _deleteClub(activeClub),
                          tooltip: 'Delete club',
                          icon: Icon(
                            Icons.delete_forever,
                            size: 20,
                            color: colors.danger,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'WATCH IMPORT'),
              const SizedBox(height: 12),
              const WatchImportSection(),
              const SizedBox(height: 28),
              const _SectionLabel(label: 'ROUTE PRIVACY'),
              const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: _shareRoutesFuture,
                builder: (context, snapshot) => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  title: Text(
                    'Share routes with club',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Show full route maps on your activities.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  value: snapshot.connectionState == ConnectionState.done
                      ? _shareRoutes
                      : false,
                  onChanged: snapshot.connectionState == ConnectionState.done
                      ? _setRouteSharing
                      : null,
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel(label: 'CLUB MANAGEMENT'),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Join with code')),
                  ButtonSegment(value: false, label: Text('Create club')),
                ],
                selected: {_joining},
                onSelectionChanged: (selection) =>
                    setState(() => _joining = selection.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autocorrect: false,
                      textCapitalization: _joining
                          ? TextCapitalization.characters
                          : TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _joining ? 'Invite code' : 'Club name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting
                          ? 'Wait'
                          : _joining
                          ? 'Join'
                          : 'Create',
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: colors.accent)),
              ],
              const SizedBox(height: 28),
              const _SectionLabel(label: 'FEEDBACK'),
              const SizedBox(height: 12),
              FutureBuilder<int>(
                future: _feedbackTodayCountFuture,
                builder: (context, snap) {
                  final used = snap.data ?? 0;
                  final remaining = (5 - used).clamp(0, 5);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      );
                      // Refresh count after returning
                      if (mounted) {
                        setState(() {
                          _feedbackTodayCountFuture =
                              _feedbackRepo.todayCount();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Send Feedback',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '$remaining remaining today',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: colors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

