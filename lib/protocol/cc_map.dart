/// MIDI Control Change mappings for POD XT Pro
/// Maps parameter names to CC numbers and buffer addresses
/// Extracted from pod-ui mod-xt/src/config.rs

library;

/// Control Change parameter definition
class CCParam {
  final String name;
  final int cc;
  final int? address; // Buffer address (null = MIDI-only)
  final int minValue;
  final int maxValue;
  final bool inverted;

  const CCParam({
    required this.name,
    required this.cc,
    this.address,
    this.minValue = 0,
    this.maxValue = 127,
    this.inverted = false,
  });

  /// Calculate buffer address from CC (default formula)
  int get bufferAddress => address ?? (32 + cc);
}

/// All POD XT Pro Control Change parameters
class PodXtCC {
  // ═══════════════════════════════════════════════════════════════════════════
  // SWITCHES (enable/disable toggles)
  // ═══════════════════════════════════════════════════════════════════════════
  static const noiseGateEnable = CCParam(name: 'noise_gate_enable', cc: 22, address: 54);
  static const wahEnable = CCParam(name: 'wah_enable', cc: 43, address: 75);
  static const stompEnable = CCParam(name: 'stomp_enable', cc: 25, address: 57);
  static const modEnable = CCParam(name: 'mod_enable', cc: 50, address: 82);
  static const modPosition = CCParam(name: 'mod_position', cc: 57, address: 89);
  static const delayEnable = CCParam(name: 'delay_enable', cc: 28, address: 60);
  static const delayPosition = CCParam(name: 'delay_position', cc: 87, address: 119);
  static const reverbEnable = CCParam(name: 'reverb_enable', cc: 36, address: 68);
  static const reverbPosition = CCParam(name: 'reverb_position', cc: 41, address: 73);
  static const ampEnable = CCParam(name: 'amp_enable', cc: 111, address: 143, inverted: true);
  static const compressorEnable = CCParam(name: 'compressor_enable', cc: 26, address: 58);
  static const eqEnable = CCParam(name: 'eq_enable', cc: 63, address: 95);
  static const tunerEnable = CCParam(name: 'tuner_enable', cc: 69); // MIDI-only
  static const volPedalPosition = CCParam(name: 'vol_pedal_position', cc: 47, address: 79);
  static const loopEnable = CCParam(name: 'loop_enable', cc: 107); // PODxt Pro only, MIDI-only

  // ═══════════════════════════════════════════════════════════════════════════
  // PREAMP
  // ═══════════════════════════════════════════════════════════════════════════
  static const ampSelect = CCParam(name: 'amp_select', cc: 11, address: 44);
  static const ampSelectNoDefaults = CCParam(name: 'amp_select_no_defaults', cc: 12); // MIDI-only
  static const drive = CCParam(name: 'drive', cc: 13, address: 45);
  static const bass = CCParam(name: 'bass', cc: 14, address: 46);
  static const mid = CCParam(name: 'mid', cc: 15, address: 47);
  static const treble = CCParam(name: 'treble', cc: 16, address: 48);
  static const presence = CCParam(name: 'presence', cc: 21, address: 53);
  static const chanVolume = CCParam(name: 'chan_volume', cc: 17, address: 49);
  static const bypassVolume = CCParam(name: 'bypass_volume', cc: 105, address: 137);

  // ═══════════════════════════════════════════════════════════════════════════
  // CABINET & MICROPHONE
  // ═══════════════════════════════════════════════════════════════════════════
  static const cabSelect = CCParam(name: 'cab_select', cc: 71, address: 103);
  static const micSelect = CCParam(name: 'mic_select', cc: 70, address: 102);
  static const room = CCParam(name: 'room', cc: 76, address: 108);

