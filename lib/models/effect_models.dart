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
  final String? basedOn;

  const EffectModel(this.id, this.name, this.params, [this.pack, this.basedOn]);

  bool get isStock => pack == null;
}

// ═══════════════════════════════════════════════════════════════════════════
// STOMP EFFECTS
// ═══════════════════════════════════════════════════════════════════════════
class StompModels {
  static const List<EffectModel> all = [
    EffectModel(
      0,
      'Facial Fuzz',
      [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')],
      null,
      'Arbiter Fuzz Face',
    ),
    EffectModel(
      1,
      'Fuzz Pi',
      [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')],
      null,
      'Electro-Harmonix Big Muff Pi',
    ),
    EffectModel(
      2,
      'Screamer',
      [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')],
      null,
      'Ibanez Tube Screamer',
    ),
    EffectModel(
      3,
      'Classic Dist',
      [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')],
      null,
      'ProCo Rat',
    ),
    EffectModel(
      4,
      'Octave Fuzz',
      [EffectParam('Drive'), EffectParam('Gain'), EffectParam('Tone')],
      null,
      'Tycobrahe Octavia',
    ),
    EffectModel(
      5,
      'Blue Comp',
      [EffectParam('Sustain'), EffectParam('Level')],
      null,
      'Boss CS-1',
    ),
    EffectModel(
      6,
      'Red Comp',
      [EffectParam('Sustain'), EffectParam('Level')],
      null,
      'MXR Dyna Comp',
    ),
    EffectModel(
      7,
      'Vetta Comp',
      [EffectParam('Sens'), EffectParam('Level')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      8,
      'Auto Swell',
      [EffectParam('Ramp'), EffectParam('Depth')],
      null,
      'Boss SG-1 Slow Gear',
    ),
    EffectModel(
      9,
      'Auto Wah',
      [EffectParam('Sens'), EffectParam('Q')],
      null,
      'Mu-Tron III',
    ),

    // FX Pack stomps
    EffectModel(
      10,
      'Killer Z',
      [
        EffectParam('Drive'),
        EffectParam('Contour'),
        EffectParam('Gain'),
        EffectParam('Mid'),
        EffectParam('Mid Freq'),
      ],
      'FX',
      'Boss Metal Zone',
    ),
    EffectModel(
      11,
      'Tube Drive',
      [
        EffectParam('Drive'),
        EffectParam('Gain'),
        EffectParam('Treble'),
        EffectParam('Bass'),
      ],
      'FX',
      'Chandler Tube Driver',
    ),
    EffectModel(
      12,
      'Vetta Juice',
      [EffectParam('Amount'), EffectParam('Level')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      13,
      'Boost + EQ',
      [
        EffectParam('Gain'),
        EffectParam('Bass'),
        EffectParam('Treble'),
        EffectParam('Mid'),
        EffectParam('Mid Freq'),
      ],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      14,
      'Blue Comp Treb',
      [EffectParam('Sustain'), EffectParam('Level')],
      'FX',
      'Boss CS-1',
    ),
    EffectModel(
      15,
      'Dingo-Tron',
      [EffectParam('Sens'), EffectParam('Q')],
      'FX',
      'Mu-Tron III',
    ),
    EffectModel(
      16,
      'Clean Sweep',
      [EffectParam('Decay'), EffectParam('Sens'), EffectParam('Q')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      17,
      'Seismik Synth',
      [EffectParam('Wave'), EffectParam('Mix')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      18,
      'Double Bass',
      [EffectParam('-1 OctG'), EffectParam('-2 OctG'), EffectParam('Mix')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      19,
      'Buzz Wave',
      [
        EffectParam('Wave'),
        EffectParam('Filter'),
        EffectParam('Decay'),
        EffectParam('Mix'),
      ],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      20,
      'Rez Synth',
      [
        EffectParam('Wave'),
        EffectParam('Filter'),
        EffectParam('Decay'),
        EffectParam('Mix'),
      ],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      21,
      'Saturn 5 Ring M',
      [EffectParam('Wave'), EffectParam('Mix')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      22,
      'Synth Analog',
      [
        EffectParam('Wave'),
        EffectParam('Filter'),
        EffectParam('Decay'),
        EffectParam('Mix'),
      ],
      'FX',
      'Moog and ARP Synth',
    ),
    EffectModel(
      23,
      'Synth FX',
      [
        EffectParam('Wave'),
        EffectParam('Filter'),
        EffectParam('Decay'),
        EffectParam('Mix'),
      ],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      24,
      'Synth Harmony',
      [
        EffectParam('1M335', maxValue: 8),
        EffectParam('1457', maxValue: 8),
        EffectParam('Wave'),
        EffectParam('Mix'),
      ],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      25,
      'Synth Lead',
      [
        EffectParam('Wave'),
        EffectParam('Filter'),
        EffectParam('Decay'),
        EffectParam('Mix'),
      ],
      'FX',
      'Moog/ARP/Sequential Synth',
    ),
    EffectModel(
      26,
      'Synth String',
      [
        EffectParam('Wave'),
        EffectParam('Filter'),
        EffectParam('Attack'),
        EffectParam('Mix'),
      ],
      'FX',
      'ARP Solina and Elka Synthex',
    ),

    // BX Pack stomps
    EffectModel(
      27,
      'Bass Overdrive',
      [
        EffectParam('Bass'),
        EffectParam('Treble'),
        EffectParam('Drive'),
        EffectParam('Gain'),
      ],
      'BX',
      'Tech 21 Bass Sans Amp',
    ),
    EffectModel(
      28,
      'Bronze Master',
      [EffectParam('Drive'), EffectParam('Tone'), EffectParam('Blend')],
      'BX',
      'Maestro Bass Brassmaster',
    ),
    EffectModel(
      29,
      'Sub Octaves',
      [EffectParam('-1 OctG'), EffectParam('-2 OctG'), EffectParam('Mix')],
      'BX',
      'Line 6 Original',
    ),
    EffectModel(
      30,
      'Bender',
      [
        EffectParam('Position'),
        EffectParam('Heel', minValue: -24, maxValue: 24),
        EffectParam('Toe', minValue: -24, maxValue: 24),
        EffectParam('Mix'),
      ],
      'BX',
      'Line 6 Original',
    ),
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
    EffectModel(
      0,
      'Sine Chorus',
      [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      1,
      'Analog Chorus',
      [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')],
      null,
      'Boss CE-1',
    ),
    EffectModel(
      2,
      'Line 6 Flanger',
      [EffectParam('Depth')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      3,
      'Jet Flanger',
      [EffectParam('Depth'), EffectParam('Feedback'), EffectParam('Manual')],
      null,
      'A/DA Flanger',
    ),
    EffectModel(4, 'Phaser', [EffectParam('Feedback')], null, 'MXR Phase 90'),
    EffectModel(5, 'U-Vibe', [EffectParam('Depth')], null, 'Uni-Vibe'),
    EffectModel(
      6,
      'Opto Trem',
      [EffectParam('Wave')],
      null,
      'Blackface Fender Tremolo',
    ),
    EffectModel(7, 'Bias Trem', [EffectParam('Wave')], null, '1960 Vox AC-15'),
    EffectModel(
      8,
      'Rotary Drum + Horn',
      [EffectParam('Tone')],
      null,
      'Leslie 145',
    ),
    EffectModel(
      9,
      'Rotary Drum',
      [EffectParam('Tone')],
      null,
      'Fender Vibratone',
    ),
    EffectModel(10, 'Auto Pan', [EffectParam('Wave')], null, 'Line 6 Original'),

    // FX Pack mods
    EffectModel(
      11,
      'Analog Square',
      [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')],
      'FX',
      'Boss CE-1',
    ),
    EffectModel(
      12,
      'Square Chorus',
      [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      13,
      'Expo Chorus',
      [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      14,
      'Random Chorus',
      [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      15,
      'Square Flange',
      [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      16,
      'Expo Flange',
      [EffectParam('Depth'), EffectParam('Pre-delay'), EffectParam('Feedback')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      17,
      'Lumpy Phase',
      [EffectParam('Depth'), EffectParam('Bass'), EffectParam('Treble')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      18,
      'Hi-Talk',
      [EffectParam('Depth'), EffectParam('Q')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      19,
      'Sweeper',
      [EffectParam('Depth'), EffectParam('Q'), EffectParam('Frequency')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      20,
      'POD Purple X',
      [EffectParam('Feedback'), EffectParam('Depth')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      21,
      'Random S/H',
      [EffectParam('Depth'), EffectParam('Q')],
      'FX',
      'Oberheim VCF',
    ),
    EffectModel(
      22,
      'Tape Eater',
      [EffectParam('Feedback'), EffectParam('Flutter'), EffectParam('Dist')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      23,
      'Warble-Matic',
      [EffectParam('Depth'), EffectParam('Q')],
      'FX',
      'Line 6 Original',
    ),
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
    EffectModel(
      0,
      'Analog Delay',
      [EffectParam('Feedback'), EffectParam('Bass'), EffectParam('Treble')],
      null,
      'Boss DM-2',
    ),
    EffectModel(
      1,
      'Analog w/ Mod',
      [EffectParam('Feedback'), EffectParam('Mod Speed'), EffectParam('Depth')],
      null,
      'Electro-Harmonix Memory Man',
    ),
    EffectModel(
      2,
      'Tube Echo',
      [EffectParam('Feedback'), EffectParam('Flutter'), EffectParam('Drive')],
      null,
      '1963 Maestro EP-1 Echoplex',
    ),
    EffectModel(
      3,
      'Multi-Head',
      [
        EffectParam('Feedback'),
        EffectParam('Heads', maxValue: 8),
        EffectParam('Flutter'),
      ],
      null,
      'Roland RE-101',
    ),
    EffectModel(
      4,
      'Sweep Echo',
      [EffectParam('Feedback'), EffectParam('Speed'), EffectParam('Depth')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      5,
      'Digital Delay',
      [EffectParam('Feedback'), EffectParam('Bass'), EffectParam('Treble')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      6,
      'Stereo Delay',
      [EffectParam('Offset'), EffectParam('Fdbk L'), EffectParam('Fdbk R')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      7,
      'Ping Pong',
      [EffectParam('Feedback'), EffectParam('Offset'), EffectParam('Spread')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      8,
      'Reverse',
      [EffectParam('Feedback')],
      null,
      'Line 6 Original',
    ),

    // FX Pack delays
    EffectModel(
      9,
      'Echo Platter',
      [
        EffectParam('Feedback'),
        EffectParam('Heads', maxValue: 8),
        EffectParam('Flutter'),
      ],
      'FX',
      'Binson EchoRec',
    ),
    EffectModel(
      10,
      'Tape Echo',
      [EffectParam('Feedback'), EffectParam('Bass'), EffectParam('Treble')],
      'FX',
      'Maestro EP-3',
    ),
    EffectModel(
      11,
      'Low Rez',
      [
        EffectParam('Feedback'),
        EffectParam('Tone'),
        EffectParam('Bits', maxValue: 8),
      ],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      12,
      'Phaze Echo',
      [EffectParam('Feedback'), EffectParam('Mod Speed'), EffectParam('Depth')],
      'FX',
      'Line 6 Original',
    ),
    EffectModel(
      13,
      'Bubble Echo',
      [EffectParam('Feedback'), EffectParam('Speed'), EffectParam('Depth')],
      'FX',
      'Line 6 Original',
    ),
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
    // Spring reverbs have only Dwell and Tone parameters
    EffectModel(
      0,
      'Lux Spring',
      [EffectParam('Dwell'), EffectParam('Tone')],
      null,
      'Blackface Fender Deluxe Reverb',
    ),
    EffectModel(
      1,
      'Std Spring',
      [EffectParam('Dwell'), EffectParam('Tone')],
      null,
      'Blackface Fender Twin Reverb',
    ),
    EffectModel(
      2,
      'King Spring',
      [EffectParam('Dwell'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),

    // All other reverbs have Pre-Delay, Decay, and Tone parameters (in that order)
    EffectModel(
      3,
      'Small Room',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      4,
      'Tiled Room',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      5,
      'Brite Room',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      6,
      'Dark Hall',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      7,
      'Medium Hall',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      8,
      'Large Hall',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      9,
      'Rich Chamber',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      10,
      'Chamber',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      11,
      'Cavernous',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      12,
      'Slap Plate',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      13,
      'Vintage Plate',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
    EffectModel(
      14,
      'Large Plate',
      [EffectParam('Pre-Delay'), EffectParam('Decay'), EffectParam('Tone')],
      null,
      'Line 6 Original',
    ),
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
    EffectModel(0, 'Vetta Wah', [], null, 'Line 6 Original'),
    EffectModel(1, 'Fassel', [], null, 'Cry Baby Super'),
    EffectModel(2, 'Weeper', [], null, 'Arbiter Cry Baby'),
    EffectModel(3, 'Chrome', [], null, 'Vox V847'),
    EffectModel(4, 'Chrome Custom', [], null, 'Modified Vox V847'),
    EffectModel(5, 'Throaty', [], null, 'RMC Real McCoy 1'),
    EffectModel(6, 'Conductor', [], null, 'Maestro Boomerang'),
    EffectModel(7, 'Colorful', [], null, 'Colorsound Wah-Fuzz'),
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
  final String label; // Compact fraction notation for display
  final double multiplier; // Relative to whole note

  const NoteDuration(this.id, this.name, this.label, this.multiplier);
}

class NoteDurations {
  static const List<NoteDuration> all = [
    NoteDuration(0, 'Off', 'Off', 0.0),
    NoteDuration(1, 'Whole', '1/1', 1.0),
    NoteDuration(2, 'Dotted Half', '1/2.', 4.0 / 3.0),
    NoteDuration(3, 'Half', '1/2', 2.0),
    NoteDuration(4, 'Half Triplet', '1/2T', 3.0),
    NoteDuration(5, 'Dotted Quarter', '1/4.', 8.0 / 3.0),
    NoteDuration(6, 'Quarter', '1/4', 4.0),
    NoteDuration(7, 'Quarter Triplet', '1/4T', 6.0),
    NoteDuration(8, 'Dotted Eighth', '1/8.', 16.0 / 3.0),
    NoteDuration(9, 'Eighth', '1/8', 8.0),
    NoteDuration(10, 'Eighth Triplet', '1/8T', 12.0),
    NoteDuration(11, 'Dotted Sixteenth', '1/16.', 32.0 / 3.0),
    NoteDuration(12, 'Sixteenth', '1/16', 16.0),
    NoteDuration(13, 'Sixteenth Triplet', '1/16T', 24.0),
  ];

  static NoteDuration? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}
