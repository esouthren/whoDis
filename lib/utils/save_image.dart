import 'package:flutter/foundation.dart';

import 'package:whodis/utils/save_image_stub.dart'
  if (dart.library.html) 'package:whodis/utils/save_image_web.dart' as impl;

Future<void> saveImageFromUrl(String url, {String? fileName}) async {
  try {
    await impl.saveImageFromUrl(url, fileName: fileName);
  } catch (e) {
    debugPrint('saveImageFromUrl failed: $e');
    rethrow;
  }
}
