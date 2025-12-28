/// Amplifier model definitions for POD XT Pro
/// Extracted from pod-ui mod-xt/src/config.rs

library;

/// Amp model with ID and display name
class AmpModel {
  final int id;
  final String name;
  final String? pack; // null = stock, otherwise expansion pack code

  const AmpModel(this.id, this.name, [this.pack]);

  bool get isStock => pack == null;
}

/// All available amp models
class AmpModels {
  static const List<AmpModel> all = [
    // Stock amps (IDs 0-36)
    AmpModel(0, 'No Amp'),
    AmpModel(1, 'Tube Preamp'),
    AmpModel(2, 'Line 6 Clean'),
    AmpModel(3, 'Line 6 JTS-45'),
    AmpModel(4, 'Line 6 Class A'),
    AmpModel(5, 'Line 6 Mood'),
    AmpModel(6, 'Spinal Puppet'),
    AmpModel(7, 'Line 6 Chemical X'),
    AmpModel(8, 'Line 6 Insane'),
    AmpModel(9, 'Line 6 Acoustic 2'),
    AmpModel(10, 'Zen Master'),
    AmpModel(11, 'Small Tweed'),
    AmpModel(12, 'Tweed B-Man'),
    AmpModel(13, 'Tiny Tweed'),
    AmpModel(14, 'Blackface Lux'),
    AmpModel(15, 'Double Verb'),
    AmpModel(16, 'Two-Tone'),
    AmpModel(17, 'Hiway 100'),
    AmpModel(18, 'Plexi 45'),
    AmpModel(19, 'Plexi Lead 100'),
    AmpModel(20, 'Plexi Jump Lead'),
    AmpModel(21, 'Plexi Variac'),
    AmpModel(22, 'Brit J-800'),
    AmpModel(23, 'Brit JM Pre'),
    AmpModel(24, 'Match Chief'),
    AmpModel(25, 'Match D-30'),
    AmpModel(26, 'Treadplate Dual'),
    AmpModel(27, 'Cali Crunch'),
    AmpModel(28, 'Jazz Clean'),
    AmpModel(29, 'Solo 100'),
    AmpModel(30, 'Super O'),
    AmpModel(31, 'Class A-15'),
    AmpModel(32, 'Class A-30 TB'),
    AmpModel(33, 'Line 6 Argo'),
    AmpModel(34, 'Line 6 Lunatic'),
    AmpModel(35, 'Line 6 Treadplate'),
    AmpModel(36, 'Variax Acoustic'),

    // MS Pack - Metal Shop Amp Expansion (IDs 37-52)
    AmpModel(37, 'Bomber Uber', 'MS'),
    AmpModel(38, 'Connor 50', 'MS'),
    AmpModel(39, 'Deity Lead', 'MS'),
    AmpModel(40, 'Deity\'s Son', 'MS'),
    AmpModel(41, 'Angel P-Ball', 'MS'),
    AmpModel(42, 'Silver J', 'MS'),
    AmpModel(43, 'Brit J-900 Clean', 'MS'),
    AmpModel(44, 'Brit J-900 Dist', 'MS'),
    AmpModel(45, 'Brit J-2000', 'MS'),
    AmpModel(46, 'Diamondplate', 'MS'),
    AmpModel(47, 'Criminal', 'MS'),
    AmpModel(48, 'Big Bottom', 'MS'),
    AmpModel(49, 'Chunk-Chunk', 'MS'),
    AmpModel(50, 'Fuzz', 'MS'),
    AmpModel(51, 'Octone', 'MS'),
    AmpModel(52, 'Smash', 'MS'),

    // CC Pack - Collector's Classic Amp Expansion (IDs 53-71)
    AmpModel(53, 'Bomber XTC', 'CC'),
    AmpModel(54, 'Deity Crunch', 'CC'),
    AmpModel(55, 'Blackface Vibro', 'CC'),
    AmpModel(56, 'Double Show', 'CC'),
    AmpModel(57, 'Silverface Bass', 'CC'),
    AmpModel(58, 'Mini Double', 'CC'),
    AmpModel(59, 'Gibtone Expo', 'CC'),
    AmpModel(60, 'Brit Bass', 'CC'),
    AmpModel(61, 'Brit Major', 'CC'),
    AmpModel(62, 'Silver Twelve', 'CC'),
    AmpModel(63, 'Super O Thunder', 'CC'),
    AmpModel(64, 'Bayou', 'CC'),
    AmpModel(65, 'Crunch', 'CC'),
    AmpModel(66, 'Purge', 'CC'),
    AmpModel(67, 'Sparkle', 'CC'),
    AmpModel(68, 'Super Clean', 'CC'),
    AmpModel(69, 'Super Sparkle', 'CC'),
    AmpModel(70, 'Twang', 'CC'),
    AmpModel(71, 'Sparkle Clean', 'CC'),

    // BX Pack - Bass expansion (IDs 72-127)
    AmpModel(72, 'BX Tube Preamp', 'BX'),
    AmpModel(73, 'BX Classic Jazz', 'BX'),
    AmpModel(74, 'BX Brit Invader', 'BX'),
    AmpModel(75, 'BX Super Thor', 'BX'),
    AmpModel(76, 'BX Frankenstein', 'BX'),
    AmpModel(77, 'BX Ebony Lux', 'BX'),
    AmpModel(78, 'BX Doppelganger', 'BX'),
    AmpModel(79, 'BX Sub Dub', 'BX'),
    AmpModel(80, 'BX Amp 360', 'BX'),
    AmpModel(81, 'BX Jaguar', 'BX'),
    AmpModel(82, 'BX Alchemist', 'BX'),
    AmpModel(83, 'BX Rock Classic', 'BX'),
    AmpModel(84, 'BX Flip Top', 'BX'),
    AmpModel(85, 'BX Adam and Eve', 'BX'),
    AmpModel(86, 'BX Tweed B-Man', 'BX'),
    AmpModel(87, 'BX Silverface Bass', 'BX'),
    AmpModel(88, 'BX Double Show', 'BX'),
    AmpModel(89, 'BX Eighties', 'BX'),
    AmpModel(90, 'BX Hiway 100', 'BX'),
    AmpModel(91, 'BX Hiway 200', 'BX'),
    AmpModel(92, 'BX British Major', 'BX'),
    AmpModel(93, 'BX British Bass', 'BX'),
    AmpModel(94, 'BX California', 'BX'),
    AmpModel(95, 'BX Jazz Tone', 'BX'),
    AmpModel(96, 'BX Stadium', 'BX'),
    AmpModel(97, 'BX Studio Tone', 'BX'),
    AmpModel(98, 'BX Motor City', 'BX'),
    AmpModel(99, 'Brit Class A100', 'BX'),
    AmpModel(100, 'Citrus D-30', 'BX'),
    AmpModel(101, 'L6 Mod Hi Gain', 'BX'),
    AmpModel(102, 'Boutique #1', 'BX'),
    AmpModel(103, 'Class A-30 Fawn', 'BX'),
    AmpModel(104, 'Brit Gain 18', 'BX'),
    AmpModel(105, 'Brit J-2000 #2', 'BX'),
  ];

  static AmpModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }

  static List<AmpModel> get stock => all.where((a) => a.isStock).toList();

  static List<AmpModel> byPack(String pack) =>
      all.where((a) => a.pack == pack).toList();
}
