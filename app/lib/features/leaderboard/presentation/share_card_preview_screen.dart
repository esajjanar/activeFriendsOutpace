import 'dart:io';
import 'dart:ui' as ui;

import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/leaderboard/data/leaderboard_repository.dart';
import 'package:activefriends/features/profile/presentation/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareCardPreviewScreen extends StatefulWidget {
  const ShareCardPreviewScreen({
    super.key,
    required this.club,
    required this.entries,
  });

  final ClubSummary club;
  final List<LeaderboardEntry> entries;

  @override
  State<ShareCardPreviewScreen> createState() => _ShareCardPreviewScreenState();
}

class _ShareCardPreviewScreenState extends State<ShareCardPreviewScreen> {
  final _cardKey = GlobalKey();
  var _isSharing = false;

  Future<void> _share() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _isSharing = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final directory = await getTemporaryDirectory();
      final imageFile = File(
        '${directory.path}/activefriends-${widget.club.id}.png',
      );
      await imageFile.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imageFile.path)],
          text: '${widget.club.name} leaderboard - week to date',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share leaderboard')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _WeeklyShareCard(
                        club: widget.club,
                        entries: widget.entries,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: Icon(Platform.isIOS ? Icons.ios_share : Icons.share),
                  label: Text(_isSharing ? 'Preparing card' : 'Share'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyShareCard extends StatelessWidget {
  const _WeeklyShareCard({required this.club, required this.entries});

  final ClubSummary club;
  final List<LeaderboardEntry> entries;

  static String _weekLabel() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final start = '${months[monday.month - 1]} ${monday.day}';
    final end = monday.month == sunday.month
        ? '${sunday.day}'
        : '${months[sunday.month - 1]} ${sunday.day}';
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    final top3 = entries.take(3).toList();
    final below = entries.skip(3).take(12).toList();

    return Container(
      width: 360,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF35A493), Color(0xFF2A8278)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OUTPACE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _weekLabel(),
                style: const TextStyle(
                  color: Color(0xFFE3F1EE),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            club.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'WEEKLY LEADERBOARD',
            style: TextStyle(
              color: Color(0xFFE3F1EE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          if (top3.length >= 2) ...[
            _ShareCardPodium(entries: top3),
            const SizedBox(height: 14),
          ] else ...[
            for (final e in entries.take(3).indexed)
              _ShareCardRow(rank: e.$1 + 1, entry: e.$2),
          ],
          for (final e in below.indexed)
            _ShareCardRow(rank: e.$1 + 4, entry: e.$2),
          const SizedBox(height: 16),
          const Text(
            'Keep moving together.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCardPodium extends StatelessWidget {
  const _ShareCardPodium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final order = entries.length == 2
        ? [entries[1], entries[0]]
        : [entries[1], entries[0], entries[2]];
    final ranks = entries.length == 2 ? [2, 1] : [2, 1, 3];
    return SizedBox(
      height: 196,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < order.length; i++)
            Expanded(
              child: _ShareCardPodiumColumn(
                entry: order[i],
                rank: ranks[i],
                barHeight: ranks[i] == 1 ? 108 : ranks[i] == 2 ? 86 : 70,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareCardPodiumColumn extends StatelessWidget {
  const _ShareCardPodiumColumn({
    required this.entry,
    required this.rank,
    required this.barHeight,
  });

  final LeaderboardEntry entry;
  final int rank;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final isWinner = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ProfileAvatar(
            displayName: entry.displayName,
            avatarUrl: entry.avatarUrl,
            radius: isWinner ? 24 : 19,
            backgroundColor: const Color(0x33FFFFFF),
          ),
          const SizedBox(height: 5),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: barHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: rank == 1
                    ? const [Color(0xFFEDD880), Color(0xFF9A7010)]
                    : rank == 2
                    ? const [Color(0xFFD8D8D8), Color(0xFF686868)]
                    : const [Color(0xFFD4924A), Color(0xFF7A3E10)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              border: Border.all(
                color: rank == 1
                    ? const Color(0xFFE2B93B)
                    : rank == 2
                    ? const Color(0xFFC0C0C0)
                    : const Color(0xFFB07640),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.points.toStringAsFixed(0)} points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCardRow extends StatelessWidget {
  const _ShareCardRow({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final isLeader = rank == 1;
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLeader ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                color: isLeader ? const Color(0xFFE2B93B) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          ProfileAvatar(
            displayName: entry.displayName,
            avatarUrl: entry.avatarUrl,
            radius: 12,
            backgroundColor: const Color(0x33FFFFFF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${entry.points.toStringAsFixed(0)} points',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
