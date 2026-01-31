import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  Color withValues({
    int? r,
    int? g,
    int? b,
    double? alpha,
  }) {
    return Color.fromARGB(
      alpha != null ? (alpha * 255).round().clamp(0, 255) : (a * 255.0).round().clamp(0, 255),
      r ?? (this.r * 255.0).round().clamp(0, 255),
      g ?? (this.g * 255.0).round().clamp(0, 255),
      b ?? (this.b * 255.0).round().clamp(0, 255),
    );
  }
}
