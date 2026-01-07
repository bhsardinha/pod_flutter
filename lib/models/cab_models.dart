/// Cabinet model definitions for POD XT Pro
/// Based on official POD XT Models reference (page 2 POD.pdf)

library;

/// Cabinet model with ID and display name
class CabModel {
  final int id;
  final String name;
  final String? pack;
  final String? realName; // Real-world cabinet name

  const CabModel(this.id, this.name, [this.pack, this.realName]);

  bool get isStock => pack == null;
}

/// All available cabinet models
class CabModels {
  static const List<CabModel> all = [
    // Stock Guitar Cabs (IDs 0-24)
    CabModel(0, 'No Cab'),
    CabModel(1, '1x6 Super O', null, '1960s Supro S6616 (6x9)'),
    CabModel(2, '1x8 Tweed', null, '1961 Fender Tweed Champ'),
    CabModel(3, '1x10 Gibtone', null, '1959 Gibson 1x10'),
    CabModel(4, '1x10 G-Brand', null, '1960 Gretsch 6156'),
    CabModel(5, '1x12 Line 6', null, 'Line 6 1x12'),
    CabModel(6, '1x12 Tweed', null, '1953 Fender Tweed Deluxe Reverb'),
    CabModel(7, '1x12 Blackface', null, '1964 Fender Blackface Deluxe'),
    CabModel(8, '1x12 Class A', null, '1960 Vox AC-15'),
    CabModel(9, '2x2 Mini T', null, 'Fender Mini Twin (2x2")'),
    CabModel(10, '2x12 Line 6', null, 'Line 6 2x12'),
    CabModel(11, '2x12 Blackface', null, '1965 Fender Blackface Twin Reverb'),
    CabModel(12, '2x12 Match', null, '1995 Matchless Chieftain'),
    CabModel(13, '2x12 Jazz', null, '1987 Roland JC-120'),
    CabModel(14, '2x12 Class A', null, '1967 Vox AC-30'),
    CabModel(15, '4x10 Line 6', null, 'Line 6 4x10'),
    CabModel(16, '4x10 Tweed', null, '1959 Fender Bassman'),
    CabModel(17, '4x12 Line 6', null, 'Line 6 4x12'),
    CabModel(18, '4x12 Green 20\'s', null, '1967 Marshall Basketweave (Greenbacks)'),
    CabModel(19, '4x12 Green 25\'s', null, '1968 Marshall Basketweave (Greenbacks)'),
    CabModel(20, '4x12 Brit T75', null, '1978 Marshall (Celestion T-75)'),
    CabModel(21, '4x12 Brit V30\'s', null, '1996 Marshall (Vintage 30s)'),
    CabModel(22, '4x12 Treadplate', null, 'Mesa/Boogie 4x12'),
    CabModel(23, '1x15 Thunder', null, '1962 Supro Thunderbolt'),
    CabModel(24, '2x12 Wishbook', null, '1967 Silvertone Twin Twelve'),

    // Bass Expansion Cabs (IDs 25-46)
    CabModel(25, '1x12 Boutique', 'BX', 'Euphonics CXL-112L'),
    CabModel(26, '1x12 Motor City', 'BX', 'Versatone Pan-O-Flex'),
    CabModel(27, '1x15 Flip Top', 'BX', 'Ampeg B-15'),
    CabModel(28, '1x15 Jazz Tone', 'BX', 'Polytone Minibrute'),
    CabModel(29, '1x18 Session', 'BX', 'SWR Big Ben'),
    CabModel(30, '1x18 Amp 360', 'BX', 'Acoustic 360'),
    CabModel(31, '1x18 California', 'BX', 'Mesa/Boogie 1x18'),
    CabModel(32, '1x18+12 Stadium', 'BX', 'Sunn Coliseum'),
    CabModel(33, '2x10 Modern UK', 'BX', 'Ashdown ABM 210T'),
    CabModel(34, '2x15 Doubleshow', 'BX', 'Fender Dual Showman D130F'),
    CabModel(35, '2x15 California', 'BX', 'Mesa/Boogie 2x15'),
    CabModel(36, '2x15 Class A', 'BX', 'Vox AC-100'),
    CabModel(37, '4x10 Line 6', 'BX', 'Line 6 4x10'),
    CabModel(38, '4x10 Tweed', 'BX', 'Fender Bassman Combo (new speakers)'),
    CabModel(39, '4x10 Adam Eve', 'BX', 'Fender Bassman Combo'),
    CabModel(40, '4x10 Silvercone', 'BX', 'Hartke 410'),
    CabModel(41, '4x10 Session', 'BX', 'David Eden 4x10'),
    CabModel(42, '4x12 Hiway', 'BX', 'Hiwatt Bass Cab'),
    CabModel(43, '4x12 Green 20\'s', 'BX', '1967 Marshall Basketweave (Greenbacks)'),
    CabModel(44, '2x12 Green 25\'s', 'BX', '1968 Marshall Basketweave (Greenbacks)'),
    CabModel(45, '4x15 Big Boy', 'BX', 'Marshall Major'),
    CabModel(46, '8x10 Classic', 'BX', 'Ampeg SVT'),
  ];

  static CabModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }

  static List<CabModel> get stock => all.where((c) => c.isStock).toList();
}

/// Microphone models
/// POD always uses positions 0-3, but the mic names differ based on cab type
class MicModel {
  final int position; // Always 0-3
  final String name;
  final String? realName; // Real-world microphone name

  const MicModel(this.position, this.name, [this.realName]);
}

class MicModels {
  /// Guitar cabinet mics (positions 0-3)
  static const List<MicModel> guitar = [
    MicModel(0, '57 On Axis', 'Shure SM57 (on-axis)'),
    MicModel(1, '57 Off Axis', 'Shure SM57 (off-axis)'),
    MicModel(2, '421 Dynamic', 'Sennheiser MD 421'),
    MicModel(3, '67 Condenser', 'Neumann U67'),
  ];

  /// Bass cabinet mics (positions 0-3)
  static const List<MicModel> bass = [
    MicModel(0, 'Tube 47 Close', 'Neumann U47 (close mic\'d)'),
    MicModel(1, 'Tube 47 Far', 'Neumann U47 (distant mic\'d)'),
    MicModel(2, '112 Dynamic', 'AKG D-112'),
    MicModel(3, '20 Dynamic', 'Electro-Voice RE-20'),
  ];

  /// Get mic by position for the appropriate cab type
  static MicModel? byPosition(int position, {required bool isBass}) {
    final list = isBass ? bass : guitar;
    if (position < 0 || position >= list.length) return null;
    return list[position];
  }

  /// Get the appropriate mic list based on cab type
  static List<MicModel> forCabType({required bool isBass}) {
    return isBass ? bass : guitar;
  }
}
