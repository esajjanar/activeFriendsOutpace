import 'dart:io';

import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/features/feedback/data/feedback_model.dart';
import 'package:activefriends/features/feedback/data/feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _repo = FeedbackRepository(Supabase.instance.client);
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  // Segmented control: 0 = New, 1 = My Feedback
  int _tab = 0;

  // Form state
  FeedbackCategory? _category;
  FeedbackArea? _screen;
  final List<XFile> _screenshots = [];
  static const _maxScreenshots = 3;
  bool _isSubmitting = false;
  int _todayCount = 0;
  static const _dailyLimit = 5;

  // History state
  late Future<List<FeedbackItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _repo.myFeedback();
    _loadTodayCount();
  }

  Future<void> _loadTodayCount() async {
    final count = await _repo.todayCount();
    if (mounted) setState(() => _todayCount = count);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _category != null &&
      _screen != null &&
      _descController.text.trim().isNotEmpty &&
      !_isSubmitting &&
      _todayCount < _dailyLimit;

  Future<void> _pickScreenshot() async {
    if (_screenshots.length >= _maxScreenshots) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image != null && mounted) {
      setState(() => _screenshots.add(image));
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      await _repo.submit(
        category: _category!,
        screen: _screen!,
        description: _descController.text,
        screenshotPaths: _screenshots.map((f) => f.path).toList(),
      );
      if (!mounted) return;
      setState(() {
        _category = null;
        _screen = null;
        _screenshots.clear();
        _descController.clear();
        _todayCount++;
        _historyFuture = _repo.myFeedback();
      });
      _showSuccessDialog();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit feedback. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF14827B)),
        title: const Text('Thank you!'),
        content: const Text('Vikas will look into this.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Switch to My Feedback tab so they see their submission
              setState(() => _tab = 1);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('New'), icon: Icon(Icons.edit_outlined, size: 18)),
                ButtonSegment(value: 1, label: Text('My Feedback'), icon: Icon(Icons.history, size: 18)),
              ],
              selected: {_tab},
              onSelectionChanged: (sel) => setState(() => _tab = sel.first),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0 ? _buildNewTab(theme, colors) : _buildHistoryTab(theme, colors),
          ),
        ],
      ),
    );
  }

  // ── New Feedback tab ──────────────────────────────────────────

  Widget _buildNewTab(ThemeData theme, AppColors colors) {
    if (_todayCount >= _dailyLimit) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.feedback_outlined, size: 56, color: colors.textMuted),
              const SizedBox(height: 16),
              Text(
                "You've shared $_dailyLimit feedbacks today — thanks!",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Try again tomorrow.',
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        // Remaining count
        Text(
          '${_dailyLimit - _todayCount} of $_dailyLimit remaining today',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: 16),

        // Screen chips
        Text('Which screen?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackArea.values.map((s) {
            final selected = _screen == s;
            return FilterChip(
              label: Text(s.label),
              selected: selected,
              onSelected: (_) => setState(() => _screen = s),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Category chips
        Text('Type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackCategory.values.map((c) {
            final selected = _category == c;
            return FilterChip(
              avatar: Text(c.icon, style: const TextStyle(fontSize: 16)),
              label: Text(c.label),
              selected: selected,
              onSelected: (_) => setState(() => _category = c),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Description
        Text('Description', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 5,
          minLines: 3,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: "Describe what happened or what you'd like...",
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Screenshots (up to 3)
        if (_screenshots.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _screenshots.length + (_screenshots.length < _maxScreenshots ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                // "Add more" button at the end
                if (index == _screenshots.length) {
                  return GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: colors.textMuted),
                          const SizedBox(height: 4),
                          Text(
                            '${_screenshots.length}/$_maxScreenshots',
                            style: theme.textTheme.labelSmall?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Thumbnail with remove button
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_screenshots[index].path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _screenshots.removeAt(index)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.danger,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _pickScreenshot,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Attach Screenshots (up to 3)'),
          ),
        const SizedBox(height: 24),

        // Submit
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  // ── My Feedback tab ───────────────────────────────────────────

  Widget _buildHistoryTab(ThemeData theme, AppColors colors) {
    return FutureBuilder<List<FeedbackItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: colors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'No feedback yet',
                  style: theme.textTheme.titleMedium?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _historyFuture = _repo.myFeedback());
            await _historyFuture;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _FeedbackCard(item: items[index]),
          ),
        );
      },
    );
  }
}

// ── Compact feedback card ─────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item});

  final FeedbackItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final ago = _timeAgo(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: category icon + category + screen chip
          Row(
            children: [
              Text(item.category.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                item.category.label,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.screen.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (item.screenshotUrls.isNotEmpty) ...[
                Icon(Icons.image_outlined, size: 16, color: colors.textFaint),
                if (item.screenshotUrls.length > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${item.screenshotUrls.length}',
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.textFaint),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Description (truncated)
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),

          // Footer: time ago + status badge
          Row(
            children: [
              Text(
                ago,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(width: 12),
              Text(item.status.badge, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                item.status.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
