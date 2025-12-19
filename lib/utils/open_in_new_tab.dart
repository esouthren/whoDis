import 'package:flutter/foundation.dart';

// Conditional import: use web implementation on web, otherwise a stub.
import 'package:whodis/utils/open_in_new_tab_stub.dart'
    if (dart.library.html) 'package:whodis/utils/open_in_new_tab_web.dart' as impl;

Future<void> openImageInNewTab(String url) async {
  try {
    await impl.openImageInNewTab(url);
  } catch (e) {
    debugPrint('openImageInNewTab failed: $e');
  }
}
