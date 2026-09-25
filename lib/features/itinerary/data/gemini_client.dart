import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiException implements Exception {
  GeminiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'GeminiException(${statusCode ?? '-'}): $message';
}

/// Minimal client for the Gemini API `generateContent` endpoint with JSON
/// (structured) output. Free tier: https://aistudio.google.com
class GeminiClient {
  GeminiClient({
    required this.apiKey,
    required this.model,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;
  final Duration timeout;

  Uri get endpoint =>
      Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent');

  /// Sends [prompt] with [system] instructions and returns the model's JSON
  /// text, constrained by [schema] (OpenAPI-style subset used by Gemini).
  Future<String> generateJson({
    required String system,
    required String prompt,
    required Map<String, dynamic> schema,
    double temperature = 0.4,
  }) async {
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': schema,
        'temperature': temperature,
        'maxOutputTokens': 2048,
      },
    };

    final http.Response res;
    try {
      res = await _client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (e) {
      throw GeminiException('Network error: $e');
    }

    final decoded = _tryDecode(res.body);
    if (res.statusCode != 200) {
      final message = (decoded?['error'] as Map<String, dynamic>?)?['message'] as String? ?? res.reasonPhrase ?? '';
      throw GeminiException(message, statusCode: res.statusCode);
    }
    final blocked = (decoded?['promptFeedback'] as Map<String, dynamic>?)?['blockReason'];
    if (blocked != null) throw GeminiException('Prompt blocked: $blocked');

    final candidates = decoded?['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) throw GeminiException('No candidates in response');
    final parts = ((candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?)?['parts'] as List?;
    final text = [
      for (final p in parts ?? const []) (p as Map<String, dynamic>)['text'] as String? ?? '',
    ].join();
    if (text.trim().isEmpty) throw GeminiException('Empty response');
    return text;
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
