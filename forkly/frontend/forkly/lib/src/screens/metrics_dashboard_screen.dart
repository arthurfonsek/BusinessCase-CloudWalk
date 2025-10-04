import 'package:flutter/material.dart';
import '../services/api.dart';

class MetricsDashboardScreen extends StatefulWidget {
  const MetricsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  final _api = Api();
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call to get metrics
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock metrics data for demo
      setState(() {
        _metrics = {
          'total_restaurants': 26,
          'total_users': 5,
          'total_reviews': 16,
          'total_lists': 8,
          'total_referrals': 5,
          'ai_search_success_rate': 78.5,
          'referral_funnel': {
            'clicked': 15,
            'registered': 8,
            'first_review': 5,
          },
          'popular_searches': [
            {'query': 'burger', 'count': 12},
            {'query': 'sushi', 'count': 8},
            {'query': 'pizza', 'count': 6},
            {'query': 'cafe', 'count': 4},
          ],
          'top_restaurants': [
            {'name': 'Sushi Master', 'reviews': 8, 'rating': 4.6},
            {'name': 'Outback Steakhouse', 'reviews': 6, 'rating': 4.3},
            {'name': 'Pizza Express', 'reviews': 5, 'rating': 4.2},
          ],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar métricas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas de Sucesso'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadMetrics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar métricas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Search Performance
                  _buildSectionCard(
                    title: '🤖 Performance da IA',
                    icon: Icons.psychology,
                    color: Colors.purple,
                    children: [
                      _buildMetricRow(
                        'Taxa de Sucesso da Busca IA',
                        '${_metrics['ai_search_success_rate']}%',
                        _metrics['ai_search_success_rate'] >= 70 ? Colors.green : Colors.orange,
                        subtitle: 'Meta: ≥70%',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buscas Mais Populares',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_metrics['popular_searches'] as List).map((search) => 
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.search, size: 16, color: Colors.purple[600]),
                                    const SizedBox(width: 8),
                                    Text('${search['query']}', style: TextStyle(color: Colors.purple[700])),
                                    const Spacer(),
                                    Text('${search['count']} buscas', style: TextStyle(color: Colors.purple[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Referral Funnel
                  _buildSectionCard(
                    title: '🔗 Funil de Referência',
                    icon: Icons.share,
                    color: Colors.green,
                    children: [
                      _buildFunnelStep('Clicaram no Link', _metrics['referral_funnel']['clicked'], Colors.blue),
                      _buildFunnelStep('Registraram', _metrics['referral_funnel']['registered'], Colors.orange),
                      _buildFunnelStep('Primeira Avaliação', _metrics['referral_funnel']['first_review'], Colors.green),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Taxa de Conversão: ${((_metrics['referral_funnel']['first_review'] / _metrics['referral_funnel']['clicked']) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Platform Performance
                  _buildSectionCard(
                    title: '📱 Performance Multiplataforma',
                    icon: Icons.phone_android,
                    color: Colors.blue,
                    children: [
                      _buildPlatformCard('Flutter Web', '✅ Funcionando', Colors.green),
                      _buildPlatformCard('Flutter iOS', '✅ Código Único', Colors.blue),
                      _buildPlatformCard('Flutter Android', '✅ Código Único', Colors.blue),
                      _buildPlatformCard('Desktop Linux', '⚠️ Limitado', Colors.orange),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Business Metrics
                  _buildSectionCard(
                    title: '📊 Métricas de Negócio',
                    icon: Icons.business,
                    color: Colors.indigo,
                    children: [
                      _buildMetricRow('Total Restaurantes', '${_metrics['total_restaurants']}', Colors.indigo),
                      _buildMetricRow('Usuários Ativos', '${_metrics['total_users']}', Colors.indigo),
                      _buildMetricRow('Avaliações', '${_metrics['total_reviews']}', Colors.indigo),
                      _buildMetricRow('Listas Criadas', '${_metrics['total_lists']}', Colors.indigo),
                      _buildMetricRow('Referências', '${_metrics['total_referrals']}', Colors.indigo),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Top Restaurants
                  _buildSectionCard(
                    title: '🏆 Top Restaurantes',
                    icon: Icons.star,
                    color: Colors.amber,
                    children: [
                      ...(_metrics['top_restaurants'] as List).map((restaurant) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant, color: Colors.amber[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                    Text(
                                      '${restaurant['reviews']} avaliações • ${restaurant['rating']}⭐',
                                      style: TextStyle(
                                        color: Colors.amber[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(String platform, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              platform,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
