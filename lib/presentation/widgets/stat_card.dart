import 'dart:ui';

import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.delta,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final double delta;
  final VoidCallback? onTap;

  bool get _isPositive => delta >= 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deltaColor = _isPositive ? Colors.greenAccent : Colors.redAccent;
    final icon = _isPositive ? Icons.trending_up : Icons.trending_down;
    final deltaText =
        '${_isPositive ? '+' : ''}${(delta * 100).toStringAsFixed(0)}%';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(icon, color: deltaColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      deltaText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
