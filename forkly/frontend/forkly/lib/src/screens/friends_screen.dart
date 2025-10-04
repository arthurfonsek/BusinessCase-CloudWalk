import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/friends_service.dart';
import '../services/api.dart';
import '../widgets/responsive_button.dart';
import '../widgets/primary_button.dart';
import 'friends_lists_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();
  final Api _api = Api();
  final TextEditingController _searchController = TextEditingController();
  
  List<Friend> _friends = [];
  List<Friend> _referredFriends = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar se já está autenticado
      if (!_api.isAuthenticated) {
        print('Não está autenticado, mostrando mensagem...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa fazer login primeiro para ver seus amigos'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _friends = [];
          _referredFriends = [];
        });
        return;
      }
      
      print('Usuário autenticado, carregando amigos...');
      // Carregar amigos
      print('Carregando amigos...');
      final friends = await _friendsService.getFriends();
      print('Amigos carregados: ${friends.length}');
      
      final referredFriends = await _friendsService.getReferredFriends();
      print('Amigos referidos carregados: ${referredFriends.length}');
      
      setState(() {
        _friends = friends;
        _referredFriends = referredFriends;
      });
    } catch (e) {
      print('Erro ao carregar amigos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar amigos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final results = await _friendsService.searchUsers(_searchController.text.trim());
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar usuários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _addFriend(String username) async {
    final success = await _friendsService.addFriend(username);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amigo adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadFriends();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao adicionar amigo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFriend(String friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Amigo'),
        content: const Text('Tem certeza que deseja remover este amigo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(true),
            text: 'Remover',
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _friendsService.removeFriend(friendId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amigo removido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFriends();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao remover amigo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amigos'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Amigos'),
            Tab(text: 'Referidos'),
            Tab(text: 'Listas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar usuários...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchUsers(),
                  ),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  text: 'Buscar',
                  onPressed: _isSearching ? null : _searchUsers,
                  isLoading: _isSearching,
                  size: isSmallScreen ? ButtonSize.small : ButtonSize.medium,
                ),
              ],
            ),
          ),
          
          // Resultados da busca
          if (_searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultados da busca:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._searchResults.map((user) => _buildSearchResultItem(user)),
                ],
              ),
            ),
          
          // Tabs de amigos
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildReferredFriendsList(),
                const FriendsListsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFd60000),
          child: Text(
            user['username'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user['username']),
        subtitle: Text(user['email']),
        trailing: PrimaryButton(
          text: 'Adicionar',
          onPressed: () => _addFriend(user['username']),
          size: ButtonSize.small,
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum amigo encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Use a busca acima para encontrar e adicionar amigos',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendItem(friend);
      },
    );
  }

  Widget _buildReferredFriendsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_referredFriends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum amigo referido',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Amigos que usaram seu código de referência aparecerão aqui',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _referredFriends.length,
      itemBuilder: (context, index) {
        final friend = _referredFriends[index];
        return _buildReferredFriendItem(friend);
      },
    );
  }

  Widget _buildFriendItem(Friend friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFd60000),
          child: Text(
            friend.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(friend.name),
        subtitle: Text('@${friend.username}'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _removeFriend(friend.id),
        ),
      ),
    );
  }

  Widget _buildReferredFriendItem(Friend friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(Icons.card_giftcard, color: Colors.white),
        ),
        title: Text(friend.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${friend.username}'),
            Text(
              'Referido em ${friend.addedAt.day}/${friend.addedAt.month}/${friend.addedAt.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _removeFriend(friend.id),
        ),
      ),
    );
  }
}
