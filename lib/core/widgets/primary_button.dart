import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(label),
          )
        : ElevatedButton(
            onPressed: onPressed,
            child: Text(label),
          );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
