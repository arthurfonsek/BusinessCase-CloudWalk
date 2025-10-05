import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../services/api.dart';
import '../services/auth_service_simple.dart';
import '../services/gamification_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/ai_chat_popup.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with TickerProviderStateMixin {
  final Api _api = Api();
  final AuthService _authService = AuthService();
  final GamificationService _gamificationService = GamificationService();
  
  late TabController _tabController;
  Map<String, dynamic>? _gamificationData;
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _ledger = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadGamificationData();
    _loadLedger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLedger() async {
    if (!_authService.isAuthenticated) return;
    try {
      final data = await _gamificationService.getLedger();
      if (mounted) setState(() => _ledger = data);
    } catch (e) {
      // Mantém silencioso na primeira carga; pode exibir erro sob demanda
    }
  }

  Future<void> _loadGamificationData() async {
    if (!_authService.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _error = 'Você precisa fazer login para ver suas recompensas';
      });
      return;
    }

    try {
      final data = await _gamificationService.getGamificationStats();
      setState(() {
        _gamificationData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _claimReward(int rewardId) async {
    try {
      await _gamificationService.claimReward(rewardId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recompensa resgatada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadGamificationData(); // Recarregar dados
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resgatar recompensa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareReferralCode() async {
    if (_gamificationData == null) return;
    
    final userProfile = _gamificationData!['user_tier'];
    final code = userProfile['referral_code'] ?? 'DEMO123';
    final link = "https://forkly.app/invite?code=$code";
    
    await Share.share(
      "🍴 Junte-se a mim no Forkly! Use meu código: $code\n$link\n\nDescubra os melhores restaurantes e ganhe pontos indicando amigos!",
      subject: "Convite para o Forkly"
    );
  }

  void _openAIChat() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: const AIChatPopup(),
      ),
    );
  }


  Widget _buildTierCard() {
    if (_gamificationData == null) return const SizedBox();
    
    final userTier = _gamificationData!['user_tier'];
    final tierName = userTier['tier_name'] ?? 'Iniciante';
    // Use a rich golden color for Gold tier
    final tierColor = tierName == 'Ouro' 
        ? const Color(0xFFDAA520) // Goldenrod - rich gold with good readability
        : Color(int.parse(userTier['tier_color']?.replaceAll('#', '0xFF') ?? '0xFF8B4513'));
    final currentReferrals = userTier['current_referrals'] ?? 0;
    final totalPoints = userTier['total_points'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTierIcon(tierName),
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier $tierName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$currentReferrals indicações • $totalPoints pontos',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(currentReferrals, tierName),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final userTier = _gamificationData!['user_tier'];
    final totalPoints = userTier['total_points'] ?? 0;
    final currentReferrals = userTier['current_referrals'] ?? 0;
    final claimedRewards = _gamificationData!['claimed_rewards']?.length ?? 0;
    final achievements = _gamificationData!['achievements']?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.stars,
                label: 'Pontos',
                value: totalPoints.toString(),
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.people,
                label: 'Indicações',
                value: currentReferrals.toString(),
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.card_giftcard,
                label: 'Recompensas',
                value: claimedRewards.toString(),
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Conquistas',
                value: achievements.toString(),
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int currentReferrals, String tierName) {
    final nextTierRequirements = _getNextTierRequirements(tierName);
    final progress = nextTierRequirements > 0 ? (currentReferrals / nextTierRequirements).clamp(0.0, 1.0) : 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso para o próximo tier',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white30,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          nextTierRequirements > 0 
            ? '$currentReferrals / $nextTierRequirements indicações'
            : 'Tier máximo alcançado!',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _getNextTierRequirements(String currentTier) {
    switch (currentTier) {
      case 'Iniciante': return 3;
      case 'Bronze': return 8;
      case 'Prata': return 15;
      case 'Ouro': return 30;
      default: return 0;
    }
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName) {
      case 'Iniciante': return Icons.star_border;
      case 'Bronze': return Icons.star;
      case 'Prata': return Icons.star_half;
      case 'Ouro': return Icons.star;
      case 'Diamante': return Icons.diamond;
      default: return Icons.star_border;
    }
  }

  Widget _buildReferralSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Convide Amigos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFd60000),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ganhe pontos indicando amigos:\n• +50 pontos quando se registram\n• +100 pontos quando fazem primeira avaliação',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveButton(
            text: 'Compartilhar Código',
            onPressed: _shareReferralCode,
            icon: Icons.share,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsGrid() {
    if (_gamificationData == null) return const SizedBox();
    
    final availableRewards = _gamificationData!['available_rewards'] as List<dynamic>? ?? [];
    final userRewards = _gamificationData!['user_rewards'] as List<dynamic>? ?? [];
    final userPoints = _gamificationData!['user_tier']['total_points'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recompensas Disponíveis',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFd60000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$userPoints pontos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // More bottom padding
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Force 3 columns for better readability
              childAspectRatio: 0.65, // Even more compact
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableRewards.length,
            itemBuilder: (context, index) {
              final reward = availableRewards[index];
              final canAfford = userPoints >= (reward['points_cost'] ?? 0);
              final isClaimed = userRewards.any((ur) => ur['reward']['id'] == reward['id']);
              
              return _buildRewardCard(reward, canAfford, isClaimed);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward, bool canAfford, bool isClaimed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimed ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimed ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRewardIcon(reward['reward_type']),
                color: isClaimed ? Colors.green : const Color(0xFFd60000),
                size: 24,
              ),
              const Spacer(),
              if (isClaimed)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reward['name'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            reward['description'] ?? '',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isClaimed 
                ? Colors.green 
                : canAfford 
                  ? const Color(0xFFd60000) 
                  : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isClaimed 
                ? 'Resgatado' 
                : '${reward['points_cost']} pts',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          if (!isClaimed && canAfford)
            const SizedBox(height: 2),
          if (!isClaimed && canAfford)
            SizedBox(
              width: double.infinity,
              child: ResponsiveButton(
                text: 'Resgatar',
                onPressed: () => _claimReward(reward['id']),
                backgroundColor: const Color(0xFFd60000),
                textColor: Colors.white,
                borderRadius: 3,
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case 'discount': return Icons.local_offer;
      case 'free_item': return Icons.card_giftcard;
      case 'premium_feature': return Icons.star;
      case 'badge': return Icons.military_tech;
      default: return Icons.card_giftcard;
    }
  }

  int _getCrossAxisCount() {
    if (kIsWeb) return 4;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return 3;
    return 2;
  }

  Widget _buildAchievementsList() {
    if (_gamificationData == null) return const SizedBox();
    
    final achievements = _gamificationData!['achievements'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Conquistas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (achievements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Nenhuma conquista desbloqueada ainda',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
      ],
    );
  }

  Widget _buildLedgerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Histórico de Pontos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_ledger.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Nenhum lançamento ainda',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ledger.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final it = _ledger[index];
              final reason = (it['reason'] ?? '').toString();
              final points = (it['points'] ?? 0) as int;
              final createdAt = (it['created_at'] ?? '').toString();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFd60000).withOpacity(0.1),
                  child: Icon(
                    points >= 0 ? Icons.add : Icons.remove,
                    color: const Color(0xFFd60000),
                  ),
                ),
                title: Text(_formatReason(reason)),
                subtitle: Text(_formatDate(createdAt)),
                trailing: Text(
                  points >= 0 ? '+$points' : '$points',
                  style: TextStyle(
                    color: points >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatReason(String r) {
    switch (r) {
      case 'invite_registered':
        return 'Indicação registrada';
      case 'invite_first_review':
        return 'Primeira avaliação do indicado';
      case 'achievement_unlocked':
        return 'Conquista desbloqueada';
      case 'reward_claimed':
        return 'Resgate de recompensa';
      default:
        return r.replaceAll('_', ' ');
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFd60000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.emoji_events,
              color: const Color(0xFFd60000),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['achievement_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['achievement_description'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (achievement['points_reward'] > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${achievement['points_reward']} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFd60000)),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recompensas'),
          backgroundColor: const Color(0xFFd60000),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ResponsiveButton(
                text: 'Tentar Novamente',
                onPressed: _loadGamificationData,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recompensas'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tier', icon: Icon(Icons.star)),
            Tab(text: 'Indicar', icon: Icon(Icons.share)),
            Tab(text: 'Recompensas', icon: Icon(Icons.card_giftcard)),
            Tab(text: 'Conquistas', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Histórico', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Tier
          SingleChildScrollView(
            child: Column(
              children: [
                _buildTierCard(),
                _buildReferralSection(),
              ],
            ),
          ),
          // Tab Indicar
          SingleChildScrollView(
            child: _buildReferralSection(),
          ),
          // Tab Recompensas
          _buildRewardsGrid(),
          // Tab Conquistas
          _buildAchievementsList(),
          // Tab Extrato
          SingleChildScrollView(child: _buildLedgerList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAIChat,
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        child: const Icon(Icons.smart_toy),
        tooltip: 'Assistente IA',
      ),
    );
  }
}
