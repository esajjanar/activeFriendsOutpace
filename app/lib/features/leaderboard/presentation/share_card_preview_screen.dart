import 'dart:io';
import 'dart:ui' as ui;

import 'package:activefriends/features/clubs/data/club_repository.dart';
import 'package:activefriends/features/leaderboard/data/leaderboard_repository.dart';
import 'package:activefriends/features/profile/presentation/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Medal colours for podium rings.
const _kGold = Color(0xFFE2B93B);
const _kSilver = Color(0xFFC0C0C0);
const _kBronze = Color(0xFFB07640);

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: Icon(Platform.isIOS ? Icons.ios_share : Icons.share),
                  label: Text(_isSharing ? 'Preparing card' : 'Share'),
                ),
              ),
            ],
          ),
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
    return '$start – $end\n${monday.year}';
  }

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    final shown = total > 15 ? 15 : total;
    final top3 = entries.take(3).toList();
    final below = entries.skip(3).take(12).toList();

    return Container(
      width: 360,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4, 1.0],
          colors: [Color(0xFF1A3A35), Color(0xFF2A8278), Color(0xFF35A493)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
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
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFFE3F1EE),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              total > 15
                  ? '${club.name} - Top $shown/$total'
                  : club.name,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
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

          // ── Podium ──
          const SizedBox(height: 6),
          if (top3.length >= 2) ...[
            _ShareCardPodium(entries: top3),
            const SizedBox(height: 14),
          ] else ...[
            for (final e in entries.take(3).indexed)
              _ShareCardRow(rank: e.$1 + 1, entry: e.$2, rowIndex: e.$1),
          ],

          // ── Rows ──
          for (final e in below.indexed)
            _ShareCardRow(rank: e.$1 + 4, entry: e.$2, rowIndex: e.$1),

          // ── Branded footer ──
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x26FFFFFF)),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/icon-lines-only.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OUTPACE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Keep moving together.',
                        style: TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

// ── Podium ──────────────────────────────────────────────────────────

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
      height: 208,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < order.length; i++)
            Expanded(
              child: _ShareCardPodiumColumn(
                entry: order[i],
                rank: ranks[i],
                barHeight: ranks[i] == 1 ? 100 : ranks[i] == 2 ? 80 : 66,
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

  static Color _medalColor(int rank) =>
      rank == 1 ? _kGold : rank == 2 ? _kSilver : _kBronze;

  @override
  Widget build(BuildContext context) {
    final isWinner = rank == 1;
    final medal = _medalColor(rank);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown for #1
          if (isWinner)
            const Text('\u{1F451}', style: TextStyle(fontSize: 18)),
          if (isWinner)
            const SizedBox(height: 2),
          // Avatar with medal ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: medal.withValues(alpha: 0.45),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(color: medal, width: 3),
            ),
            child: ProfileAvatar(
              displayName: entry.displayName,
              avatarUrl: entry.avatarUrl,
              radius: isWinner ? 24 : 19,
              backgroundColor: const Color(0x33FFFFFF),
            ),
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
          // Bar — no rank number, points are the hero
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
              border: Border.all(color: medal),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.points.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'points',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.distanceM > 0
                      ? '${(entry.distanceM / 1000).toStringAsFixed(2)} km'
                      : '\u2014',
                  style: TextStyle(
                    color: const Color(0xFFFFE082).withValues(alpha: 0.90),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
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

// ── Row ─────────────────────────────────────────────────────────────

class _ShareCardRow extends StatelessWidget {
  const _ShareCardRow({
    required this.rank,
    required this.entry,
    required this.rowIndex,
  });

  final int rank;
  final LeaderboardEntry entry;
  final int rowIndex;

  static const _shameLines = [
    'Still on the couch \u{1F6CB}\u{FE0F}',
    'Sleeping in \u{1F634}',
    'Netflix marathon? \u{1F3AC}',
    'MIA this week \u{1F440}',
    'Ghosting the group \u{1F47B}',
    'Forgot their shoes \u{1F45F}',
    'Lost in the snack aisle \u{1F355}',
    'Charging their watch \u{231A}',
    'Waiting for motivation \u{1F40C}',
    'Hiding from the leaderboard \u{1FAE3}',
    'Training their thumbs instead \u{1F4F1}',
    'Stuck in traffic \u{1F697}',
    'Blaming the weather \u{2601}\u{FE0F}',
    'Stretching... since Monday \u{1F9D8}',
    'Perfecting their excuse \u{1F4DD}',
    'In a food coma \u{1F354}',
    'Snoozed the alarm 5 times \u{23F0}',
    'Joined the wrong club? \u{1F914}',
    'Still lacing up \u{1F45F}',
    'Warming up the bench \u{1FA91}',
    'Checking the weather app... again \u{1F327}\u{FE0F}',
    'Resting for next week \u{1F607}',
    'Plotting a comeback \u{1F9B8}',
    'Buffering... \u{1F504}',
    'On airplane mode \u{2708}\u{FE0F}',
    'Napping like a pro \u{1F4A4}',
    'Vibing, not moving \u{1F3A7}',
    'Leg day was yesterday \u{1F9B5}',
    'Ordered Uber instead \u{1F695}',
    'Zero steps, zero regrets \u{1F937}',
  ];

  @override
  Widget build(BuildContext context) {
    final isActive = entry.points > 0;
    // Alternate shading for active rows; dim for inactive.
    final bgColor = isActive
        ? (rowIndex.isEven
            ? const Color(0x26FFFFFF)
            : const Color(0x15FFFFFF))
        : const Color(0x0DFFFFFF);
    final opacity = isActive ? 1.0 : 0.50;

    return Opacity(
      opacity: opacity,
      child: Container(
        height: 42,
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    isActive
                        ? '${(entry.distanceM / 1000).toStringAsFixed(2)} km'
                        : _shameLines[rank % _shameLines.length],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.points.toStringAsFixed(0)} points',
              style: TextStyle(
                color: entry.points == 0
                    ? const Color(0xFFFF4444)
                    : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
