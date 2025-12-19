import 'package:flutter/foundation.dart';

Future<void> openImageInNewTab(String url) async {
  // Non-web platforms: no-op with a log.
  debugPrint('openImageInNewTab is only supported on web. URL: $url');
}