  // ═══════════════════════════════════════════════════════════════════════════
  // NOISE GATE
  // ═══════════════════════════════════════════════════════════════════════════
  static const gateThreshold = CCParam(name: 'gate_threshold', cc: 23, address: 55, maxValue: 96);
  static const gateDecay = CCParam(name: 'gate_decay', cc: 24, address: 56);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPRESSOR
  // ═══════════════════════════════════════════════════════════════════════════
  static const compressorThreshold = CCParam(name: 'compressor_threshold', cc: 9, address: 41);
  static const compressorGain = CCParam(name: 'compressor_gain', cc: 5, address: 37);

  // ═══════════════════════════════════════════════════════════════════════════
  // REVERB
  // ═══════════════════════════════════════════════════════════════════════════
  static const reverbSelect = CCParam(name: 'reverb_select', cc: 37, address: 69);
  static const reverbDecay = CCParam(name: 'reverb_decay', cc: 38, address: 70);
  static const reverbTone = CCParam(name: 'reverb_tone', cc: 39, address: 71);
  static const reverbPreDelay = CCParam(name: 'reverb_pre_delay', cc: 40, address: 72);
  static const reverbLevel = CCParam(name: 'reverb_level', cc: 18, address: 50);
  static const effectSelect = CCParam(name: 'effect_select', cc: 19, address: 51);

  // ═══════════════════════════════════════════════════════════════════════════
  // STOMP
  // ═══════════════════════════════════════════════════════════════════════════
  static const stompSelect = CCParam(name: 'stomp_select', cc: 75, address: 107);
  static const stompParam2 = CCParam(name: 'stomp_param2', cc: 79, address: 111);
  static const stompParam3 = CCParam(name: 'stomp_param3', cc: 80, address: 112);
  static const stompParam4 = CCParam(name: 'stomp_param4', cc: 81, address: 113);
  static const stompParam5 = CCParam(name: 'stomp_param5', cc: 82, address: 114);
  static const stompParam6 = CCParam(name: 'stomp_param6', cc: 83, address: 115);

  // ═══════════════════════════════════════════════════════════════════════════
  // MODULATION
  // ═══════════════════════════════════════════════════════════════════════════
  static const modSelect = CCParam(name: 'mod_select', cc: 58, address: 90);
  static const modSpeedMsb = CCParam(name: 'mod_speed_msb', cc: 29, address: 61);
  static const modSpeedLsb = CCParam(name: 'mod_speed_lsb', cc: 61, address: 93);
  static const modNoteSelect = CCParam(name: 'mod_note_select', cc: 51, address: 83);
  static const modParam2 = CCParam(name: 'mod_param2', cc: 52, address: 84);
  static const modParam3 = CCParam(name: 'mod_param3', cc: 53, address: 85);
  static const modParam4 = CCParam(name: 'mod_param4', cc: 54, address: 86);
  static const modMix = CCParam(name: 'mod_mix', cc: 56, address: 88);

  // ═══════════════════════════════════════════════════════════════════════════
  // DELAY
  // ═══════════════════════════════════════════════════════════════════════════
  static const delaySelect = CCParam(name: 'delay_select', cc: 88, address: 120);
  static const delayTimeMsb = CCParam(name: 'delay_time_msb', cc: 30, address: 62);
  static const delayTimeLsb = CCParam(name: 'delay_time_lsb', cc: 62, address: 94);
  static const delayNoteSelect = CCParam(name: 'delay_note_select', cc: 31, address: 63);
  static const delayParam2 = CCParam(name: 'delay_param2', cc: 33, address: 65);
  static const delayParam3 = CCParam(name: 'delay_param3', cc: 35, address: 67);
  static const delayParam4 = CCParam(name: 'delay_param4', cc: 85, address: 117);
  static const delayMix = CCParam(name: 'delay_mix', cc: 34, address: 66);

  // ═══════════════════════════════════════════════════════════════════════════
  // D.I. (Direct Input)
  // ═══════════════════════════════════════════════════════════════════════════
  static const diModel = CCParam(name: 'di_model', cc: 48, address: 80);
  static const diDelay = CCParam(name: 'di_delay', cc: 49, address: 81);
  static const diXover = CCParam(name: 'di_xover', cc: 45, address: 77);

