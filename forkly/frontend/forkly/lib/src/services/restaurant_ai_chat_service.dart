import 'api.dart';

class RestaurantAIChatService {
  final Api _api = Api();

  Future<Map<String, dynamic>> startConversation({String? systemPrompt}) async {
    try {
      final response = await _api.post(
        '/ai/chat/start/',
        data: {
          'persona': 'restaurant_owner',
          if (systemPrompt != null && systemPrompt.isNotEmpty) 'system_prompt': systemPrompt,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao iniciar conversa (restaurante): $e');
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
    String? context,
  }) async {
    try {
      final payload = {
        'message': message,
        'persona': 'restaurant_owner',
        if (conversationId != null) 'conversation_id': conversationId,
        if (context != null && context.isNotEmpty) 'context': context,
      };
      final response = await _api.post('/ai/chat/send/', data: payload);
      return response.data;
    } catch (e) {
      throw Exception('Erro ao enviar mensagem (restaurante): $e');
    }
  }
}


