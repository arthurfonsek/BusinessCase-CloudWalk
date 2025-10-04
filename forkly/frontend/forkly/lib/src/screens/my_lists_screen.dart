import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lists_service.dart';
import '../services/api.dart';
import '../services/auth_service_simple.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({Key? key}) : super(key: key);

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  final ListsService _listsService = ListsService();
  final Api _api = Api();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _lists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar se já está autenticado
      if (!_authService.isAuthenticated) {
        print('Não está autenticado, mostrando mensagem...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa fazer login primeiro para ver suas listas'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _lists = []);
        return;
      }
      
      print('Usuário autenticado, carregando listas...');
      // Carregar listas
      final lists = await _listsService.getMyLists();
      setState(() => _lists = lists);
    } catch (e) {
      print('Erro ao carregar listas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar listas: $e'),
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
        title: const Text('Minhas Listas'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showCreateListDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Criar nova lista',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
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
            Icons.list_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma lista criada ainda',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira lista de restaurantes!',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateListDialog,
            icon: const Icon(Icons.add),
            label: const Text('Criar Lista'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd60000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                        list['title'] ?? list['name'] ?? 'Lista sem nome',
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
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleListAction(value, list),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Compartilhar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
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

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Nova Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _createList(nameController.text.trim(), descriptionController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createList(String name, String description) async {
    try {
      final newList = await _listsService.createList(name, description: description);
      if (newList != null) {
        setState(() {
          _lists.insert(0, newList);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lista criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao criar lista'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar lista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateShareCode() {
    // Generate a simple share code
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }

  void _handleListAction(String action, Map<String, dynamic> list) {
    switch (action) {
      case 'edit':
        // TODO: Implement edit functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
        );
        break;
      case 'share':
        _copyShareCode(list['shareCode']);
        break;
      case 'delete':
        _deleteList(list);
        break;
    }
  }

  void _deleteList(Map<String, dynamic> list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Lista'),
        content: Text('Tem certeza que deseja excluir a lista "${list['title'] ?? list['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _lists.removeWhere((l) => l['id'] == list['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lista excluída'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _copyShareCode(String shareCode) {
    Clipboard.setData(ClipboardData(text: shareCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código "$shareCode" copiado para a área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewListDetails(Map<String, dynamic> list) {
    // TODO: Navigate to list details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tela de detalhes da lista em desenvolvimento')),
    );
  }
}
