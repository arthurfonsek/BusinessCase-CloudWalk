import 'api.dart';

class AIChatService {
  final Api _api = Api();

  /// Inicia uma nova conversa com IA
  Future<Map<String, dynamic>> startConversation() async {
    try {
      final response = await _api.post('/ai/chat/start/');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao iniciar conversa com IA: $e');
    }
  }

  /// Envia mensagem para IA
  Future<Map<String, dynamic>> sendMessage(String message, {String? conversationId}) async {
    try {
      final data = {
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      };
      final response = await _api.post('/ai/chat/send/', data: data);
      return response.data;
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  /// Lista conversas do usuário
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _api.get('/ai/chat/conversations/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Erro ao carregar conversas: $e');
    }
  }

  /// Obtém conversa específica
  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final response = await _api.get('/ai/chat/conversations/$conversationId/');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar conversa: $e');
    }
  }

  /// Encerra conversa
  Future<void> endConversation(String conversationId) async {
    try {
      await _api.delete('/ai/chat/conversations/$conversationId/end/');
    } catch (e) {
      throw Exception('Erro ao encerrar conversa: $e');
    }
  }

  /// Obtém recomendações da IA
  Future<Map<String, dynamic>> getRecommendations() async {
    try {
      final response = await _api.get('/ai/recommendations/');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar recomendações: $e');
    }
  }

  /// Formata mensagem para exibição
  String formatMessage(String content) {
    // Converter markdown básico para texto formatado
    return content
        .replaceAll('**', '') // Remove bold markdown
        .replaceAll('*', '') // Remove italic markdown
        .replaceAll('#', '') // Remove headers
        .trim();
  }

  /// Extrai emojis de uma mensagem
  List<String> extractEmojis(String content) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    return emojiRegex.allMatches(content).map((match) => match.group(0)!).toList();
  }

  /// Verifica se mensagem contém recomendações
  bool isRecommendationMessage(String content) {
    final recommendationKeywords = [
      'recomendo', 'sugiro', 'dica', 'dicas', 'como', 'para', 'melhorar',
      'progredir', 'avançar', 'tier', 'pontos', 'referrals'
    ];
    
    final lowerContent = content.toLowerCase();
    return recommendationKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  /// Extrai ações sugeridas da mensagem
  List<String> extractSuggestedActions(String content) {
    final actionKeywords = [
      'compartilhar', 'convidar', 'resgatar', 'ver', 'usar', 'ganhar',
      'completar', 'desbloquear', 'participar'
    ];
    
    final lowerContent = content.toLowerCase();
    return actionKeywords.where((action) => lowerContent.contains(action)).toList();
  }
}
