import 'package:flutter/material.dart';
import '../services/lists_service.dart';
import '../services/api.dart';

class FriendsListsScreen extends StatefulWidget {
  const FriendsListsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListsScreen> createState() => _FriendsListsScreenState();
}

class _FriendsListsScreenState extends State<FriendsListsScreen> {
  final ListsService _listsService = ListsService();
  final Api _api = Api();
  List<Map<String, dynamic>> _friendsLists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriendsLists();
  }

  Future<void> _loadFriendsLists() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar se já está autenticado
      if (!_api.isAuthenticated) {
        print('Não está autenticado, mostrando mensagem...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa fazer login primeiro para ver listas de amigos'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _friendsLists = []);
        return;
      }
      
      print('Usuário autenticado, carregando listas de amigos...');
      // Carregar listas
      final lists = await _listsService.getFriendsLists();
      setState(() => _friendsLists = lists);
    } catch (e) {
      print('Erro ao carregar listas de amigos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar listas de amigos: $e'),
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
        title: const Text('Listas dos Amigos'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadFriendsLists,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendsLists.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _friendsLists.length,
                  itemBuilder: (context, index) {
                    final list = _friendsLists[index];
                    return _buildListCard(list);
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma lista de amigos encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus amigos ainda não criaram listas públicas',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> list) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list['title'] ?? 'Lista sem nome',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        list['description'] ?? 'Sem descrição',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por: ${list['owner'] is Map ? list['owner']['username'] ?? 'Usuário desconhecido' : 'Usuário desconhecido'}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
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
                      Icon(Icons.people, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Amigo',
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
                Icon(Icons.restaurant, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${list['items']?.length ?? 0} restaurantes',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFd60000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFd60000).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 14, color: const Color(0xFFd60000)),
                      const SizedBox(width: 4),
                      Text(
                        list['share_code'] ?? 'N/A',
                        style: const TextStyle(
                          color: Color(0xFFd60000),
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewListDetails(list),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Lista'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFd60000),
                      side: const BorderSide(color: Color(0xFFd60000)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _copyShareCode(list['share_code'] ?? ''),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar Código'),
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

  void _copyShareCode(String shareCode) {
    if (shareCode.isNotEmpty) {
      // Clipboard.setData(ClipboardData(text: shareCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código "$shareCode" copiado para a área de transferência!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewListDetails(Map<String, dynamic> list) {
    // TODO: Navigate to list details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tela de detalhes da lista em desenvolvimento')),
    );
  }
}
