import 'package:flutter/material.dart';
import 'home_map_screen.dart';
import '../../widgets/rectangular_button.dart';
import '../widgets/responsive_button.dart';
import '../widgets/primary_button.dart';
import 'map_widget.dart';
import '../services/api.dart';
import '../services/ai_search_parser.dart';
import '../services/auth_service_simple.dart';
import 'network_recommendations_screen.dart';
import 'popular_restaurants_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = Api();
  double _centerLat = -23.561; // São Paulo coordinates
  double _centerLng = -46.656;
  Set<MapMarker> _markers = {};
  final _q = TextEditingController();
  bool _isSearching = false;
  String _lastSearchQuery = '';
  SearchQuery? _currentSearchQuery;

  Future<void> _loadNearby() async {
    final data = await _api.nearby(_centerLat, _centerLng, radius: 500); // Reduzido de 1500 para 500
    setState((){
      _markers = data.map<MapMarker>((e)=> MapMarker(
        id: e["id"].toString(),
        latitude: e["lat"],
        longitude: e["lng"],
        title: e["name"],
        snippet: "${e["rating_avg"]}★  \$${e["price_level"]}",
        address: e["address"] ?? "Endereço não disponível", // Adicionar endereço real
      )).toSet();
    });
  }

  Future<void> _search() async {
    if (_q.text.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _lastSearchQuery = _q.text.trim();
    });

    try {
      // Usar IA para interpretar a busca
      final searchQuery = AISearchParser.parseNaturalLanguage(_q.text.trim());
      _currentSearchQuery = searchQuery;
      
      // Usar os termos de busca otimizados pela IA
      final searchTerm = searchQuery.searchTerms.isNotEmpty 
          ? searchQuery.searchTerms.join(' ')
          : _q.text.trim();
      
      final data = await _api.search(searchTerm, _centerLat, _centerLng, radius: 500);
      setState((){
        _markers = data.map<MapMarker>((e)=> MapMarker(
          id: e["id"].toString(),
          latitude: e["lat"],
          longitude: e["lng"],
          title: e["name"],
          snippet: "${e["rating_avg"]}★  \$${e["price_level"]}",
          address: e["address"] ?? "Endereço não disponível", // Adicionar endereço real
        )).toSet();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na pesquisa: $e')),
        );
      }
    }
  }

  @override 
  void initState(){ 
    super.initState(); 
    _loadNearby();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Força a reconstrução quando a autenticação muda
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forkly'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          _buildAuthActions(isSmallScreen),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bem-vindo ao Forkly',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFd60000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Descubra os melhores restaurantes da sua região',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureButtons(context),
                ],
              ),
            ),
            
            // Search section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _q,
                          decoration: InputDecoration(
                            hintText: "Ex: 'Sushis recomendados por amigos perto de mim'",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Color(0xFFd60000), width: 2),
                            ),
                            prefixIcon: const Icon(Icons.psychology, color: Color(0xFFd60000)),
                            suffixIcon: _isSearching 
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _q.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _q.clear();
                                        setState(() {
                                          _lastSearchQuery = '';
                                          _currentSearchQuery = null;
                                        });
                                      },
                                    )
                                  : null,
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PrimaryButton(
                        text: 'Buscar',
                        icon: Icons.search,
                        onPressed: _isSearching ? null : _search,
                        isLoading: _isSearching,
                        size: isSmallScreen ? ButtonSize.medium : ButtonSize.large,
                      ),
                    ],
                  ),
                  if (_lastSearchQuery.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFd60000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFd60000).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, color: const Color(0xFFd60000), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'IA interpretou sua busca:',
                                style: const TextStyle(
                                  color: Color(0xFFd60000),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentSearchQuery != null 
                                ? AISearchParser.generateSearchDescription(_currentSearchQuery!)
                                : 'Buscando por: "$_lastSearchQuery"',
                            style: const TextStyle(
                              color: Color(0xFFd60000),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_markers.length} resultados encontrados',
                            style: TextStyle(
                              color: const Color(0xFFd60000).withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Map section - MUCH LARGER
            Container(
              height: 500, // Mapa muito maior - 500px de altura
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MapWidget(
                  latitude: _centerLat,
                  longitude: _centerLng,
                  markers: _markers,
                  onMapCreated: (lat, lng) {
                    _centerLat = lat;
                    _centerLng = lng;
                  },
                  onCameraMove: (lat, lng) {
                    _centerLat = lat;
                    _centerLng = lng;
                  },
                  onMarkerTap: (marker) {
                    final restaurant = _markers.firstWhere((m) => m.id == marker.id);
                    Navigator.pushNamed(
                      context, 
                      '/restaurant-detail',
                      arguments: {
                        'id': restaurant.id,
                        'name': restaurant.title,
                        'address': restaurant.address,
                        'rating_avg': '4.5',
                        'price_level': '3',
                      },
                    );
                  },
                ),
              ),
            ),
            
            // Results section
            if (_markers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFd60000),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Restaurantes Encontrados (${_markers.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _markers.length,
                        itemBuilder: (context, index) {
                          final marker = _markers.elementAt(index);
                          return _buildRestaurantCard(marker);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // Bottom spacing
            const SizedBox(height: 20),
          ],
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
                    Icons.person,
                    color: Color(0xFFd60000),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Olá, ${AuthService().currentUser?.name ?? AuthService().currentUser?.username ?? 'Usuário'}!',
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
            leading: const Icon(Icons.list_alt, color: Color(0xFFd60000)),
            title: const Text('Minhas Listas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my-lists');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFFd60000)),
            title: const Text('Amigos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/friends');
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Color(0xFFd60000)),
            title: const Text('Recompensas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/rewards');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.map, color: Color(0xFFd60000)),
            title: const Text('Mapa de Restaurantes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeMapScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Color(0xFFd60000)),
            title: const Text('Métricas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/metrics');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButtons(BuildContext context) {
    return Column(
      children: [
        RectangularButton(
          title: 'Minhas Listas',
          icon: Icons.list_alt,
          onTap: () => Navigator.pushNamed(context, '/my-lists'),
        ),
        const SizedBox(height: 12),
        RectangularButton(
          title: 'Novidades de Amigos',
          icon: Icons.people,
          onTap: () => Navigator.pushNamed(context, '/friends'),
        ),
        const SizedBox(height: 12),
        RectangularButton(
          title: 'Achados da sua Rede',
          icon: Icons.explore,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NetworkRecommendationsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        RectangularButton(
          title: 'Popular no Forkly',
          icon: Icons.trending_up,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PopularRestaurantsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(MapMarker marker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context, 
              '/restaurant-detail',
              arguments: {
                'id': marker.id,
                'name': marker.title,
                'address': marker.address,
                'rating_avg': '4.5',
                'price_level': '3',
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFd60000).withOpacity(0.1),
                        const Color(0xFFd60000).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFd60000).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Color(0xFFd60000),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd60000),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFd60000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          marker.snippet,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFd60000),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              marker.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFd60000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Color(0xFFd60000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthActions(bool isSmallScreen) {
    final authService = AuthService();
    
    if (authService.isAuthenticated) {
      // Se estiver logado, mostrar botão de logout
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSmallScreen)
            Text(
              'Olá, ${authService.currentUser?.name ?? 'Usuário'}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(width: 8),
          PrimaryButton(
            text: 'Sair',
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            size: isSmallScreen ? ButtonSize.small : ButtonSize.medium,
          ),
        ],
      );
    } else {
      // Se não estiver logado, mostrar botões de login
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSmallScreen)
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/register'),
              child: const Text(
                'Criar Conta',
                style: TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(width: 8),
          PrimaryButton(
            text: isSmallScreen ? 'Login' : 'Entrar',
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            size: isSmallScreen ? ButtonSize.small : ButtonSize.medium,
          ),
        ],
      );
    }
  }


}
