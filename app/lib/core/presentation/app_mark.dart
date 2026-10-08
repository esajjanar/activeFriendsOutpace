import 'package:flutter/material.dart';

class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 44, this.showName = false});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: Image.asset(
        'assets/icon-lines-only.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
    if (!showName) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 2),
        Text(
          'OUTPACE',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(fontSize: 9, height: 1, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
