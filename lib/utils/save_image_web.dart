import 'dart:html' as html;

Future<void> saveImageFromUrl(String url, {String? fileName}) async {
  final anchor = html.AnchorElement(href: url);
  if (fileName != null && fileName.isNotEmpty) {
    anchor.download = fileName;
  }
  anchor.style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
