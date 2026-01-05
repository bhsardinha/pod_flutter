# POD Xt Pro – DOT‑MATRIX LCD & Faceplate (Figma → Flutter)

**Autor:** Bernardo (assistido por M365 Copilot)  
**Data:** 2026‑01‑05

Este guia te leva de **Figma** (faceplate em SVG, sem distorção) até **Flutter** (LCD **DOT‑MATRIX** de alto contraste, botões retroiluminados, knobs e faders), tudo pensado para a estética do **Line 6 POD Xt Pro** em ambiente escuro.

---

## Sumário
1. Visão geral & por que DOT‑MATRIX  
2. Preparando o projeto (Flutter + fontes)  
3. LCD **DOT‑MATRIX** em Flutter (`DotMatrixLCD`)  
4. Guia de Faceplate no **Figma** (grid, sections, export SVG)  
5. Scaffold escalável com `flutter_svg`  
6. Dicas de legibilidade e fidelidade  
7. Referências

---

## 1) Visão geral & por que DOT‑MATRIX
- **DOT‑MATRIX** (pontilhado) aproxima a aparência de módulos LCD de rack com legibilidade excelente no escuro. A família **Doto** (Google Fonts) é uma fonte **open‑source**, **monoespaçada** e **variável**, construída sobre uma matriz 6×10 e com eixos que controlam **tamanho** e **arredondamento** dos pontos; ideal para displays estilo LCD. citeturn9search82turn9search83
- No app, o **faceplate** deve ser **vetorial** (SVG) para ficar **nítido** em qualquer DPI. Em Flutter, usamos **`flutter_svg`** que migrou para um backend **vector_graphics** com melhor desempenho e compatibilidade. citeturn9search91turn9search95

---

## 2) Preparando o projeto (Flutter + fontes)
### `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.2.3
  flex_color_scheme: ^8.4.0
  syncfusion_flutter_gauges: ^32.1.21  # faders (licença community/comercial)

flutter:
  assets:
    - assets/faceplate.svg
    - assets/fonts/Doto-Regular.ttf
    # (Opcional) outros pesos/variantes da Doto caso queira
```
- **Doto** está em Google Fonts e sob **OFL**; você pode baixar e hospedar localmente. citeturn9search82turn9search84
- `flutter_svg` documenta API e o backend **vector_graphics**; use assets locais para renderizar vetores com nitidez. citeturn9search90turn9search95

---

## 3) LCD DOT‑MATRIX em Flutter (`DotMatrixLCD`)
Fundo **laranja quase preto** e texto **laranja brilhante** com fonte **Doto**.

```dart
// lib/widgets/dot_matrix_lcd.dart
import 'package:flutter/material.dart';

class DotMatrixLCD extends StatelessWidget {
  final String line1;
  final String? line2;
  final EdgeInsets padding;
  final double line1Size;
  final double line2Size;

  const DotMatrixLCD({
    super.key,
    required this.line1,
    this.line2,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.line1Size = 48,
    this.line2Size = 18,
  });

