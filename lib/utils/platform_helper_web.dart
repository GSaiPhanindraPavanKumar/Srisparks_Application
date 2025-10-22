import 'package:flutter_web_plugins/url_strategy.dart';
import 'dart:html' as html;

class PlatformHelper {
  static void usePathUrlStrategy() {
    setUrlStrategy(PathUrlStrategy());
  }

  static void logCurrentUrl() {
    print('Current URL: ${html.window.location.href}');
  }
}
