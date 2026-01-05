# POD Orange LCD & Rack Panel – Flutter Implementation Guide

**Author:** Bernardo’s M365 Copilot  
**Date:** 2026-01-05  

This guide documents how to build a **POD Xt Pro–style UI** in Flutter:
- A high-contrast **orange LCD** (near‑black orange background, bright segmented letters)
- **Backlit buttons** (gray text that glows orange when active)
- **Custom vector knobs**
- **Vertical faders**
- A scalable, **distortion‑free rack faceplate** using SVG + constraint-driven layout.

It’s designed so you can follow later on any machine.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Folder Structure](#folder-structure)
3. [pubspec.yaml](#pubspecyaml)
4. [Theme (Material 3)](#theme-material-3)
5. [LCD Widget (`PodOrangeLCD`)](#lcd-widget-podorangeld)
6. [Backlit Buttons (`BacklitTextButton`)](#backlit-buttons-backlittextbutton)
7. [Knobs (`ProKnob`)](#knobs-proknob)
8. [Faders (`FadersBlock`)](#faders-fadersblock)
9. [Scalable Panel Scaffold (`RackPanelScaffold`)](#scalable-panel-scaffold-rackpanelscaffold)
10. [Demo Page](#demo-page)
11. [Design Notes (Readability in the Dark)](#design-notes-readability-in-the-dark)
12. [Citations / References](#citations--references)

---

## Prerequisites
- Flutter 3.7+ (Material 3 theming & fragment shader support)
- Basic familiarity with `pubspec.yaml`, assets, and `CustomPaint`.

> **Why vector/SVG & segmented fonts?**
> - **SVG rendering** in Flutter (`flutter_svg`) keeps assets **crisp** at any DPI and avoids raster distortion.  
> - **Segmented LCD fonts** (DSEG) emulate true 7/14‑segment displays and are **free** under SIL OFL, ideal for an orange LCD readout.  
> Sources: [flutter_svg on pub.dev](https://pub.dev/packages/flutter_svg), [DSEG fonts](https://www.keshikan.net/fonts-e.html), [DSEG GitHub](https://github.com/keshikan/DSEG).

---

## Folder Structure
```
lib/
  main.dart
  theme.dart
  widgets/
    lcd_orange.dart
    backlit_button.dart
    pro_knob.dart
    faders_block.dart
    panel_scaffold.dart
assets/
  faceplate.svg
  fonts/
    DSEG7Classic-Regular.ttf
    DSEG14Classic-Regular.ttf
```

---

## pubspec.yaml
Add dependencies and register font assets.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.2.3         # crisp SVG rendering (vector-first)
  flex_color_scheme: ^8.4.0   # cohesive Material 3 theming
  flutter_animate: ^4.5.2     # micro-animations (optional)
  flutter_shaders: ^0.1.3     # GPU fragment shader utilities (optional glows)
  syncfusion_flutter_gauges: ^32.1.21  # vertical faders (Community/Commercial license)

flutter:
  assets:
    - assets/faceplate.svg
    - assets/fonts/DSEG7Classic-Regular.ttf
    - assets/fonts/DSEG14Classic-Regular.ttf
```

> **Notes:**
> - `flutter_svg` v2+ uses the vector_graphics backend for performance. See its docs for advanced color mapping.  
> - Syncfusion’s gauges may require a community or commercial license; see their license notes.
> Sources: [flutter_svg](https://pub.dev/packages/flutter_svg), [vector_graphics overview](https://github.com/dnfield/flutter_svg/blob/master/vector_graphics.md), [Syncfusion Gauges on pub.dev](https://pub.dev/packages/syncfusion_flutter_gauges).

---

## Theme (Material 3)
Create a dark theme tuned to orange accents.

```dart
// lib/theme.dart
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const primary = Color(0xFFFF7A00);
  const surface = Color(0xFF0F0F12);

  return FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: primary,
      secondary: Color(0xFFFF9A3E),
      tertiary: Color(0xFFCC5E00),
      surface: surface,
      background: surface,
    ),
    useMaterial3: true,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 8,
      bottomSheetRadius: 12,
      filledButtonRadius: 8,
    ),
  );
}
```

Usage in `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets/panel_scaffold.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Scaffold(
        backgroundColor: Color(0xFF0F0F12),
        body: Center(child: RackPanelScaffold()),
      ),
    );
  }
}
```

> FlexColorScheme provides Material 3–ready theming with consistent color application and easy radius/config tuning. Source: [FlexColorScheme](https://pub.dev/packages/flex_color_scheme).

---

## LCD Widget (`PodOrangeLCD`)
Near‑black orange background with bright orange segmented text for **dark‑room readability**.

```dart
// lib/widgets/lcd_orange.dart
import 'package:flutter/material.dart';

/// POD-style LCD block: near-black orange background + bright orange segmented text.
class PodOrangeLCD extends StatelessWidget {
  final String line1;          // main title
  final String? line2;         // optional subtitle
  final EdgeInsets padding;
  final double line1Size;      // font size for line1
  final double line2Size;      // font size for line2
  final bool dotted14Segment;  // true: DSEG14 (letters), false: DSEG7

  const PodOrangeLCD({
    super.key,
    required this.line1,
    this.line2,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.line1Size = 48,
    this.line2Size = 18,
    this.dotted14Segment = true,
  });

  @override
  Widget build(BuildContext context) {
    // Colors tuned for "near black orange" LCD + bright orange text
    const lcdBgTop    = Color(0xFF140900);  // darker top
    const lcdBgBottom = Color(0xFF0B0500);  // almost black orange bottom
    const lcdBorder   = Color(0xFF2B1200);  // subtle edge
    const textBright  = Color(0xFFFF7A00);  // main lit text
    const textDim     = Color(0xFFCC5E00);  // secondary line dimmer
    const glowSoft    = Color(0x33FF8C2A);  // outer bloom
    const innerGlow   = Color(0x22FF9A3E);  // inner glow from top

    final familyMain  = dotted14Segment ? 'DSEG14Classic' : 'DSEG7Classic';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lcdBorder, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 8, spreadRadius: 1),
          BoxShadow(color: glowSoft, blurRadius: 22, spreadRadius: 4),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [lcdBgTop, lcdBgBottom],
        ),
      ),
      padding: padding,
      child: Stack(
        children: [
          // thin inner glow on the top half for that "lit LCD" feeling
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.center,
                    colors: [innerGlow, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segText(
                line1,
                fontFamily: familyMain,
                size: line1Size,
                color: textBright,
                letterSpacing: 2.0,
              ),
              if (line2 != null) ...[
                const SizedBox(height: 5),
                _segText(
                  line2!,
                  fontFamily: familyMain,
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

  Widget _segText(
    String text, {
    required String fontFamily,
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
        fontFamily: fontFamily,
        fontSize: size,
        height: 1.0,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }
}
```

Usage:
```dart
PodOrangeLCD(
  line1: 'CR1M1NAL',
  line2: '- 2002 PEAVEY 5150 -',
  dotted14Segment: true,
)
```

> DSEG is built to emulate 7/14-segment LCDs and licensed under SIL OFL 1.1. Sources: [Keshikan DSEG page](https://www.keshikan.net/fonts-e.html), [DSEG GitHub](https://github.com/keshikan/DSEG).

---

## Backlit Buttons (`BacklitTextButton`)
Gray text with orange glow when active; minimal hardware feel.

```dart
// lib/widgets/backlit_button.dart
import 'package:flutter/material.dart';

class BacklitTextButton extends StatelessWidget {
  final String label;
  final bool active;
  const BacklitTextButton({super.key, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final onColor  = const Color(0xFFFF7A00);
    final offColor = const Color(0xFFB3B3B3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x66FF8C2A), blurRadius: 12, spreadRadius: 1)]
            : const [BoxShadow(color: Colors.black87, blurRadius: 6, spreadRadius: 1)],
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          colors: active
              ? [onColor.withOpacity(0.9), onColor.withOpacity(0.6)]
              : [offColor, offColor],
        ).createShader(rect),
        blendMode: BlendMode.srcIn,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: active ? onColor : offColor,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}
```

> For more animation polish (press/hover), chain effects with `flutter_animate` (fade/scale/shimmer). Source: [flutter_animate](https://pub.dev/packages/flutter_animate).

---

## Knobs (`ProKnob`)
CustomPaint knob with orange indicator and subtle specular highlight.

```dart
// lib/widgets/pro_knob.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ProKnob extends StatefulWidget {
  final String label;
  const ProKnob({super.key, required this.label});

  @override State<ProKnob> createState() => _ProKnobState();
}

class _ProKnobState extends State<ProKnob> {
  double value = 0.5; // 0..1

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanUpdate: (d) => setState(() => value = (value - d.delta.dy * 0.002).clamp(0.0, 1.0)),
            child: CustomPaint(painter: _KnobPainter(value: value)),
          ),
        ),
        const SizedBox(height: 6),
        Text(widget.label.toUpperCase(),
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14, letterSpacing: 1.1)),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  _KnobPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Body
    final base = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF161616), Color(0xFF0B0B0B)],
        stops: [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, base);

    // Rim bevel
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(c, r * 0.82, rim);

    // Indicator
    const startDeg = -140.0, endDeg = 140.0;
    final ang = (startDeg + (endDeg - startDeg) * value) * pi / 180;
    final p2 = Offset(c.dx + r * 0.7 * cos(ang), c.dy + r * 0.7 * sin(ang));
    final indicator = Paint()
      ..color = const Color(0xFFFF7A00)
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, p2, indicator);

    // Specular highlight
    final hi = Paint()..color = const Color(0x22FFFFFF);
    canvas.drawCircle(c.translate(-r * 0.25, -r * 0.25), r * 0.35, hi);
  }

  @override bool shouldRepaint(_KnobPainter old) => old.value != value;
}
```

---

## Faders (`FadersBlock`)
Vertical faders via **Syncfusion LinearGauge** (drag + animation).

```dart
// lib/widgets/faders_block.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class FadersBlock extends StatelessWidget {
  const FadersBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _Fader(label: 'LOW'),
        _Fader(label: 'BAND'),
        _Fader(label: 'HI-MID'),
        _Fader(label: 'HIGH'),
      ],
    );
  }
}

