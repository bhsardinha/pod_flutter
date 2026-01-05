/// Application settings model
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'amp_models.dart'; // Import for AmpNameDisplayMode

/// Application settings
class AppSettings {
  AmpNameDisplayMode ampNameDisplayMode;

  AppSettings({
    this.ampNameDisplayMode = AmpNameDisplayMode.factory,
  });

  /// Load settings from persistent storage
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('amp_name_display_mode') ?? 0;

    return AppSettings(
      ampNameDisplayMode: AmpNameDisplayMode.values[modeIndex],
    );
  }

  /// Save settings to persistent storage
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('amp_name_display_mode', ampNameDisplayMode.index);
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
