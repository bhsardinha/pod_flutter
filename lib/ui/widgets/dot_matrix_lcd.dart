import 'package:flutter/material.dart';

/// POD-style dot-matrix LCD display with orange glow aesthetic.
///
/// Features:
/// - Near-black orange background gradient
/// - Bright orange text using Doto dot-matrix font
/// - Inner glow effect for authentic LCD look
/// - Supports 1-2 lines of text OR custom child widget
class DotMatrixLCD extends StatelessWidget {
  /// Main line of text (larger, brighter)
  final String? line1;

  /// Optional second line (smaller, dimmer)
  final String? line2;

  /// Optional custom child widget (overrides line1/line2)
  final Widget? child;

  /// Padding inside the LCD container
  final EdgeInsets padding;

  /// Font size for line1
  final double line1Size;

  /// Font size for line2
  final double line2Size;

  const DotMatrixLCD({
    super.key,
    this.line1,
    this.line2,
    this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.line1Size = 48,
    this.line2Size = 18,
  }) : assert(line1 != null || child != null, 'Either line1 or child must be provided');

  @override
  Widget build(BuildContext context) {
    // Color palette for orange LCD aesthetic
    const lcdBgTop = Color(0xFF140900); // darker top
    const lcdBgBottom = Color(0xFF0B0500); // almost black orange bottom
    const lcdBorder = Color(0xFF2B1200); // subtle edge
    const textBright = Color(0xFFFF7A00); // main lit text
    const textDim = Color(0xFFCC5E00); // secondary line dimmer
    const glowSoft = Color(0x18FF8C2A); // outer bloom (more subtle)
    const innerGlow = Color(0x22FF9A3E); // inner glow from top

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lcdBorder, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 8, spreadRadius: 1),
          BoxShadow(color: glowSoft, blurRadius: 22, spreadRadius: 4),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lcdBgTop, lcdBgBottom],
        ),
      ),
      padding: padding,
      child: Stack(
        children: [
          // Thin inner glow on the top half for "lit LCD" feeling
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [innerGlow, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Content
          child ?? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dotText(
                line1!,
                size: line1Size,
                color: textBright,
                letterSpacing: 2.0,
              ),
              if (line2 != null) ...[
                const SizedBox(height: 5),
                _dotText(
                  line2!,
                  size: line2Size,
                  color: textDim,
                  letterSpacing: 1.2,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dotText(
    String text, {
    required double size,
    required Color color,
    double letterSpacing = 0,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      overflow: TextOverflow.fade,
      softWrap: false,
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'Doto', // dot-matrix font
        fontSize: size,
        height: 1.0,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }
}
