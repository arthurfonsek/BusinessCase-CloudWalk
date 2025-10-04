import 'api.dart';

class GamificationService {
  final Api _api = Api();

  /// Carrega estatísticas completas de gamificação do usuário
  Future<Map<String, dynamic>> getGamificationStats() async {
    try {
      final response = await _api.get('/gamification/stats/');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas de gamificação: $e');
    }
  }

  /// Resgata uma recompensa
  Future<Map<String, dynamic>> claimReward(int rewardId) async {
    try {
      final response = await _api.post('/gamification/rewards/claim/', data: {'reward_id': rewardId});
      return response.data;
    } catch (e) {
      throw Exception('Erro ao resgatar recompensa: $e');
    }
  }

  /// Usa uma recompensa resgatada
  Future<Map<String, dynamic>> useReward(int userRewardId) async {
    try {
      final response = await _api.post('/gamification/rewards/use/', data: {'user_reward_id': userRewardId});
      return response.data;
    } catch (e) {
      throw Exception('Erro ao usar recompensa: $e');
    }
  }

  /// Lista todas as conquistas
  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final response = await _api.get('/gamification/achievements/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Erro ao carregar conquistas: $e');
    }
  }

  /// Verifica e desbloqueia conquistas
  Future<Map<String, dynamic>> checkAchievements() async {
    try {
      final response = await _api.post('/gamification/achievements/check/');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao verificar conquistas: $e');
    }
  }

  /// Obtém o ranking de usuários
  Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await _api.get('/gamification/leaderboard/');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao carregar ranking: $e');
    }
  }

  /// Calcula o progresso para o próximo tier
  Map<String, dynamic> calculateTierProgress(int currentReferrals, String currentTier) {
    final tierRequirements = {
      'Iniciante': {'next': 'Bronze', 'required': 3},
      'Bronze': {'next': 'Prata', 'required': 8},
      'Prata': {'next': 'Ouro', 'required': 15},
      'Ouro': {'next': 'Diamante', 'required': 30},
      'Diamante': {'next': null, 'required': 0},
    };

    final tierInfo = tierRequirements[currentTier] ?? {'next': 'Bronze', 'required': 3};
    final required = tierInfo['required'] as int;
    final nextTier = tierInfo['next'] as String?;
    
    final progress = required > 0 ? (currentReferrals / required).clamp(0.0, 1.0) : 1.0;
    final remaining = (required - currentReferrals).clamp(0, required);

    return {
      'progress': progress,
      'current': currentReferrals,
      'required': required,
      'remaining': remaining,
      'nextTier': nextTier,
      'isMaxTier': nextTier == null,
    };
  }

  /// Calcula pontos necessários para uma recompensa
  bool canAffordReward(int userPoints, int rewardCost) {
    return userPoints >= rewardCost;
  }

  /// Formata pontos para exibição
  String formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }

  /// Obtém cor do tier
  String getTierColor(String tierName) {
    const tierColors = {
      'Iniciante': '#8B4513',
      'Bronze': '#CD7F32',
      'Prata': '#C0C0C0',
      'Ouro': '#FFD700',
      'Diamante': '#B9F2FF',
    };
    return tierColors[tierName] ?? '#8B4513';
  }

  /// Obtém ícone do tier
  String getTierIcon(String tierName) {
    const tierIcons = {
      'Iniciante': 'star_border',
      'Bronze': 'star',
      'Prata': 'star_half',
      'Ouro': 'star',
      'Diamante': 'diamond',
    };
    return tierIcons[tierName] ?? 'star_border';
  }

  /// Obtém ícone do tipo de recompensa
  String getRewardIcon(String rewardType) {
    const rewardIcons = {
      'discount': 'local_offer',
      'free_item': 'card_giftcard',
      'premium_feature': 'star',
      'badge': 'military_tech',
    };
    return rewardIcons[rewardType] ?? 'card_giftcard';
  }

  /// Valida se o usuário pode resgatar uma recompensa
  Map<String, dynamic> validateRewardClaim(Map<String, dynamic> userData, Map<String, dynamic> reward) {
    final userPoints = userData['total_points'] ?? 0;
    final rewardCost = reward['points_cost'] ?? 0;
    final userRewards = userData['user_rewards'] as List<dynamic>? ?? [];
    
    final alreadyClaimed = userRewards.any((ur) => ur['reward']['id'] == reward['id']);
    
    if (alreadyClaimed) {
      return {'valid': false, 'message': 'Você já possui esta recompensa'};
    }
    
    if (userPoints < rewardCost) {
      return {'valid': false, 'message': 'Pontos insuficientes'};
    }
    
    return {'valid': true, 'message': 'Recompensa disponível'};
  }
}
