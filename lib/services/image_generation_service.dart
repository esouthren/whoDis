import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ImageGenerationService {
  static const String _endpoint = 'https://generatecharacterportrait-vzqbj55nua-uc.a.run.app';

  /// Calls the image generation endpoint with the current user's Firebase auth token.
  /// Returns the imageUrl string on success.
  static Future<String> generateCharacterPortrait({
    required String email,
    required String questionsAndAnswers,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in. Please sign in to generate an image.');
      }

      final idToken = await user.getIdToken(true);
      final uri = Uri.parse(_endpoint);

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
             'data': { 'email': email,
              'questionsAndAnswers': questionsAndAnswers,
            }}),
          )
          .timeout(const Duration(seconds: 45));

      if (resp.statusCode != 200) {
        debugPrint('ImageGenerationService HTTP ${resp.statusCode}: ${resp.body}');
        throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase ?? 'Request failed'}');
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final imageUrl = (decoded['result']['imageUrl'] ?? '').toString();
      if (imageUrl.isEmpty) {
        throw Exception('imageUrl not found in response');
      }

      return imageUrl;
    } catch (e) {
      debugPrint('ImageGenerationService error: $e');
      rethrow;
    }
  }
}
