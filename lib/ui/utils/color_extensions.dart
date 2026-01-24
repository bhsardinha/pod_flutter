import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  Color withValues({
    int? r,
    int? g,
    int? b,
    double? alpha,
  }) {
    return Color.fromARGB(
      alpha != null ? (alpha * 255).round().clamp(0, 255) : this.alpha,
      r ?? red,
      g ?? green,
      b ?? blue,
    );
  }
}
