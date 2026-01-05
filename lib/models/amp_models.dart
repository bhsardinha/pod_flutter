/// Amplifier model definitions for POD XT Pro
/// Based on official POD XT Models reference (page 2 POD.pdf)

library;

/// Amp model with ID and display name
class AmpModel {
  final int id;
  final String name;
  final String? pack; // null = stock, otherwise expansion pack code
  final String? realName; // Real-world amp name (manufacturer + model)

  const AmpModel(this.id, this.name, [this.pack, this.realName]);

  bool get isStock => pack == null;

  /// Get display name based on mode
  String getDisplayName(AmpNameDisplayMode mode) {
    switch (mode) {
      case AmpNameDisplayMode.factory:
        return pack != null ? '$pack-$name' : name;
      case AmpNameDisplayMode.realAmp:
        return realName ?? name;
      case AmpNameDisplayMode.both:
        return name; // UI will handle showing both
    }
  }

  /// Get real name for "both" mode (smaller, top line)
  String? getRealNameForBothMode() => realName;
}

/// Amp name display mode
enum AmpNameDisplayMode { factory, realAmp, both }

/// All available amp models - Number List Based on My POD XT Pro
class AmpModels {
  static const List<AmpModel> all = [
    // Standard & Power Pack Amps (IDs 0-36, 101-106)
    AmpModel(0, 'Bypass', null, 'No Amp'),
    AmpModel(1, 'Tube Preamp'),
    AmpModel(2, 'Line 6 Clean'),
    AmpModel(3, 'Line 6 JTS-45'),
    AmpModel(4, 'Line 6 Class A'),
    AmpModel(5, 'Line 6 Mood'),
    AmpModel(6, 'Line 6 Spinal Puppet'),
    AmpModel(7, 'Line 6 Chemical X'),
    AmpModel(8, 'Line 6 Insane'),
    AmpModel(9, 'Line 6 Piezacoustic 2'),
    AmpModel(10, 'Zen Master', null, 'Budda Twinmaster'),
    AmpModel(11, 'Small Tweed', null, '1953 Fender Tweed Deluxe'),
    AmpModel(12, 'Tweed B-Man', null, '1958 Fender Bassman'),
    AmpModel(13, 'Tiny Tweed', null, '1961 Fender Tweed Champ'),
    AmpModel(14, 'Blackface Lux', null, '1964 Fender Blackface Deluxe Reverb'),
    AmpModel(15, 'Double Verb', null, '1965 Fender Twin Reverb'),
    AmpModel(16, 'Two-Tone', null, 'Gretsch® 6156'),
    AmpModel(17, 'Hiway 100', null, 'Hiwatt DR-103'),
    AmpModel(18, 'Plexi 45', null, '1965 Marshall JTM-45'),
    AmpModel(19, 'Plexi Lead 100', null, '1968 Marshall Plexi Super Lead'),
    AmpModel(20, 'Plexi Jump Lead', null, '1968 Marshall Plexi Jumped'),
    AmpModel(21, 'Plexi Variac', null, '1968 Marshall Plexi w/ Variac'),
    AmpModel(22, 'Brit J-800', null, '1990 Marshall JCM-800'),
    AmpModel(23, 'Brit JM Pre', null, '1992 Marshall JMP-1'),
    AmpModel(24, 'Match Chief', null, '1996 Matchless Chieftain'),
    AmpModel(25, 'Match D-30', null, '1990 Matchless DC-30'),
    AmpModel(
      26,
      'Treadplate Dual',
      null,
      '2001 Mesa/Boogie Dual Rectifier Solo',
    ),
    AmpModel(27, 'Cali Crunch', null, '1983 Mesa/Boogie Mark II C+'),
    AmpModel(28, 'Jazz Clean', null, 'Roland JC-120'),
    AmpModel(29, 'Solo 100', null, 'Soldano SLO-100'),
    AmpModel(30, 'Super O', null, 'Supro S6616'),
    AmpModel(31, 'Class A-15', null, '1960 Vox AC-15'),
    AmpModel(32, 'Class A-30 TB', null, '1967 Vox AC-30 Top Boost'),
    AmpModel(33, 'Line 6 Agro'),
    AmpModel(34, 'Line 6 Lunatic'),
    AmpModel(35, 'Line 6 Treadplate'),
    AmpModel(36, 'Line 6 Variax Acoustic'),

    // Metal Shop Amp Expansion (IDs 37-54)
    AmpModel(37, 'Bomber Uber', 'MS'),
    AmpModel(38, 'Connor 50', 'MS'),
    AmpModel(39, 'Deity Lead', 'MS'),
    AmpModel(40, 'Deity\'s Son', 'MS'),
    AmpModel(41, 'Angel P-Ball', 'MS'),
    AmpModel(42, 'Brit Sliver', 'MS'),
    AmpModel(43, 'Brit J-900 Cln', 'MS'),
    AmpModel(44, 'Brit J-900 Dst', 'MS'),
    AmpModel(45, 'Brit J-2000', 'MS'),
    AmpModel(46, 'Diamondplate', 'MS'),
    AmpModel(47, 'Criminal', 'MS'),
    AmpModel(48, 'Line 6 Big Bottom', 'MS'),
    AmpModel(49, 'Line 6 Chunk Chunk', 'MS'),
    AmpModel(50, 'Line 6 Fuzz', 'MS'),
    AmpModel(51, 'Line 6 Octone', 'MS'),
    AmpModel(52, 'Line 6 Smash', 'MS'),
    AmpModel(53, 'Line 6 Sparkle Clean', 'MS'),
    AmpModel(54, 'Line 6 Throttle', 'MS'),

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
    AmpModel(65, 'Super O Thunder', 'CC'),
    AmpModel(66, 'Line 6 Bayou', 'CC'),
    AmpModel(67, 'Line 6 Crunch', 'CC'),
    AmpModel(68, 'Line 6 Purge', 'CC'),
    AmpModel(69, 'Line 6 Sparkle', 'CC'),
    AmpModel(70, 'Line 6 Super Clean', 'CC'),
    AmpModel(71, 'Line 6 Superspark', 'CC'),
    AmpModel(72, 'Line 6 Twang', 'CC'),

    // Bass Expansion Amps (IDs 73-100)
    AmpModel(73, 'Tube Preamp', 'BX'),
    AmpModel(74, 'Line 6 Classic Jazz', 'BX'),
    AmpModel(75, 'Line 6 Brit Invader', 'BX'),
    AmpModel(76, 'Line 6 Super Thor', 'BX'),
    AmpModel(77, 'Line 6 Frankenstein', 'BX'),
    AmpModel(78, 'Line 6 Ebonylux', 'BX'),
    AmpModel(79, 'Line 6 Doppelganger', 'BX'),
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
    AmpModel(101, 'Citrus D-30', null, '2005 Orange AD30TC'),
    AmpModel(102, 'Line 6 Modern Hi Gain', null, 'POD 2.0 Soldano X88R'),
    AmpModel(
      103,
      'Line 6 Boutique #1',
      null,
      'POD 2.0 Dumble Overdrive Special',
    ),
    AmpModel(104, 'Class A-30 Fawn', null, 'Vox AC-30 (Non Top Boost)'),
    AmpModel(105, 'Brit Gain 18', null, 'Marshall 1974X reissue'),
    AmpModel(106, 'Brit J-2000 #2', null, 'Marshall JCM2000 DSL + Germ'),
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