  // ═══════════════════════════════════════════════════════════════════════════
  // VOLUME PEDAL
  // ═══════════════════════════════════════════════════════════════════════════
  static const volLevel = CCParam(name: 'vol_level', cc: 7, address: 39);
  static const volMinimum = CCParam(name: 'vol_minimum', cc: 46, address: 78);

  // ═══════════════════════════════════════════════════════════════════════════
  // WAH
  // ═══════════════════════════════════════════════════════════════════════════
  static const wahSelect = CCParam(name: 'wah_select', cc: 91, address: 123);
  static const wahLevel = CCParam(name: 'wah_level', cc: 4, address: 36);

  // ═══════════════════════════════════════════════════════════════════════════
  // TWEAKS & PEDALS
  // ═══════════════════════════════════════════════════════════════════════════
  static const tweakParamSelect = CCParam(name: 'tweak_param_select', cc: 108, address: 140);
  static const pedalAssign = CCParam(name: 'pedal_assign', cc: 65, address: 97);

  // ═══════════════════════════════════════════════════════════════════════════
  // EQUALIZER (4-band parametric)
  // ═══════════════════════════════════════════════════════════════════════════
  static const eq1Freq = CCParam(name: 'eq_1_freq', cc: 20, address: 52);
  static const eq1Gain = CCParam(name: 'eq_1_gain', cc: 114);
  static const eq2Freq = CCParam(name: 'eq_2_freq', cc: 42, address: 74);
  static const eq2Gain = CCParam(name: 'eq_2_gain', cc: 116);
  static const eq3Freq = CCParam(name: 'eq_3_freq', cc: 60, address: 92);
  static const eq3Gain = CCParam(name: 'eq_3_gain', cc: 117);
  static const eq4Freq = CCParam(name: 'eq_4_freq', cc: 77, address: 109);
  static const eq4Gain = CCParam(name: 'eq_4_gain', cc: 119);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPO
  // ═══════════════════════════════════════════════════════════════════════════
  static const tempoMsb = CCParam(name: 'tempo_msb', cc: 89, address: 121);
  static const tempoLsb = CCParam(name: 'tempo_lsb', cc: 90, address: 122);

  /// All parameters as a list for iteration
  static const List<CCParam> all = [
    // Switches
    noiseGateEnable, wahEnable, stompEnable, modEnable, modPosition,
    delayEnable, delayPosition, reverbEnable, reverbPosition, ampEnable,
    compressorEnable, eqEnable, tunerEnable, volPedalPosition, loopEnable,
    // Preamp
    ampSelect, ampSelectNoDefaults, drive, bass, mid, treble, presence,
    chanVolume, bypassVolume,
    // Cabinet & Mic
    cabSelect, micSelect, room,
    // Noise Gate
    gateThreshold, gateDecay,
    // Compressor
    compressorThreshold, compressorGain,
    // Reverb
    reverbSelect, reverbDecay, reverbTone, reverbPreDelay, reverbLevel, effectSelect,
    // Stomp
    stompSelect, stompParam2, stompParam3, stompParam4, stompParam5, stompParam6,
    // Modulation
    modSelect, modSpeedMsb, modSpeedLsb, modNoteSelect, modParam2, modParam3, modParam4, modMix,
    // Delay
    delaySelect, delayTimeMsb, delayTimeLsb, delayNoteSelect, delayParam2, delayParam3, delayParam4, delayMix,
    // D.I.
    diModel, diDelay, diXover,
    // Volume Pedal
    volLevel, volMinimum,
    // Wah
    wahSelect, wahLevel,
    // Tweaks
    tweakParamSelect, pedalAssign,
    // EQ
    eq1Freq, eq1Gain, eq2Freq, eq2Gain, eq3Freq, eq3Gain, eq4Freq, eq4Gain,
    // Tempo
    tempoMsb, tempoLsb,
  ];

  /// Map CC number to parameter
  static final Map<int, CCParam> byCC = {
    for (final p in all) p.cc: p
  };

  /// Map name to parameter
  static final Map<String, CCParam> byName = {
    for (final p in all) p.name: p
  };
}
