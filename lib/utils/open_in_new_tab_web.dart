import 'dart:html' as html;

Future<void> openImageInNewTab(String url) async {
  // Open in a new tab/window to avoid replacing the current Flutter app tab.
  html.window.open(url, '_blank');
}
