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
    AmpModel(10, 'Zen Master', null, '2001 Budda Twinmaster 2x12'),
    AmpModel(11, 'Small Tweed', null, '1953 Fender Tweed Deluxe (Wide Panel)'),
    AmpModel(12, 'Tweed B-Man', null, '1958 Fender Bassman 4x10'),
    AmpModel(13, 'Tiny Tweed', null, '1960 Fender Tweed Champ'),
    AmpModel(14, 'Blackface Lux', null, '1964 Fender Deluxe Reverb (Normal Ch, Input 1)'),
    AmpModel(15, 'Double Verb', null, '1965 Fender Twin Reverb (Normal Ch, Input 1)'),
    AmpModel(16, 'Two-Tone', null, '1960 Gretsch 6156'),
    AmpModel(17, 'Hiway 100', null, '1973 Hiwatt DR-103'),
    AmpModel(18, 'Plexi 45', null, '1965 Marshall JTM-45 (Block Logo)'),
    AmpModel(19, 'Plexi Lead 100', null, '1968 Marshall Plexi Super Lead'),
    AmpModel(20, 'Plexi Jump Lead', null, '1968 Marshall Plexi Super Lead (Ch I+II Jumpered)'),
    AmpModel(21, 'Plexi Variac', null, '1968 Marshall Super Lead (High Voltage via Variac)'),
    AmpModel(22, 'Brit J-800', null, '1990 Marshall JCM-800'),
    AmpModel(23, 'Brit JM Pre', null, '1996 Marshall JMP-1'),
    AmpModel(24, 'Match Chief', null, '1996 Matchless Chieftain'),
    AmpModel(25, 'Match D-30', null, '1993 Matchless DC-30'),
    AmpModel(
      26,
      'Treadplate Dual',
      null,
      '2001 Mesa/Boogie Dual Rectifier Solo Head (Ch 3)',
    ),
    AmpModel(27, 'Cali Crunch', null, '1985 Mesa/Boogie Mark II-C+ (Drive Ch)'),
    AmpModel(28, 'Jazz Clean', null, '1987 Roland JC-120'),
    AmpModel(29, 'Solo 100', null, '1993 Soldano SLO-100'),
    AmpModel(30, 'Super O', null, '1960s Supro S6616'),
    AmpModel(31, 'Class A-15', null, '1960 Vox AC-15 (Ch 1)'),
    AmpModel(32, 'Class A-30 TB', null, '1967 Vox AC-30 Top Boost'),
    AmpModel(33, 'Line 6 Agro'),
    AmpModel(34, 'Line 6 Lunatic'),
    AmpModel(35, 'Line 6 Treadplate'),
    AmpModel(36, 'Line 6 Variax Acoustic'),

    // Metal Shop Amp Expansion (IDs 37-54)
    AmpModel(37, 'Bomber Uber', 'MS', '2002 Bogner Uberschall'),
    AmpModel(38, 'Connor 50', 'MS', '2003 Cornford mk50h'),
    AmpModel(39, 'Deity Lead', 'MS', '2003 Diezel VH4 (Ch 4)'),
    AmpModel(40, 'Deity\'s Son', 'MS', '2003 Diezel Herbert'),
    AmpModel(41, 'Angel P-Ball', 'MS', '2002 ENGL Powerball (Ch 2 Soft Lead)'),
    AmpModel(42, 'Brit Sliver', 'MS', '1987 Marshall Silver Jubilee'),
    AmpModel(43, 'Brit J-900 Cln', 'MS', '1992 Marshall JCM-900 (Clean Ch)'),
    AmpModel(44, 'Brit J-900 Dst', 'MS', '1992 Marshall JCM-900 (Lead Ch)'),
    AmpModel(45, 'Brit J-2000', 'MS', '2003 Marshall JCM 2000 (OD2 Ch)'),
    AmpModel(46, 'Diamondplate', 'MS', '2001 Mesa/Boogie Triple Rectifier (Ch 3)'),
    AmpModel(47, 'Criminal', 'MS', '2002 Peavey 5150 MkII (Lead Ch)'),
    AmpModel(48, 'Line 6 Big Bottom', 'MS'),
    AmpModel(49, 'Line 6 Chunk Chunk', 'MS'),
    AmpModel(50, 'Line 6 Fuzz', 'MS'),
    AmpModel(51, 'Line 6 Octone', 'MS'),
    AmpModel(52, 'Line 6 Smash', 'MS'),
    AmpModel(53, 'Line 6 Sparkle Clean', 'MS'),
    AmpModel(54, 'Line 6 Throttle', 'MS'),

    // Collector's Classic Amp Expansion (IDs 55-72)
    AmpModel(55, 'Bomber X-TC', 'CC', '2002 Bogner Ecstasy'),
    AmpModel(56, 'Deity Crunch', 'CC', '2003 Diezel VH4 (Ch 3)'),
    AmpModel(57, 'Blackface Vibro', 'CC', '1963 Fender Vibroverb 6G16 2x10'),
    AmpModel(58, 'Double Show', 'CC', '1967 Fender Dual Showman'),
    AmpModel(59, 'Silverface Bass', 'CC', '1972 Fender Bassman Head (2x15 w/ JBL)'),
    AmpModel(60, 'Mini Double', 'CC', '1996 Fender Mini-Twin (2x2")'),
    AmpModel(61, 'Gibtone Expo', 'CC', '1960 Gibson GA-18T Explorer (14W, 10")'),
    AmpModel(62, 'Brit Bass', 'CC', '1968 Marshall Plexi Super Bass (Input I)'),
    AmpModel(63, 'Brit Major', 'CC', '1969 Marshall Major (Input I, 200W)'),
    AmpModel(64, 'Silver Twelve', 'CC', '1967 Silvertone Twin Twelve'),
    AmpModel(65, 'Super O Thunder', 'CC', '1962 Supro Thunderbolt (1x15)'),
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
    AmpModel(81, 'Amp 360', 'BX', '1972 Acoustic 360'),
    AmpModel(82, 'Jaguar', 'BX', '2003 Aguilar DB750'),
    AmpModel(83, 'Alchemist', 'BX', '1975 Alembic F-2B Preamp'),
    AmpModel(84, 'Rock Classic', 'BX', '1974 Ampeg SVT (w/ 1970s 8x10)'),
    AmpModel(85, 'Flip Top', 'BX', '1968 Ampeg B-15 Portaflex'),
    AmpModel(86, 'Adam and Eve', 'BX', '1998 Eden Traveller WT-300'),
    AmpModel(87, 'Tweed B-Man', 'BX', '1958 Fender Bassman 4x10'),
    AmpModel(88, 'Silverface Bass', 'BX', '1967 Fender Bassman Head (2x15 w/ JBL)'),
    AmpModel(89, 'Double Show', 'BX', '1967 Fender Dual Showman'),
    AmpModel(90, 'Eighties', 'BX', '1989 Gallien-Krueger 800RB'),
    AmpModel(91, 'Hiway 100', 'BX', '1973 Hiwatt DR-103'),
    AmpModel(92, 'Hiway 200', 'BX', '1971 Hiwatt 200DR'),
    AmpModel(93, 'Brit Major', 'BX', '1969 Marshall Major (w/ 1976 4x15)'),
    AmpModel(94, 'Brit Bass', 'BX', '1968 Marshall Plexi Super Bass'),
    AmpModel(95, 'California', 'BX', '2003 Mesa/Boogie Bass 400+'),
    AmpModel(96, 'Jazz Tone', 'BX', '1998 Polytone Minibrute (1x15)'),
    AmpModel(97, 'Stadium', 'BX', '1978 Sunn Coliseum 300'),
    AmpModel(98, 'Studio Tone', 'BX', '2002 SWR SM-500'),
    AmpModel(99, 'Motor City', 'BX', '1967 Versatone Pan-O-Flex (1x12)'),
    AmpModel(100, 'Brit Class A100', 'BX', '1965 Vox AC-100'),

    // Additional Standard Models (IDs 101-106)
    AmpModel(101, 'Citrus D-30', null, '2005 Orange AD30TC (30W Class A)'),
    AmpModel(102, 'Line 6 Modern Hi Gain', null, 'Soldano X88R Preamp'),
    AmpModel(
      103,
      'Line 6 Boutique #1',
      null,
      'Dumble Overdrive Special (Clean Ch)',
    ),
    AmpModel(104, 'Class A-30 Fawn', null, 'Vox AC-30 (Normal Ch, Non Top Boost)'),
    AmpModel(105, 'Brit Gain 18', null, 'Marshall 1974X (1974 18W Reissue)'),
    AmpModel(106, 'Brit J-2000 #2', null, '2003 Marshall JCM2000 (w/ Germ Pedal)'),
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
