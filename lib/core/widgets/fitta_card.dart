import 'package:flutter/material.dart';
import 'package:fitta/core/theme/app_theme.dart';

class FittaCard extends StatelessWidget {
  const FittaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
