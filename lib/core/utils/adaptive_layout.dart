/// Adaptive layout utilities.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdaptiveLayout {
  AdaptiveLayout._();

  /// Returns `true` when running on a desktop OS (Windows, macOS, Linux).
  static bool get isDesktopOS {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Breakpoint width below which we render the mobile layout.
  static const double mobileBreakpoint = 768;

  /// Returns `true` when the current window width is wide enough for the
  /// desktop (sidebar) layout.
  static bool isWideScreen(double width) => width >= mobileBreakpoint;
}
