/// Amplifier model definitions for POD XT Pro
/// Based on official POD XT Models reference (page 2 POD.pdf)

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
    // Standard & Power Pack Amps (IDs 0-36, 101-106)
    AmpModel(0, 'Bypass'),
    AmpModel(1, 'Tube Preamp'),
    AmpModel(2, 'Line 6 Clean'),
    AmpModel(3, 'Line 6 JTS-45'),
    AmpModel(4, 'Line 6 Class A'),
    AmpModel(5, 'Line 6 Mood'),
    AmpModel(6, 'Spinal Puppet'),
    AmpModel(7, 'Line 6 Chem X'),
    AmpModel(8, 'Line 6 Insane'),
    AmpModel(9, 'Line 6 Aco 2'),
    AmpModel(10, 'Zen Master'),
    AmpModel(11, 'Small Tweed'),
    AmpModel(12, 'Tweed B-Man'),
    AmpModel(13, 'Tiny Tweed'),
    AmpModel(14, 'Blackface Lux'),
    AmpModel(15, 'Double Verb'),
    AmpModel(16, 'Two-Tone'),
    AmpModel(17, 'Hiway 100'),
    AmpModel(18, 'Plexi 45 PP'),
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
    AmpModel(33, 'L6 Agro'),
    AmpModel(34, 'L6 Lunatic'),
    AmpModel(35, 'L6 Treadplate'),
    AmpModel(36, 'Variax Acoustic'),

    // Metal Shop Amp Expansion (IDs 37-54)
    AmpModel(37, 'Bomber Uber', 'MS'),
    AmpModel(38, 'Conor 50', 'MS'),
    AmpModel(39, 'Deity Lead', 'MS'),
    AmpModel(40, 'Deity\'s Son', 'MS'),
    AmpModel(41, 'Angel P-Ball', 'MS'),
    AmpModel(42, 'Brit Sliver', 'MS'),
    AmpModel(43, 'Brit J-900 Cln', 'MS'),
    AmpModel(44, 'Brit J-900 Dst', 'MS'),
    AmpModel(45, 'Brit J-2000', 'MS'),
    AmpModel(46, 'Diamond Plate', 'MS'),
    AmpModel(47, 'Criminal', 'MS'),
    AmpModel(48, 'L6 Big Bottom', 'MS'),
    AmpModel(49, 'L6 Chunk Chunk', 'MS'),
    AmpModel(50, 'L6 Fuzz', 'MS'),
    AmpModel(51, 'L6 Octone', 'MS'),
    AmpModel(52, 'L6 Smash', 'MS'),
    AmpModel(53, 'L6 Sparkle Cln', 'MS'),
    AmpModel(54, 'L6 Throttle', 'MS'),

    // Collector's Classic Amp Expansion (IDs 55-72)
    AmpModel(55, 'Bomber X-TC', 'CC'),
    AmpModel(56, 'Deity Crunch', 'CC'),
    AmpModel(57, 'Blackface Vibro', 'CC'),
    AmpModel(58, 'Double Show', 'CC'),
    AmpModel(59, 'Silverface Bass', 'CC'),
    AmpModel(60, 'Mini Double', 'CC'),
    AmpModel(61, 'Gibtone Expo', 'CC'),
    AmpModel(62, 'Brit Bass', 'CC'),
    AmpModel(63, 'Brit Major', 'CC'),
    AmpModel(64, 'Silver Twelve', 'CC'),
    AmpModel(65, 'Supro \'62 Thunderbolt', 'CC'),
    AmpModel(66, 'L6 Bayou', 'CC'),
    AmpModel(67, 'L6 Crunch', 'CC'),
    AmpModel(68, 'L6 Purge', 'CC'),
    AmpModel(69, 'L6 Sparkle', 'CC'),
    AmpModel(70, 'L6 Super Cln', 'CC'),
    AmpModel(71, 'L6 Superspark', 'CC'),
    AmpModel(72, 'L6 Twang', 'CC'),

    // Bass Expansion Amps (IDs 73-100)
    AmpModel(73, 'Tube Preamp', 'BX'),
    AmpModel(74, 'L6 Classic Jazz', 'BX'),
    AmpModel(75, 'L6 Brit Invader', 'BX'),
    AmpModel(76, 'L6 Super Thor', 'BX'),
    AmpModel(77, 'L6 Frankenstein', 'BX'),
    AmpModel(78, 'L6 Ebonylux', 'BX'),
    AmpModel(79, 'L6 Doppelganger', 'BX'),
    AmpModel(80, 'Sub Dub', 'BX'),
    AmpModel(81, 'Amp 360', 'BX'),
    AmpModel(82, 'Jaguer', 'BX'),
    AmpModel(83, 'Alcemist', 'BX'),
    AmpModel(84, 'Rock Classic', 'BX'),
    AmpModel(85, 'Flip Top', 'BX'),
    AmpModel(86, 'Adam and Eve', 'BX'),
    AmpModel(87, 'Tweed B-Man', 'BX'),
    AmpModel(88, 'Silverface Bass', 'BX'),
    AmpModel(89, 'Double Show', 'BX'),
    AmpModel(90, 'Eighties', 'BX'),
    AmpModel(91, 'Hiway 100', 'BX'),
    AmpModel(92, 'Hiway 200', 'BX'),
    AmpModel(93, 'Brit Major', 'BX'),
    AmpModel(94, 'Brit Bass', 'BX'),
    AmpModel(95, 'California', 'BX'),
    AmpModel(96, 'Jazz Tone', 'BX'),
    AmpModel(97, 'Stadium', 'BX'),
    AmpModel(98, 'Studio Tone', 'BX'),
    AmpModel(99, 'Motor City', 'BX'),
    AmpModel(100, 'Brit Class A100', 'BX'),

    // Additional Standard Models (IDs 101-106)
    AmpModel(101, 'Citrus D-30'),
    AmpModel(102, 'Class A-30 Fawn'),
    AmpModel(103, 'Brit Gain 18'),
    AmpModel(104, 'J-2000 #2'),
    AmpModel(105, 'Line 6 Boutique'),
    AmpModel(106, 'Line 6 Modern Gain #1'),
  ];

  static AmpModel? byId(int id) {
    try {
      return all.firstWhere((amp) => amp.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<AmpModel> get stock => all.where((a) => a.isStock).toList();

  static List<AmpModel> byPack(String pack) =>
      all.where((a) => a.pack == pack).toList();
}
