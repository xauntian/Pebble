import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AiSearchRequest {
  const AiSearchRequest({
    required this.prompt,
    required this.source,
  });

  final String prompt;
  final AiSearchSource source;
}

enum AiSearchSource { suggestion, typed, voice }

class AiSearchResponse {
  const AiSearchResponse({
    required this.prompt,
    required this.answer,
  });

  final String prompt;
  final String answer;
}

abstract class AskAiResponder {
  Future<AiSearchResponse> ask(AiSearchRequest request);
}

class ApiAskAiResponder implements AskAiResponder {
  const ApiAskAiResponder({
    this.apiKeyAssetPath = 'assets/secrets/ai_search_api_key.txt',
    this.endpoint = 'https://api.deepseek.com/chat/completions',
    this.model = 'deepseek-chat',
  });

  final String apiKeyAssetPath;
  final String endpoint;
  final String model;

  static const _systemPrompt =
      'Answer only questions about water quality. Always reply in English. '
      'If the question is not related to water quality, reply exactly: '
      '"This question is not related to water quality." '
      'Keep the answer concise and under 30 words.';

  @override
  Future<AiSearchResponse> ask(AiSearchRequest request) async {
    final prompt = request.prompt.trim();
    final apiKey = (await rootBundle.loadString(apiKeyAssetPath)).trim();
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.2,
        'max_tokens': 80,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI Search API request failed: ${response.statusCode}');
    }

    return AiSearchResponse(
      prompt: prompt,
      answer: _extractAnswer(response.body),
    );
  }

  String _extractAnswer(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI Search API response is not an object.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('AI Search API response has no choices.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw const FormatException('AI Search API choice is not an object.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('AI Search API choice has no message.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('AI Search API message has no content.');
    }

    return _limitToThirtyWords(content.trim());
  }

  String _limitToThirtyWords(String answer) {
    final words = answer.split(RegExp(r'\s+'));
    if (words.length < 30) {
      return answer;
    }

    return words.take(29).join(' ');
  }
}

class LocalAskAiResponder implements AskAiResponder {
  const LocalAskAiResponder();

  static const Map<String, String> _answers = {
    'how to update water quality ?':
        'Water quality can be updated by testing a new water sample with Pebble. Place the device near or in the water as instructed, wait for the measurement to finish, and the app will refresh the latest result automatically.',
    'what is ph?':
        'pH shows how acidic or basic water is. A value near 7 is neutral, lower values are more acidic, and higher values are more basic. It is useful to read pH alongside other test results.',
  };

  @override
  Future<AiSearchResponse> ask(AiSearchRequest request) async {
    final prompt = request.prompt.trim();
    final answer = request.source == AiSearchSource.voice
        ? 'Waiting for API integration.'
        : _answers[prompt.toLowerCase()] ?? 'Waiting for API integration.';

    return AiSearchResponse(prompt: prompt, answer: answer);
  }
}
