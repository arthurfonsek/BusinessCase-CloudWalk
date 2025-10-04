import 'package:flutter/material.dart';
import '../services/lists_service.dart';
import '../services/api.dart';

class PopularRestaurantsScreen extends StatefulWidget {
  const PopularRestaurantsScreen({Key? key}) : super(key: key);

  @override
  State<PopularRestaurantsScreen> createState() => _PopularRestaurantsScreenState();
}

class _PopularRestaurantsScreenState extends State<PopularRestaurantsScreen> {
  final ListsService _listsService = ListsService();
  final Api _api = Api();
  List<Map<String, dynamic>> _popularRestaurants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPopularRestaurants();
  }

  Future<void> _loadPopularRestaurants() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar se já está autenticado
      if (!_api.isAuthenticated) {
        print('Não está autenticado, mostrando mensagem...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa fazer login primeiro para ver restaurantes populares'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _popularRestaurants = []);
        return;
      }
      
      print('Usuário autenticado, carregando restaurantes populares...');
      // Carregar restaurantes
      final restaurants = await _listsService.getPopularRestaurants();
      setState(() => _popularRestaurants = restaurants);
    } catch (e) {
      print('Erro ao carregar restaurantes populares: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar restaurantes populares: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular no Forkly'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPopularRestaurants,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _popularRestaurants.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _popularRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = _popularRestaurants[index];
                    return _buildRestaurantCard(restaurant, index + 1);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum restaurante popular encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ainda não há restaurantes populares no Forkly',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant, int position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: position <= 3 ? Colors.amber : const Color(0xFFd60000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant['name'] ?? 'Restaurante sem nome',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (restaurant['address'] != null && restaurant['address'].isNotEmpty)
                        Text(
                          restaurant['address'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant['list_count'] ?? 0} listas',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${restaurant['rating_avg']?.toStringAsFixed(1) ?? '0.0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${restaurant['rating_count'] ?? 0} avaliações)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (restaurant['categories'] != null && restaurant['categories'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      restaurant['categories'].split(',').first,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewRestaurantDetails(restaurant),
                    icon: const Icon(Icons.info),
                    label: const Text('Ver Detalhes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFd60000),
                      side: const BorderSide(color: Color(0xFFd60000)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addToList(restaurant),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd60000),
                      foregroundColor: Colors.white,
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

  void _viewRestaurantDetails(Map<String, dynamic> restaurant) {
    // TODO: Navigate to restaurant details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tela de detalhes do restaurante em desenvolvimento')),
    );
  }

  void _addToList(Map<String, dynamic> restaurant) {
    // TODO: Show dialog to select which list to add to
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de adicionar à lista em desenvolvimento')),
    );
  }
}