class _Fader extends StatelessWidget {
  final String label;
  const _Fader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 40, height: 180,
          child: SfLinearGauge(
            orientation: LinearGaugeOrientation.vertical,
            minimum: 0, maximum: 100,
            axisTrackStyle: const LinearAxisTrackStyle(
              thickness: 6, color: Color(0xFF2A2A2A), edgeStyle: LinearEdgeStyle.bothFlat,
            ),
            markerPointers: const [
              LinearShapePointer(
                value: 60,
                shapeType: LinearShapePointerType.diamond,
                color: Color(0xFFFF7A00),
                elevation: 2,
                height: 18,
              ),
            ],
            ranges: const [
              LinearGaugeRange(startValue: 0, endValue: 100, color: Color(0x22000000)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, letterSpacing: 1.0)),
      ],
    );
  }
}
```

> Syncfusion’s Gauges support vertical orientation, custom pointers, ranges, and interactive dragging. Source: [Syncfusion Gauges](https://pub.dev/packages/syncfusion_flutter_gauges), [Getting started guide](https://help.syncfusion.com/flutter/radial-gauge/getting-started).

---

## Scalable Panel Scaffold (`RackPanelScaffold`)
SVG faceplate, proportional layout via `AspectRatio` + `FittedBox`.

```dart
// lib/widgets/panel_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'lcd_orange.dart';
import 'backlit_button.dart';
import 'pro_knob.dart';
import 'faders_block.dart';

