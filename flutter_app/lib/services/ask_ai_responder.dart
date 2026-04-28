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
