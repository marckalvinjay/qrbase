import 'package:flutter/material.dart';

const LinearGradient appBackgroundGradient = LinearGradient(
  colors: [
    Color(0xFF0E1426),
    Color(0xFF0B1D1E),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient primaryButtonGradient = LinearGradient(
  colors: [
    Color(0xFF4AD9C6),
    Color(0xFF2A8CFF),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const Color lightBackgroundColor = Color(0xFFFB9EB7);

BoxDecoration appBackgroundDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return const BoxDecoration(gradient: appBackgroundGradient);
  }
  return const BoxDecoration(color: lightBackgroundColor);
}
