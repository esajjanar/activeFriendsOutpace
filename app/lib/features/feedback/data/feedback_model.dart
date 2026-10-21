enum FeedbackCategory {
  bug,
  feature,
  uiUx,
  general;

  String get dbValue => switch (this) {
    bug => 'bug',
    feature => 'feature',
    uiUx => 'ui_ux',
    general => 'general',
  };

  String get label => switch (this) {
    bug => 'Bug',
    feature => 'Feature',
    uiUx => 'UI / UX',
    general => 'General',
  };

  String get icon => switch (this) {
    bug => '\u{1F41B}',       // 🐛
    feature => '\u{1F4A1}',   // 💡
    uiUx => '\u{1F3A8}',     // 🎨
    general => '\u{1F4AC}',   // 💬
  };

  static FeedbackCategory fromDb(String value) => switch (value) {
    'bug' => bug,
    'feature' => feature,
    'ui_ux' => uiUx,
    'general' => general,
    _ => general,
  };
}

enum FeedbackArea {
  tracking,
  leaderboard,
  shareCard,
  clubs,
  healthImport,
  profile,
  other;

  String get dbValue => switch (this) {
    tracking => 'tracking',
    leaderboard => 'leaderboard',
    shareCard => 'share_card',
    clubs => 'clubs',
    healthImport => 'health_import',
    profile => 'profile',
    other => 'other',
  };

  String get label => switch (this) {
    tracking => 'Tracking',
    leaderboard => 'Leaderboard',
    shareCard => 'Share Card',
    clubs => 'Clubs',
    healthImport => 'Health Import',
    profile => 'Profile',
    other => 'Other',
  };

  static FeedbackArea fromDb(String value) => switch (value) {
    'tracking' => tracking,
    'leaderboard' => leaderboard,
    'share_card' => shareCard,
    'clubs' => clubs,
    'health_import' => healthImport,
    'profile' => profile,
    'other' => other,
    _ => other,
  };
}

enum FeedbackStatus {
  submitted,
  reviewing,
  fixed,
  noted;

  String get dbValue => switch (this) {
    submitted => 'submitted',
    reviewing => 'reviewing',
    fixed => 'fixed',
    noted => 'noted',
  };

  String get label => switch (this) {
    submitted => 'Submitted',
    reviewing => 'Reviewing',
    fixed => 'Fixed',
    noted => 'Noted',
  };

  String get badge => switch (this) {
    submitted => '\u{1F535}',  // 🔵
    reviewing => '\u{1F7E1}',  // 🟡
    fixed => '\u{2705}',      // ✅
    noted => '\u{26AA}',      // ⚪
  };

  static FeedbackStatus fromDb(String value) => switch (value) {
    'submitted' => submitted,
    'reviewing' => reviewing,
    'fixed' => fixed,
    'noted' => noted,
    _ => submitted,
  };
}

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.category,
    required this.screen,
    required this.description,
    required this.status,
    required this.createdAt,
    this.screenshotUrls = const [],
  });

  final String id;
  final FeedbackCategory category;
  final FeedbackArea screen;
  final String description;
  final FeedbackStatus status;
  final DateTime createdAt;
  final List<String> screenshotUrls;

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['screenshot_urls'];
    final urls = rawUrls is List
        ? rawUrls.cast<String>().toList()
        : <String>[];
    return FeedbackItem(
      id: json['id'] as String,
      category: FeedbackCategory.fromDb(json['category'] as String),
      screen: FeedbackArea.fromDb(json['screen'] as String),
      description: json['description'] as String,
      status: FeedbackStatus.fromDb(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      screenshotUrls: urls,
    );
  }
}
