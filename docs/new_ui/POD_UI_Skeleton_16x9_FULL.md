# POD Xt Pro — Painel Estético Consolidado (16:9)

Foco **somente na estética** e **estrutura**. Sem lógica funcional.

- **Proporção:** 16:9
- **Linhas (altura relativa):** `2 / 2 / 4 / 1` → ~`22.22% / 22.22% / 44.44% / 11.11%`
- **Cantinhos:** **6px** (todos os boxes)
- **LCD:** DOT‑MATRIX (fonte **Doto**). Pode mostrar: 
  1) **Nome de fábrica**; 
  2) **Real amp menor em cima + nome de fábrica grande**; 
  3) **Somente real amp**.

---

## 1) Figma — guia rápido (faceplate 16:9)
**Frame base:** `1600 × 900` (16:9). 

Para cada linha, use **16 colunas** e aplique as divisões abaixo:

### Linha 1 — `3 / 10 / 3` (altura ~22.22%)
- **Coluna 1 (3):** dois botões empilhados (**GATE** / **AMP**). 
- **Coluna 2 (10):** **LCD DOT‑MATRIX/Selector** (duas linhas quando houver real amp). 
- **Coluna 3 (3):** dois botões empilhados (**CAB** / **MIC**).

### Linha 2 — `1 / 14 / 1` (altura ~22.22%)
- **Centro (14):** **7 knobs** (cada ocupa **2 colunas**), com **espaço de 1** coluna antes e depois: 
  **GAIN · BASS · MID · TREBLE · PRESENCE · VOLUME · REVERB**.

### Linha 3 — `4 / 8 / 4` (altura ~44.44%)
- **Esquerda (4):** **STOMP**, **EQ**, **COMP** (empilhados). Cada botão com **indicador abaixo** do rótulo mostrando o **modelo ativo**.
- **Centro (8):** **Box de EQ** com **4 knobs** de **frequência** (valores em Hz) e abaixo **4 faders** de **ganho (dB)**. Rótulos: **LOW · LOW MID · HI MID · HIGH**.
- **Direita (4):** **MOD**, **DELAY**, **REVERB** (empilhados), também com **indicador abaixo** do modelo ativo.

### Linha 4 — `1 / 1 / 1 / 10 / 2 / 1` (altura ~11.11%)
- **Configurações** (ícone engrenagem, sem texto) · **Wah on/off** · **FX Loop on/off** · **Barra de presets** (seleção/indicação) · **Tap Tempo** · **Status MIDI**.

**Export:** faceplate em **SVG (Contents only)**. Evite blur/efeitos complexos; mantenha cantos 6px. 

---

## 2) Flutter — esqueleto 16:9 com todos os rótulos
> O layout abaixo usa `AspectRatio(16/9)` + `FittedBox` com espaço de design fixo `1600×900`. É **apenas visual**, com placeholders.