  @override
  Widget build(BuildContext context) {
    const lcdBgTop    = Color(0xFF140900);
    const lcdBgBottom = Color(0xFF0B0500);
    const lcdBorder   = Color(0xFF2B1200);
    const textBright  = Color(0xFFFF7A00);
    const textDim     = Color(0xFFCC5E00);
    const glowSoft    = Color(0x33FF8C2A);
    const innerGlow   = Color(0x22FF9A3E);

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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dotText(line1, size: line1Size, color: textBright, letterSpacing: 2.0),
              if (line2 != null) ...[
                const SizedBox(height: 5),
                _dotText(line2!, size: line2Size, color: textDim, letterSpacing: 1.2),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dotText(String text, {required double size, required Color color, double letterSpacing = 0}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      overflow: TextOverflow.fade,
      softWrap: false,
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'Doto',  // fonte DOT‑MATRIX
        fontSize: size,
        height: 1.0,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }
}
```

> A **Doto** é uma fonte variável monoespaçada baseada em matriz (6×10), perfeita para simular dot‑matrix de LCD; distribui‑se sob **OFL**. citeturn9search82turn9search83

---

## 4) Faceplate no **Figma** – passo a passo

### 4.1 Criar o frame base e layout guides
1. Abra o Figma e crie um **Frame** com o tamanho de **1600×600** (seu espaço de design fixo).  
2. Adicione **Layout Guides** (antigo Layout Grid) ao frame: defina **colunas** para seções (ex.: 16 colunas, gutter 16, margins 40) e, se precisar, uma **uniform grid** de 8–10 px para alinhar ícones/screws. O Figma permite **múltiplas guides no mesmo frame** e tipos como **Stretch/Center/Left** dependendo da responsividade que você quer simular. citeturn9search74turn9search71
3. Use guides para o **rack bezel**, divisórias horizontais (linhas finas), e áreas de **LCD** e **botões** conforme seu esboço.

### 4.2 Construir elementos vetoriais
- Desenhe **painéis** (retângulos com cantos 8px), **divisórias** (1–2px), e **slots** de botões. Evite efeitos incompatíveis com SVG (blur de fundo, gradientes complexos). **Angular/Diamond gradients** podem ser convertidos erraticamente — prefira **linear/radial** ou **flatten**. citeturn9search79turn9search64
- Use **layer names** claros (ex.: `panel/top`, `divider/row1`, `lcd/bezel`) para gerar `id`/classes no SVG se precisar referenciar no app. Plugins de export podem incluir **classes** e otimizações via **SVGO**. citeturn9search62

### 4.3 Tipografia no faceplate
- Para **labels gravados** do painel (não LCD), use uma fonte legível e **converta para outline** somente se você **precisar aparência garantida** sem depender de fontes no runtime; caso contrário, exporte como **texto** para peso menor. citeturn9search79turn9search88

### 4.4 Exportar SVG corretamente
1. Selecione o **frame** ou **grupo** do faceplate.  
2. No painel **Export**, escolha **SVG**; use **Contents only** para exportar somente o conteúdo (viewBox calculado).  
3. Decida entre **Outline text** (paths garantidos) ou manter **texto** (menor tamanho e editável, mas requer fonte).  
4. Opcional: habilite **id attributes** para mapear unidades no Flutter.  
   Dicas e parâmetros (incluindo via API) estão detalhados na **Documentação de ExportSettings** e em guias de export. citeturn9search78turn9search66turn9search64

> Se você tiver uma biblioteca de ícones, plugins como **SVG Export** ajudam a padronizar código e reduzir peso via **SVGO**. citeturn9search62

---

## 5) Rack panel em Flutter com `flutter_svg`

```dart
// lib/widgets/panel_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dot_matrix_lcd.dart';

class RackPanelScaffold extends StatelessWidget {
  const RackPanelScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 6,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1600, height: 600,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset('assets/faceplate.svg', fit: BoxFit.cover),
              ),
              Positioned(
                left: 180, right: 180, top: 40, height: 90,
                child: const DotMatrixLCD(
                  line1: 'CR1M1NAL',
                  line2: '- 2002 PEAVEY 5150 -',
                ),
              ),
              // ... acrescente botões/knobs/faders como no seu layout
            ],
          ),
        ),
      ),
    );
  }
}
```

> `flutter_svg` fornece `SvgPicture.asset/string` e ferramentas de tema/cores; desde a v2 usa **vector_graphics** para parsing/execução mais eficiente. citeturn9search91turn9search90

---

## 6) Legibilidade & fidelidade (no escuro)
- **Contraste**: texto `#FF7A00` sobre fundo `#0B0500` dá contraste alto; ajuste para `#FF6A00` ou eleve o fundo se necessário.  
- **Espaçamento**: dot‑matrix costuma ganhar com **letterSpacing** +1.5–2.0 em maiúsculas.  
- **Efeitos**: use apenas **gradientes simples** e sombras leves; blur/filtros podem não exportar bem para SVG. citeturn9search79
- **Export**: preferir **Contents only**, decidir **Outline text** de acordo com necessidade; habilitar **id** quando for manipular elementos especificamente no app. citeturn9search78turn9search66

---

## 7) Referências
- **Doto (Google Fonts, OFL, matriz 6×10, eixos de ponto):** [Google Fonts](https://fonts.google.com/specimen/Doto) citeturn9search82 • [GitHub](https://github.com/oliverlalan/Doto) citeturn9search83  
- **SVG em Flutter:** [API `flutter_svg`](https://pub.dev/documentation/flutter_svg/latest/flutter_svg/) citeturn9search90 • [README (vector_graphics backend)](https://github.com/flutter/packages/blob/main/third_party/packages/flutter_svg/README.md) citeturn9search91 • [vector_graphics.md](https://github.com/dnfield/flutter_svg/blob/master/vector_graphics.md) citeturn9search95  
- **Exportar SVG no Figma:** [Help Center – Export](https://help.figma.com/hc/en-us/articles/360040028114-Export-from-Figma-Design) citeturn9search78 • [ExportSettings (API)](https://developers.figma.com/docs/plugins/api/ExportSettings/) citeturn9search66 • [Design+Code – Handbook](https://designcode.io/figma-handbook-export-svg) citeturn9search79  
- **Layout Guides (Grid) no Figma:** [Help Center – Layout guides](https://help.figma.com/hc/en-us/articles/360040450513-Create-layout-guides) citeturn9search74 • [Boas práticas de grids](https://www.figma.com/best-practices/everything-you-need-to-know-about-layout-grids/) citeturn9search71  
- **Otimize export:** [SVG Genie – guia](https://www.svggenie.com/blog/how-to-export-svg-from-figma) citeturn9search64 • [platformOS – otimização](https://documentation.platformos.com/use-cases/optimizing-svg-exported-from-figma) citeturn9search80

---

### Checklist rápido do Figma → Flutter
- [ ] Frame 1600×600 com layout guides (colunas + uniform grid). citeturn9search74  
- [ ] Vetores limpos (sem blur complexo; gradientes simples). citeturn9search79  
- [ ] Nomes de camada consistentes; exportar SVG (Contents only; decidir Outline text; opcional `id`). citeturn9search78turn9search66  
- [ ] Copiar `faceplate.svg` para `assets/` e registrar no `pubspec.yaml`. citeturn9search90  
- [ ] Baixar **Doto** (OFL) e registrar em `assets/fonts/`. citeturn9search82  
- [ ] Usar `DotMatrixLCD` no painel e ajustar `letterSpacing`/tamanhos.

Se quiser, eu crio um **arquivo Figma** inicial com o frame 1600×600, guides, e placeholders de `LCD`, `buttons`, `knobs`, `dividers` — basta me dizer a **quantidade exata** de knobs/faders, rótulos, e margens preferidas.
