import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.radius,
    required this.backgroundColor,
  });

  final String displayName;
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isEmpty
        ? '?'
        : displayName.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
          ? null
          : NetworkImage(avatarUrl!),
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * .75,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
