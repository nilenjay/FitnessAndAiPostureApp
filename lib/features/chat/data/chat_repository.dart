import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class ChatRepository {
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.groq.com',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConstants.groqApiKey}',
    },
  ));

  /// Sends the conversation so far and returns the AI's reply text.
  Future<String> sendMessage({
    required List<Map<String, String>> conversationHistory,
  }) async {
    final response = await _dio.post(
      '/openai/v1/chat/completions',
      data: {
        'model': AppConstants.groqModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a knowledgeable and friendly AI fitness coach. '
                'Answer questions about workouts, nutrition, recovery, posture, '
                'and overall health. Keep answers concise and actionable. '
                'Use bullet points when listing multiple items.',
          },
          ...conversationHistory,
        ],
        'temperature': 0.7,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String? ?? '';
  }
}
