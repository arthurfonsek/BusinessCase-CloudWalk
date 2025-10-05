import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/forkly_logo.dart';
import '../services/auth_service_simple.dart';
import '../widgets/ai_chat_popup.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final Api _api = Api();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  // Forecast config (somente leitura de dados existentes; sem inputs de campanha)
  final int _forecastMonths = 6;
  final double _projectionDecay = 0.85; // decaimento leve mês a mês para projeção

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showSuccessSnackBar = false}) async {
    try {
      setState(() => _isLoading = true);
      final data = await _api.getRestaurantDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
      if (showSuccessSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard atualizado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: const Color(0xFFd60000),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: const Color(0xFFd60000),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar dados',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final restaurant = _dashboardData!['restaurant'];
    final analytics = _dashboardData!['analytics'];
    final monthlyStats = _dashboardData!['monthly_stats'];
    final recentReservations = _dashboardData!['recent_reservations'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard do Restaurante'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadDashboardData(showSuccessSnackBar: true),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair da conta?'),
                  content: const Text('Você tem certeza que deseja sair?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                await _authService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant info card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: const Color(0xFFd60000),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant['name'] ?? 'Nome não informado',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  restaurant['address'] ?? 'Endereço não informado',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFC107),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(double.tryParse(analytics['average_rating']?.toString() ?? '0') ?? 0.0).toStringAsFixed(1)} (${analytics['total_reviews'] ?? 0} avaliações)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Statistics cards
              Text(
                'Estatísticas Gerais',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Reservas Totais',
                      analytics['total_reservations']?.toString() ?? '0',
                      Icons.event_seat,
                      const Color(0xFFd60000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Receita Total',
                      'R\$ ${(double.tryParse(analytics['total_revenue']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                      Icons.payments,
                      const Color(0xFFd60000),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Recomendações',
                      analytics['times_recommended']?.toString() ?? '0',
                      Icons.trending_up,
                      const Color(0xFFd60000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Em Listas',
                      analytics['times_in_lists']?.toString() ?? '0',
                      Icons.format_list_bulleted,
                      const Color(0xFFd60000),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Monthly stats
              Text(
                'Últimos 30 Dias',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _metricValue(monthlyStats['reservations']?.toString() ?? '0'),
                            Text(
                              'Reservas',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _metricValue('R\$ ${(double.tryParse(monthlyStats['revenue']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}'),
                            Text(
                              'Receita',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Forecast & ROI baseado APENAS nos dados atuais (sem campanha)
              _buildListsEffectForecastSection(restaurant, analytics, monthlyStats),

              const SizedBox(height: 24),

              // Recent reservations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reservas Recentes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/reservations'),
                    icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFFd60000)),
                    label: const Text('Ver todas', style: TextStyle(color: Color(0xFFd60000))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (recentReservations.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0x1Ad60000),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.event_note, size: 32, color: Color(0xFFd60000)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma reserva ainda',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quando clientes fizerem reservas, elas aparecerão aqui',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentReservations.take(5).map((reservation) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(reservation['status']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person, color: _getStatusColor(reservation['status']), size: 22),
                    ),
                    title: Text('${reservation['customer_username']}'),
                    subtitle: Text(
                      '${reservation['date']} às ${reservation['time']} - ${reservation['party_size']} pessoas',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(reservation['status']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(reservation['status']),
                        style: TextStyle(
                          color: _getStatusColor(reservation['status']),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reservations');
                      },
                      icon: const Icon(Icons.book_online),
                      label: const Text('Ver Reservas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd60000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRestaurantAI,
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        child: const Icon(Icons.smart_toy),
        tooltip: 'Assistente IA',
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      case 'no_show':
        return 'Não compareceu';
      default:
        return status;
    }
  }

  Widget _metricValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFFd60000),
      ),
    );
  }

  // ===== Forecast/ROI baseado em estar em listas (sem inputs) =====
  Widget _buildListsEffectForecastSection(Map<String, dynamic> restaurant, Map<String, dynamic> analytics, Map<String, dynamic> monthly) {
    final profile = restaurant['profile'] ?? {};
    final avgTicket = (profile['average_ticket'] is num) ? (profile['average_ticket'] as num).toDouble() : 0.0;
    final monthlyRevenue = (monthly['revenue'] is num) ? (monthly['revenue'] as num).toDouble() : 0.0;
    final monthlyReservations = (monthly['reservations'] is num) ? (monthly['reservations'] as num).toDouble() : 0.0;
    final timesInLists = (analytics['times_in_lists'] is num) ? (analytics['times_in_lists'] as num).toDouble() : 0.0;
    final timesRecommended = (analytics['times_recommended'] is num) ? (analytics['times_recommended'] as num).toDouble() : 0.0;

    // Heurística de lift: efeito de listas + recomendações sobre reservas do mês
    // Ajustado para ficar entre 0% e 50% no máximo
    final double k = 200.0; // fator de escala
    final double rawLift = (timesInLists + timesRecommended) / k;
    final double lift = rawLift.clamp(0.0, 0.5);

    final attributedReservations = monthlyReservations * lift;
    final attributedRevenue = avgTicket > 0 ? attributedReservations * avgTicket : monthlyRevenue * lift;

    final forecast = _computeProjectionFromLift(
      baseReservations: monthlyReservations,
      baseRevenue: monthlyRevenue,
      lift: lift,
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.query_stats, color: Color(0xFFd60000)),
                const SizedBox(width: 8),
                Text(
                  'Efeito de Listas e Projeção (6 meses)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildKpi('Reservas (mês)', monthlyReservations.toStringAsFixed(0)),
                _buildKpi('Receita (mês)', 'R\$ ${monthlyRevenue.toStringAsFixed(2)}'),
                _buildKpi('Lift por Listas', '${(lift * 100).toStringAsFixed(1)}%'),
                _buildKpi('Reservas atribuíveis (mês)', attributedReservations.toStringAsFixed(0)),
                _buildKpi('Receita atribuível (mês)', 'R\$ ${attributedRevenue.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _ForecastBarChart(data: forecast),
            ),
            const SizedBox(height: 8),
            Text(
              'Projeção automática baseada no mês atual e exposição em listas (decay ${((_projectionDecay - 1).abs() * 100).toStringAsFixed(0)}%/mês).',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFd60000).withOpacity(0.06),
        border: Border.all(color: const Color(0xFFd60000).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFd60000), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<_ForecastPoint> _computeProjectionFromLift({required double baseReservations, required double baseRevenue, required double lift}) {
    final List<_ForecastPoint> series = [];
    final baselineRevenue = baseRevenue; // baseline = receita do mês atual

    double projectedReservations = baseReservations * (1 + lift);
    double projectedRevenue = baseRevenue * (1 + lift);

    for (int m = 1; m <= _forecastMonths; m++) {
      if (m > 1) {
        projectedReservations *= _projectionDecay;
        projectedRevenue *= _projectionDecay;
      }
      series.add(_ForecastPoint(monthIndex: m, baselineRevenue: baselineRevenue, projectedRevenue: projectedRevenue));
    }
    return series;
  }

  void _openRestaurantAI() {
    final restaurant = _dashboardData?['restaurant'] ?? {};
    final analytics = _dashboardData?['analytics'] ?? {};
    final monthly = _dashboardData?['monthly_stats'] ?? {};

    final contextMessage = '''Contexto: Você é um assistente para o dono de restaurante. Responda de forma objetiva e acionável sobre desempenho do restaurante, reservas, receita, avaliação e insights. Se o usuário pedir um resumo do mês, responda com os números e tendências.

Dados atuais:
- Restaurante: ${restaurant['name'] ?? '-'}
- Avaliação média: ${analytics['average_rating'] ?? '-'} (${analytics['total_reviews'] ?? 0} avaliações)
- Reservas totais: ${analytics['total_reservations'] ?? 0}
- Receita total: ${analytics['total_revenue'] ?? 0}
- Últimos 30 dias: reservas=${monthly['reservations'] ?? 0}, receita=${monthly['revenue'] ?? 0}
''';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AIChatPopup(
          title: 'Assistente do Restaurante',
          subtitle: 'Insights e desempenho do seu restaurante',
          initialContext: contextMessage,
          restaurantMode: true,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFd60000),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.store,
                    color: Color(0xFFd60000),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Olá, ${_authService.currentUser?.name ?? _authService.currentUser?.username ?? 'Restaurante'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.space_dashboard, color: Color(0xFFd60000)),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_online, color: Color(0xFFd60000)),
            title: const Text('Reservas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reservations');
            },
          ),
          // Recompensas removido para restaurantes
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Color(0xFFd60000)),
            title: const Text('Assistente IA'),
            onTap: () {
              Navigator.pop(context);
              _openRestaurantAI();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFd60000)),
            title: const Text('Sair'),
            onTap: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

}

class _ForecastPoint {
  final int monthIndex;
  final double baselineRevenue;
  final double projectedRevenue;
  _ForecastPoint({required this.monthIndex, required this.baselineRevenue, required this.projectedRevenue});
}

class _ForecastBarChart extends StatelessWidget {
  final List<_ForecastPoint> data;
  const _ForecastBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final chartHeight = height - 24; // reserve space for legend
        final barGroupWidth = width / (data.length * 2); // baseline + projected per month

        final maxValue = data
            .map((e) => e.projectedRevenue)
            .fold<double>(0, (a, b) => a > b ? a : b);
        final safeMax = maxValue > 0 ? maxValue : 1;

        Widget legend() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Base', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(0xFFd60000), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Projetado', style: TextStyle(fontSize: 11)),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(height: 20, child: Align(alignment: Alignment.centerRight, child: legend())),
            SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((point) {
                  final baselineH = (point.baselineRevenue / safeMax) * (chartHeight - 24);
                  final projectedH = (point.projectedRevenue / safeMax) * (chartHeight - 24);
                  final projectedLabel = 'R\$ ${point.projectedRevenue.toStringAsFixed(0)}';
                  return SizedBox(
                    width: barGroupWidth * 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(projectedLabel, style: TextStyle(color: Colors.grey[700], fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: barGroupWidth * 0.8,
                                height: baselineH,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: barGroupWidth * 0.8,
                                height: projectedH,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFd60000),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('M${point.monthIndex}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MathUtils {
  static double powd(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