```dart
// lib/widgets/pod_panel_16x9.dart
import 'package:flutter/material.dart';

class PodPanel16x9 extends StatelessWidget {
  const PodPanel16x9({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1600, height: 900,
          child: Column(
            children: const [
              _Row1(),  // 3 / 10 / 3
              _Row2(),  // 1 / 14 / 1 (7 knobs × 2 cols; espaços nas pontas)
              _Row3(),  // 4 / 8 / 4 (botões / EQ 4 bandas / botões)
              _Row4(),  // 1 / 1 / 1 / 10 / 2 / 1 (config, wah, fx loop, presets, tap, midi)
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Paleta & estilos ----------
class _Ui {
  static const bg = Color(0xFF0F0F12);
  static const box = Color(0xFF121212);
  static const border = Color(0xFF2A2A2A);
  static const label = Color(0xFFB3B3B3);
  static const lcdTop = Color(0xFF140900);
  static const lcdBot = Color(0xFF0B0500);
  static const lcdBorder = Color(0xFF2B1200);
  static const lcdText = Color(0xFFFF7A00);
  static const lcdTextDim = Color(0xFFCC5E00);
}

BoxDecoration _box6({Color? color}) => BoxDecoration(
  color: color ?? _Ui.box,
  borderRadius: BorderRadius.circular(6),
  border: Border.all(color: _Ui.border),
);

// ---------- Linha 1: 3 / 10 / 3 ----------
class _Row1 extends StatelessWidget {
  const _Row1();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 900 * (2 / 9),
      child: Row(
        children: const [
          _LeftStack(),
          _LCDSelector(),
          _RightStack(),
        ],
      ),
    );
  }
}

class _LeftStack extends StatelessWidget {
  const _LeftStack();
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _ButtonBox(label: 'GATE'),
            _ButtonBox(label: 'AMP'),
          ],
        ),
      ),
    );
  }
}

class _RightStack extends StatelessWidget {
  const _RightStack();
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _ButtonBox(label: 'CAB'),
            _ButtonBox(label: 'MIC'),
          ],
        ),
      ),
    );
  }
}

class _ButtonBox extends StatelessWidget {
  final String label; const _ButtonBox({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: _box6(),
      child: Center(
        child: Text(label, style: const TextStyle(color: _Ui.label, letterSpacing: 1.3)),
      ),
    );
  }
}

class _LCDSelector extends StatelessWidget {
  const _LCDSelector();
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 10,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _Ui.lcdBorder, width: 1.4),
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_Ui.lcdTop, _Ui.lcdBot],
          ),
        ),
        child: const _LCDContent(),
      ),
    );
  }
}

class _LCDContent extends StatelessWidget {
  const _LCDContent();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          // Linha menor (real amp, se desejado)
          Text('PEAVEY 5150',
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontFamily: 'Doto', fontSize: 20, height: 1.0,
              letterSpacing: 1.2, color: _Ui.lcdTextDim,
            ),
          ),
          SizedBox(height: 4),
          // Linha principal (nome de fábrica)
          Text('CR1M1NAL',
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontFamily: 'Doto', fontSize: 50, height: 1.0,
              letterSpacing: 2.0, color: _Ui.lcdText,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Linha 2: 1 / 14 / 1 (7 knobs) ----------
class _Row2 extends StatelessWidget {
  const _Row2();
  static const _labels = ['GAIN','BASS','MID','TREBLE','PRESENCE','VOLUME','REVERB'];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 900 * (2 / 9),
      child: Row(
        children: [
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 14,
            child: Row(
              children: [
                for (final label in _labels) Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Column(
                      children: [
                        Container(
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(color: _Ui.border),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(label, style: const TextStyle(color: _Ui.label, fontSize: 13, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}

// ---------- Linha 3: 4 / 8 / 4 ----------
class _Row3 extends StatelessWidget {
  const _Row3();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 900 * (4 / 9),
      child: Row(
        children: const [
          _EffectsColumn(labels: ['STOMP','EQ','COMP']),
          _EqBox(),
          _EffectsColumn(labels: ['MOD','DELAY','REVERB']),
        ],
      ),
    );
  }
}

class _EffectsColumn extends StatelessWidget {
  final List<String> labels; const _EffectsColumn({required this.labels});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final label in labels) Column(
              children: [
                Container(
                  height: 64,
                  decoration: _box6(),
                  child: Center(
                    child: Text(label, style: const TextStyle(color: _Ui.label, letterSpacing: 1.3)),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 24,
                  decoration: _box6(color: const Color(0xFF1A1A1A)),
                  child: const Center(
                    child: Text('MODEL ACTIVE', style: TextStyle(color: _Ui.label, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EqBox extends StatelessWidget {
  const _EqBox();
  static const _bands = ['LOW','LOW MID','HI MID','HIGH'];
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 8,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: _box6(),
        child: Column(
          children: [
            // Knobs de frequência (Hz)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) => Column(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: _Ui.border),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('FREQ', style: TextStyle(color: _Ui.label, fontSize: 12)),
                ],
              )),
            ),
            const SizedBox(height: 16),
            // Faders de ganho (dB) com rótulos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) => Column(
                children: [
                  Container(
                    width: 36, height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _Ui.border),
                    ),
                    child: const Center(
                      child: Text('dB', style: TextStyle(color: _Ui.label, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_bands[i], style: const TextStyle(color: _Ui.label, fontSize: 12)),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Linha 4: 1 / 1 / 1 / 10 / 2 / 1 ----------
class _Row4 extends StatelessWidget {
  const _Row4();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 900 * (1 / 9),
      child: Row(
        children: const [
          _GearButton(),      // 1
          _Toggle(label: 'WAH'), // 1
          _Toggle(label: 'FX LOOP'), // 1
          _PresetBar(),       // 10
          _ButtonBox(label: 'TAP'), // 2
          _MidiStatus(),      // 1
        ],
      ),
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton();
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: _box6(),
        child: const Center(
          child: Icon(Icons.settings, color: _Ui.label, size: 22),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label; const _Toggle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: _box6(),
        child: Center(
          child: Text(label, style: const TextStyle(color: _Ui.label, letterSpacing: 1.2)),
        ),
      ),
    );
  }
}

class _PresetBar extends StatelessWidget {
  const _PresetBar();
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 10,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: _box6(),
        child: const Center(
          child: Text('PRESET SELECTION / ACTIVE', style: TextStyle(color: _Ui.label)),
        ),
      ),
    );
  }
}

class _MidiStatus extends StatelessWidget {
  const _MidiStatus();
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: _box6(),
        child: const Center(
          child: Text('MIDI', style: TextStyle(color: _Ui.label)),
        ),
      ),
    );
  }
}
```

**Bootstrap mínimo:**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'widgets/pod_panel_16x9.dart';

void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: Color(0xFF0F0F12), body: Center(child: PodPanel16x9())),
    );
  }
}
```

> **LCD DOT‑MATRIX:** use a família **Doto** (Google Fonts, OFL) para o pontilhado; registre em `assets/fonts/` e aplique `fontFamily: 'Doto'` nos textos do LCD.

---

## 3) Rótulos confirmados (do desenho)
- **Linha 1 (3/10/3):** 
  - Esquerda: **GATE** / **AMP** empilhados.
  - Centro: **Amp Model LCD/Selector** — duas linhas quando houver real amp (menor em cima, ambas em DOT‑MATRIX).
  - Direita: **CAB** / **MIC** empilhados.
- **Linha 2 (1 / 14 / 1):** 
  **GAIN · BASS · MID · TREBLE · PRESENCE · VOLUME · REVERB** (com espaços de 1 nas pontas).
- **Linha 3 (4 / 8 / 4):** 
  - Esquerda: **STOMP**, **EQ**, **COMP** (indicador de **modelo ativo** abaixo). 
  - Centro: **EQ 4 bandas** → **4 knobs de frequência (Hz)** + **4 faders (dB)**, rótulos: **LOW · LOW MID · HI MID · HIGH**. 
  - Direita: **MOD**, **DELAY**, **REVERB** (também com **indicador de modelo** abaixo).
- **Linha 4 (1 / 1 / 1 / 10 / 2 / 1):** 
  **Config (engrenagem)** · **Wah on/off** · **FX Loop on/off** · **Barra de presets** · **Tap Tempo** · **Status MIDI**.

---

## 4) Notas finais
- Toda a estrutura usa **cantos 6px** e bordas discretas para aquela estética de rack.
- Em Figma, mantenha os **guides** por linha/coluna e exporte como **SVG (Contents only)** para integrar no Flutter via `flutter_svg` (vetorial, sem distorção).

