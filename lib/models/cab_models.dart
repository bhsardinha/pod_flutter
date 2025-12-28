/// Cabinet model definitions for POD XT Pro
/// Extracted from pod-ui mod-xt/src/config.rs

library;

/// Cabinet model with ID and display name
class CabModel {
  final int id;
  final String name;
  final String? pack;

  const CabModel(this.id, this.name, [this.pack]);

  bool get isStock => pack == null;
}

/// All available cabinet models
class CabModels {
  static const List<CabModel> all = [
    // Stock cabs (IDs 0-24)
    CabModel(0, 'No Cab'),
    CabModel(1, '1x6 Super O'),
    CabModel(2, '1x8 Tweed'),
    CabModel(3, '1x10 Gibtone'),
    CabModel(4, '1x10 G-Band'),
    CabModel(5, '1x12 Line 6'),
    CabModel(6, '1x12 Tweed'),
    CabModel(7, '1x12 Blackface'),
    CabModel(8, '1x12 Class A'),
    CabModel(9, '2x2 Mini T'),
    CabModel(10, '2x12 Line 6'),
    CabModel(11, '2x12 Blackface'),
    CabModel(12, '2x12 Match'),
    CabModel(13, '2x12 Jazz'),
    CabModel(14, '2x12 Class A'),
    CabModel(15, '4x10 Line 6'),
    CabModel(16, '4x10 Tweed'),
    CabModel(17, '4x12 Line 6'),
    CabModel(18, '4x12 Green 20\'s'),
    CabModel(19, '4x12 Green 25\'s'),
    CabModel(20, '4x12 Brit T75'),
    CabModel(21, '4x12 Brit V30\'s'),
    CabModel(22, '4x12 Treadplate'),
    CabModel(23, '1x15 Thunder'),
    CabModel(24, '2x12 Wishbook'),

    // BX Pack (IDs 25-46)
    CabModel(25, '1x12 Boutique', 'BX'),
    CabModel(26, '1x12 Motor City', 'BX'),
    CabModel(27, '1x15 Flip Top', 'BX'),
    CabModel(28, '1x15 Jazz Tone', 'BX'),
    CabModel(29, '1x18 Session', 'BX'),
    CabModel(30, '1x18 Amp 360', 'BX'),
    CabModel(31, '1x18 California', 'BX'),
    CabModel(32, '1x18+12 Stadium', 'BX'),
    CabModel(33, '2x10 Modern UK', 'BX'),
    CabModel(34, '2x15 Double Show', 'BX'),
    CabModel(35, '2x15 California', 'BX'),
    CabModel(36, '2x15 Class A', 'BX'),
    CabModel(37, '4x10 Line 6', 'BX'),
    CabModel(38, '4x10 Tweed', 'BX'),
    CabModel(39, '4x10 Adam Eve', 'BX'),
    CabModel(40, '4x10 Silvercone', 'BX'),
    CabModel(41, '4x10 Session', 'BX'),
    CabModel(42, '4x12 Hiway', 'BX'),
    CabModel(43, '4x12 Green 20\'s', 'BX'),
    CabModel(44, '4x12 Green 25\'s', 'BX'),
    CabModel(45, '4x15 Big Boy', 'BX'),
    CabModel(46, '8x10 Classic', 'BX'),
  ];

  static CabModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }

  static List<CabModel> get stock => all.where((c) => c.isStock).toList();
}

/// Microphone models
class MicModel {
  final int id;
  final String name;
  final String? pack;

  const MicModel(this.id, this.name, [this.pack]);
}

class MicModels {
  static const List<MicModel> all = [
    // Stock mics
    MicModel(0, '57 On Axis'),
    MicModel(1, '57 Off Axis'),
    MicModel(2, '421 Dynamic'),
    MicModel(3, '67 Condenser'),
    // BX Pack
    MicModel(4, 'Tube 47 Close', 'BX'),
    MicModel(5, 'Tube 47 Far', 'BX'),
    MicModel(6, '112 Dynamic', 'BX'),
    MicModel(7, '20 Dynamic', 'BX'),
  ];

  static MicModel? byId(int id) {
    if (id < 0 || id >= all.length) return null;
    return all[id];
  }
}
