import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ImageGenerationService {
  static const String _endpoint = 'https://generatecharacterportrait-vzqbj55nua-uc.a.run.app';

  /// Calls the external Cloud Run endpoint with the current user's Firebase auth token.
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

  /// Triggers the Firebase callable to generate and (optionally) save a portrait for a given player
  static Future<void> generateAndSavePortraitForPlayer({
    required String gameId,
    required String playerId,
    required String email,
    required String questionsAndAnswers,
  }) async {
    return generateAndSavePortraitForPlayerFn(
      gameId: gameId,
      playerId: playerId,
      email: email,
      questionsAndAnswers: questionsAndAnswers,
    );
  }
}

/// Top-level wrapper used to avoid static-call issues on some web builds
Future<void> generateAndSavePortraitForPlayerFn({
  required String gameId,
  required String playerId,
  required String email,
  required String questionsAndAnswers,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in.');
    }
    await user.getIdToken(true); // ensure fresh token for callable

    debugPrint('generateAndSavePortraitForPlayer: start gameId=$gameId playerId=$playerId email=$email');
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    // Use the deployed callable name
    final callable = functions.httpsCallable('generateCharacterPortrait');
    final result = await callable
        .call({
          'email': email,
          'questionsAndAnswers': questionsAndAnswers,
          'gameDocumentRef': gameId,
          'playerDocumentId': playerId,
          'playerEmail': email,
        })
        .timeout(const Duration(seconds: 60));

    debugPrint('generateAndSavePortraitForPlayer success: ${result.data}');
  } catch (e) {
    debugPrint('generateAndSavePortraitForPlayer error: $e');
    // Do not rethrow to avoid blocking gameplay; just log
  }
}
