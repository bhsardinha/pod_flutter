/// Application settings model
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'amp_models.dart'; // Import for AmpNameDisplayMode

/// Application settings
class AppSettings {
  AmpNameDisplayMode ampNameDisplayMode;
  int gridItemsPerRow;
  bool enableTempoScrolling;

  AppSettings({
    this.ampNameDisplayMode = AmpNameDisplayMode.factory,
    this.gridItemsPerRow = 6,
    this.enableTempoScrolling = true,
  });

  /// Load settings from persistent storage
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('amp_name_display_mode') ?? 0;
    final gridItems = prefs.getInt('grid_items_per_row') ?? 6;
    final tempoScrolling = prefs.getBool('enable_tempo_scrolling') ?? true;

    return AppSettings(
      ampNameDisplayMode: AmpNameDisplayMode.values[modeIndex],
      gridItemsPerRow: gridItems.clamp(4, 6),
      enableTempoScrolling: tempoScrolling,
    );
  }

  /// Save settings to persistent storage
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('amp_name_display_mode', ampNameDisplayMode.index);
    await prefs.setInt('grid_items_per_row', gridItemsPerRow);
    await prefs.setBool('enable_tempo_scrolling', enableTempoScrolling);
  }

  /// Get display name for the mode
  static String getModeName(AmpNameDisplayMode mode) {
    switch (mode) {
      case AmpNameDisplayMode.factory:
        return 'Factory Default';
      case AmpNameDisplayMode.realAmp:
        return 'Real Amp Names';
      case AmpNameDisplayMode.both:
        return 'Both Names';
    }
  }

  /// Get description for the mode
  static String getModeDescription(AmpNameDisplayMode mode) {
    switch (mode) {
      case AmpNameDisplayMode.factory:
        return 'Shows Line 6 model names with pack prefix (MS-, CC-, BX-)';
      case AmpNameDisplayMode.realAmp:
        return 'Shows real-world amp manufacturer and model names';
      case AmpNameDisplayMode.both:
        return 'Shows both real name (top) and Line 6 name (bottom)';
    }
  }
}
