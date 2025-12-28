/// Effect model definitions for POD XT Pro
/// Extracted from pod-ui mod-xt/src/config.rs

library;

/// Effect parameter definition
class EffectParam {
  final String name;
  final int minValue;
  final int maxValue;

  const EffectParam(this.name, {this.minValue = 0, this.maxValue = 127});
}

/// Base effect model
class EffectModel {
  final int id;
  final String name;
  final List<EffectParam> params;
  final String? pack;

  const EffectModel(this.id, this.name, this.params, [this.pack]);

  bool get isStock => pack == null;
}

// ═══════════════════════════════════════════════════════════════════════════
// STOMP EFFECTS
// ═══════════════════════════════════════════════════════════════════════════
class StompModels {
  static const List<EffectModel> all = [
    EffectModel(0, 'Facial Fuzz', [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')]),
    EffectModel(1, 'Fuzz Pi', [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')]),
    EffectModel(2, 'Screamer', [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')]),
    EffectModel(3, 'Classic Dist', [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')]),
    EffectModel(4, 'Octave Fuzz', [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')]),
    EffectModel(5, 'Blue Comp', [EffectParam('Sustain'), EffectParam('Level')]),
    EffectModel(6, 'Red Comp', [EffectParam('Sustain'), EffectParam('Level')]),
    EffectModel(7, 'Vetta Comp', [EffectParam('Sens'), EffectParam('Level')]),
    EffectModel(8, 'Auto Swell', [EffectParam('Ramp'), EffectParam('Depth')]),
    EffectModel(9, 'Auto Wah', [EffectParam('Sens'), EffectParam('Q')]),

    // FX Pack stomps
    EffectModel(10, 'Killer Z', [EffectParam('Drive'), EffectParam('Contour'), EffectParam('Gain'), EffectParam('Mid'), EffectParam('Mid Freq')], 'FX'),
    EffectModel(11, 'Tube Drive', [EffectParam('Drive'), EffectParam('Treble'), EffectParam('Gain'), EffectParam('Bass')], 'FX'),
    EffectModel(12, 'Vetta Juice', [EffectParam('Amount'), EffectParam('Level')], 'FX'),
    EffectModel(13, 'Boost + EQ', [EffectParam('Gain'), EffectParam('Bass'), EffectParam('Treble'), EffectParam('Mid'), EffectParam('Mid Freq')], 'FX'),
    EffectModel(14, 'Blue Comp Treb', [EffectParam('Level'), EffectParam('Sustain')], 'FX'),
    EffectModel(15, 'Dingo-Tron', [EffectParam('Sens'), EffectParam('Q')], 'FX'),
    EffectModel(16, 'Clean Sweep', [EffectParam('Decay'), EffectParam('Sens'), EffectParam('Q')], 'FX'),
    EffectModel(17, 'Seismik Synth', [EffectParam('Wave'), EffectParam('Mix')], 'FX'),
    EffectModel(18, 'Double Bass', [EffectParam('-1 Oct Gain'), EffectParam('-2 Oct Gain'), EffectParam('Mix')], 'FX'),
    EffectModel(19, 'Buzz Wave', [EffectParam('Wave'), EffectParam('Filter'), EffectParam('Decay'), EffectParam('Mix')], 'FX'),
    EffectModel(20, 'Rez Synth', [EffectParam('Wave'), EffectParam('Filter'), EffectParam('Decay'), EffectParam('Mix')], 'FX'),
    EffectModel(21, 'Saturn 5 Ring M', [EffectParam('Wave'), EffectParam('Mix')], 'FX'),
    EffectModel(22, 'Synth Analog', [EffectParam('Wave'), EffectParam('Filter'), EffectParam('Decay'), EffectParam('Mix')], 'FX'),
    EffectModel(23, 'Synth FX', [EffectParam('Wave'), EffectParam('Filter'), EffectParam('Decay'), EffectParam('Mix')], 'FX'),
    EffectModel(24, 'Synth Harmony', [EffectParam('Octave 1'), EffectParam('Octave 2'), EffectParam('Wave'), EffectParam('Mix')], 'FX'),
    EffectModel(25, 'Synth Lead', [EffectParam('Wave'), EffectParam('Filter'), EffectParam('Decay'), EffectParam('Mix')], 'FX'),
    EffectModel(26, 'Synth String', [EffectParam('Wave'), EffectParam('Filter'), EffectParam('Attack'), EffectParam('Mix')], 'FX'),

    // BX Pack stomps
    EffectModel(27, 'Bass Overdrive', [EffectParam('Bass'), EffectParam('Treble'), EffectParam('Drive'), EffectParam('Gain')], 'BX'),
    EffectModel(28, 'Bronze Master', [EffectParam('Drive'), EffectParam('Tone'), EffectParam('Blend')], 'BX'),
    EffectModel(29, 'Sub Octaves', [EffectParam('-1 Oct Gain'), EffectParam('-2 Oct Gain'), EffectParam('Mix')], 'BX'),
    EffectModel(30, 'Bender', [EffectParam('Position'), EffectParam('Heel'), EffectParam('Toe'), EffectParam('Mix')], 'BX'),
  ];

  static EffectModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULATION EFFECTS
// ═══════════════════════════════════════════════════════════════════════════
class ModModels {
  static const List<EffectModel> all = [
    EffectModel(0, 'Sine Chorus', [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')]),
    EffectModel(1, 'Analog Chorus', [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')]),
    EffectModel(2, 'Line 6 Flanger', [EffectParam('Depth')]),
    EffectModel(3, 'Jet Flanger', [EffectParam('Depth'), EffectParam('Feedback'), EffectParam('Manual')]),
    EffectModel(4, 'Phaser', [EffectParam('Feedback')]),
    EffectModel(5, 'U-Vibe', [EffectParam('Depth')]),
    EffectModel(6, 'Opto Trem', [EffectParam('Wave')]),
    EffectModel(7, 'Bias Trem', [EffectParam('Wave')]),
    EffectModel(8, 'Rotary Drum + Horn', [EffectParam('Tone')]),
    EffectModel(9, 'Rotary Drum', [EffectParam('Tone')]),
    EffectModel(10, 'Auto Pan', [EffectParam('Wave')]),

    // FX Pack mods
    EffectModel(11, 'Analog Square', [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')], 'FX'),
    EffectModel(12, 'Square Chorus', [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')], 'FX'),
    EffectModel(13, 'Expo Chorus', [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')], 'FX'),
    EffectModel(14, 'Random Chorus', [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')], 'FX'),
    EffectModel(15, 'Square Flange', [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')], 'FX'),
    EffectModel(16, 'Expo Flange', [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')], 'FX'),
    EffectModel(17, 'Lumpy Phase', [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')], 'FX'),
    EffectModel(18, 'Hi-Talk', [EffectParam('Depth'), EffectParam('Q')], 'FX'),
    EffectModel(19, 'Sweeper', [EffectParam('Depth'), EffectParam('Q'), EffectParam('Frequency')], 'FX'),
    EffectModel(20, 'POD Purple X', [EffectParam('Feedback'), EffectParam('Depth')], 'FX'),
    EffectModel(21, 'Random S/H', [EffectParam('Depth'), EffectParam('Q')], 'FX'),
    EffectModel(22, 'Tape Eater', [EffectParam('Feedback'), EffectParam('Flutter'), EffectParam('Distortion')], 'FX'),
    EffectModel(23, 'Warble-Matic', [EffectParam('Depth'), EffectParam('Q')], 'FX'),
  ];

  static EffectModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DELAY EFFECTS
// ═══════════════════════════════════════════════════════════════════════════
class DelayModels {
  static const List<EffectModel> all = [
    EffectModel(0, 'Analog Delay', [EffectParam('Feedback'), EffectParam('Bass'), EffectParam('Treble')]),
    EffectModel(1, 'Analog w/ Mod', [EffectParam('Feedback'), EffectParam('Mod Speed'), EffectParam('Depth')]),
    EffectModel(2, 'Tube Echo', [EffectParam('Feedback'), EffectParam('Flutter'), EffectParam('Drive')]),
    EffectModel(3, 'Multi-Head', [EffectParam('Feedback'), EffectParam('Heads'), EffectParam('Flutter')]),
    EffectModel(4, 'Sweep Echo', [EffectParam('Feedback'), EffectParam('Speed'), EffectParam('Depth')]),
    EffectModel(5, 'Digital Delay', [EffectParam('Feedback'), EffectParam('Bass'), EffectParam('Treble')]),
    EffectModel(6, 'Stereo Delay', [EffectParam('Offset'), EffectParam('Feedback L'), EffectParam('Feedback R')]),
    EffectModel(7, 'Ping Pong', [EffectParam('Feedback'), EffectParam('Offset'), EffectParam('Spread')]),
    EffectModel(8, 'Reverse', [EffectParam('Feedback')]),

    // FX Pack delays
    EffectModel(9, 'Echo Platter', [EffectParam('Feedback'), EffectParam('Heads'), EffectParam('Flutter')], 'FX'),
    EffectModel(10, 'Tape Echo', [EffectParam('Feedback'), EffectParam('Bass'), EffectParam('Treble')], 'FX'),
    EffectModel(11, 'Low Rez', [EffectParam('Feedback'), EffectParam('Tone'), EffectParam('Bits')], 'FX'),
    EffectModel(12, 'Phaze Echo', [EffectParam('Feedback'), EffectParam('Mod Speed'), EffectParam('Depth')], 'FX'),
    EffectModel(13, 'Bubble Echo', [EffectParam('Feedback'), EffectParam('Speed'), EffectParam('Depth')], 'FX'),
  ];

  static EffectModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REVERB EFFECTS
// ═══════════════════════════════════════════════════════════════════════════
class ReverbModels {
  static const List<EffectModel> all = [
    EffectModel(0, 'Lux Spring', []),
    EffectModel(1, 'Std Spring', []),
    EffectModel(2, 'King Spring', []),
    EffectModel(3, 'Small Room', []),
    EffectModel(4, 'Tiled Room', []),
    EffectModel(5, 'Brite Room', []),
    EffectModel(6, 'Dark Hall', []),
    EffectModel(7, 'Medium Hall', []),
    EffectModel(8, 'Large Hall', []),
    EffectModel(9, 'Rich Chamber', []),
    EffectModel(10, 'Chamber', []),
    EffectModel(11, 'Cavernous', []),
    EffectModel(12, 'Slap Plate', []),
    EffectModel(13, 'Vintage Plate', []),
    EffectModel(14, 'Large Plate', []),
  ];

  static EffectModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WAH MODELS
// ═══════════════════════════════════════════════════════════════════════════
class WahModels {
  static const List<EffectModel> all = [
    EffectModel(0, 'Vetta Wah', []),
    EffectModel(1, 'Fassel', []),
    EffectModel(2, 'Weeper', []),
    EffectModel(3, 'Chrome', []),
    EffectModel(4, 'Chrome Custom', []),
    EffectModel(5, 'Throaty', []),
    EffectModel(6, 'Conductor', []),
    EffectModel(7, 'Colorful', []),
  ];

  static EffectModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTE DURATIONS (for tempo-synced effects)
// ═══════════════════════════════════════════════════════════════════════════
class NoteDuration {
  final int id;
  final String name;
  final double multiplier; // Relative to whole note

  const NoteDuration(this.id, this.name, this.multiplier);
}

class NoteDurations {
  static const List<NoteDuration> all = [
    NoteDuration(0, 'Off', 0.0),
    NoteDuration(1, 'Whole', 1.0),
    NoteDuration(2, 'Dotted Half', 4.0 / 3.0),
    NoteDuration(3, 'Half', 2.0),
    NoteDuration(4, 'Half Triplet', 3.0),
    NoteDuration(5, 'Dotted Quarter', 8.0 / 3.0),
    NoteDuration(6, 'Quarter', 4.0),
    NoteDuration(7, 'Quarter Triplet', 6.0),
    NoteDuration(8, 'Dotted Eighth', 16.0 / 3.0),
    NoteDuration(9, 'Eighth', 8.0),
    NoteDuration(10, 'Eighth Triplet', 12.0),
    NoteDuration(11, 'Dotted Sixteenth', 32.0 / 3.0),
    NoteDuration(12, 'Sixteenth', 16.0),
    NoteDuration(13, 'Sixteenth Triplet', 24.0),
  ];

  static NoteDuration? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}
