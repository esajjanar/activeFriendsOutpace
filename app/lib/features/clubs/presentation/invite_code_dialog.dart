import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteCodeDialog extends StatelessWidget {
  const InviteCodeDialog({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite code'),
      content: SelectableText(code, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          tooltip: 'Copy invite code',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied.')));
          },
          icon: const Icon(Icons.copy),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
      ],
    );
  }
}