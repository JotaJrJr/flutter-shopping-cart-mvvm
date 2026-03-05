import 'package:flutter/material.dart';

class InlineError extends StatelessWidget {
  const InlineError({
    required this.message,
    required this.onClose,
    super.key,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE1DA),
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ),
    );
  }
}