class RackPanelScaffold extends StatelessWidget {
  const RackPanelScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 6, // rack-like wide ratio
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1600, height: 600,
          child: Stack(
            children: [
              // Faceplate SVG
              Positioned.fill(
                child: SvgPicture.asset('assets/faceplate.svg', fit: BoxFit.cover),
              ),

              // Top center LCD
              Positioned(
                left: 180, right: 180, top: 40, height: 90,
                child: const PodOrangeLCD(
                  line1: 'CR1M1NAL',
                  line2: '- 2002 PEAVEY 5150 -',
                ),
              ),

              // Left top buttons
              const Positioned(
                left: 40, top: 40, width: 120, height: 90,
                child: BacklitTextButton(label: 'GATE', active: true),
              ),
              const Positioned(
                left: 40, top: 140, width: 120, height: 60,
                child: BacklitTextButton(label: 'AMP', active: true),
              ),

              // Right top selects
              const Positioned(
                right: 40, top: 40, width: 140, height: 60,
                child: BacklitTextButton(label: '4×12 V30', active: false),
              ),
              const Positioned(
                right: 40, top: 110, width: 140, height: 60,
                child: BacklitTextButton(label: '57 OFF AXIS', active: true),
              ),

              // Knob row
              for (final entry in _knobLayout.entries)
                Positioned(
                  left: entry.value.dx, top: 220, width: 120, height: 120,
                  child: ProKnob(label: entry.key),
                ),

              // Middle left buttons
              const Positioned(
                left: 40, top: 370, width: 240, height: 60,
                child: BacklitTextButton(label: 'STOMP', active: false),
              ),
              const Positioned(
                left: 40, top: 440, width: 240, height: 60,
                child: BacklitTextButton(label: 'EQ', active: true),
              ),
              const Positioned(
                left: 40, top: 510, width: 240, height: 60,
                child: BacklitTextButton(label: 'COMP', active: false),
              ),

              // Middle faders block
              const Positioned(
                left: 700, top: 370, width: 200, height: 200,
                child: FadersBlock(),
              ),

              // Middle right buttons
              const Positioned(
                right: 40, top: 370, width: 240, height: 60,
                child: BacklitTextButton(label: 'MOD', active: false),
              ),
              const Positioned(
                right: 40, top: 440, width: 240, height: 60,
                child: BacklitTextButton(label: 'DELAY', active: true),
              ),
              const Positioned(
                right: 40, top: 510, width: 240, height: 60,
                child: BacklitTextButton(label: 'REVERB', active: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _knobLayout = {
  'GAIN': Offset(240, 0),
  'BASS': Offset(380, 0),
  'MIDS': Offset(520, 0),
  'TREBLE': Offset(660, 0),
  'PRESENCE': Offset(800, 0),
  'VOLUME': Offset(940, 0),
  'REVERB': Offset(1080, 0),
};
```

> Use `AspectRatio` + `FittedBox` with a fixed design space (e.g., 1600×600). All child positions stay proportional, preventing distortion.

---

## Demo Page
A quick page to preview the LCD and panel.

```dart
// lib/main.dart (alt minimal demo)
import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets/panel_scaffold.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Scaffold(
        backgroundColor: Color(0xFF0F0F12),
        body: Center(child: RackPanelScaffold()),
      ),
    );
  }
}
```

---

## Design Notes (Readability in the Dark)
- **Contrast:** Bright text `#FF7A00` on near‑black `#0B0500` achieves strong contrast without eye strain. If too harsh, lower text to `#FF6A00` or raise bg to `#130800`.
- **Letter spacing:** Segmented fonts read better with +1.5 to +2.0 tracking for uppercase headings.
- **Glow discipline:** Keep inner glow subtle; outer glow alpha ~0.2–0.35 to suggest backlight without wash.
- **Tight leading:** `height: 1.0` preserves the compact LCD grid feel.
- **Vector-first:** SVG + `CustomPaint` avoids pixelation; don’t use PNGs for faceplate lines.

---

## Citations / References
- **SVG rendering:** `flutter_svg` package and its vector_graphics backend – [pub.dev](https://pub.dev/packages/flutter_svg), [design notes](https://github.com/dnfield/flutter_svg/blob/master/vector_graphics.md).
- **Segmented LCD fonts (DSEG):** Official page and GitHub – [keshikan.net](https://www.keshikan.net/fonts-e.html), [GitHub](https://github.com/keshikan/DSEG), [Debian README](https://sources.debian.org/src/fonts-dseg/0.46-1/README.md/).
- **Material 3 theming:** FlexColorScheme – [pub.dev](https://pub.dev/packages/flex_color_scheme).
- **Faders (linear gauges):** Syncfusion – [pub.dev](https://pub.dev/packages/syncfusion_flutter_gauges), [Getting started](https://help.syncfusion.com/flutter/radial-gauge/getting-started).
- **Animations:** flutter_animate – [pub.dev](https://pub.dev/packages/flutter_animate).

---

## Next Steps
1. Copy this repo structure to your machine.
2. Download DSEG TTFs and drop them into `assets/fonts/`.
3. Create your **faceplate.svg** (lines, labels, dividers) in Figma and export.
4. Run `flutter pub get` and launch.
5. Swap labels/positions to match your exact rack map (from your sketch).

If you want a **dot‑matrix** look (like classic LCD modules), substitute a dot font (e.g., Google Fonts **Doto**) with the same palette and spacing.
