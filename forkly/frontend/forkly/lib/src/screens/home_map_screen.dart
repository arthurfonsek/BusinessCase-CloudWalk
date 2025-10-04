import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api.dart';
import 'map_widget.dart';

class HomeMapScreen extends StatefulWidget { 
  const HomeMapScreen({super.key}); 
  @override 
  State<HomeMapScreen> createState()=>_HomeMapScreenState(); 
}

class _HomeMapScreenState extends State<HomeMapScreen>{
  final _api = Api();
  double _centerLat = -23.561; // São Paulo coordinates
  double _centerLng = -46.656;
  Set<MapMarker> _markers = {};
  final _q = TextEditingController();
  bool _isSearching = false;
  String _lastSearchQuery = '';

  Future<void> _loadNearby() async {
    final data = await _api.nearby(_centerLat, _centerLng);
    setState((){ 
      _markers = data.map<MapMarker>((e)=> MapMarker(
        id: e["id"].toString(),
        latitude: e["lat"],
        longitude: e["lng"],
        title: e["name"],
        snippet: "${e["rating_avg"]}★  \$${e["price_level"]}",
        address: e["address"] ?? "Endereço não disponível",
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
      final data = await _api.search(_q.text, _centerLat, _centerLng);
      setState((){ 
        _markers = data.map<MapMarker>((e)=> MapMarker(
          id: e["id"].toString(),
          latitude: e["lat"],
          longitude: e["lng"],
          title: e["name"],
          snippet: "${e["rating_avg"]}★  \$${e["price_level"]}",
          address: e["address"] ?? "Endereço não disponível",
        )).toSet(); 
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      // Show error message
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
  Widget build(BuildContext context){
           Widget mapArea = MapWidget(
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
               // Find the restaurant data for this marker
               final restaurant = _markers.firstWhere((m) => m.id == marker.id);
               Navigator.pushNamed(
                 context, 
                 '/restaurant-detail',
                 arguments: {
                   'id': restaurant.id,
                   'name': restaurant.title,
                   'address': 'Endereço do restaurante',
                   'rating_avg': '4.5',
                   'price_level': '3',
                 },
               );
             },
           );

    return Scaffold(
             appBar: AppBar(
               title: const Text('Mapa de Restaurantes'),
               backgroundColor: const Color(0xFFd60000),
               foregroundColor: Colors.white,
               elevation: 0,
               leading: IconButton(
                 icon: const Icon(Icons.arrow_back),
                 onPressed: () => Navigator.pop(context),
               ),
               actions: [
                 IconButton(
                   onPressed: () => Navigator.pushNamed(context, "/my-lists"), 
                   icon: const Icon(Icons.list_alt),
                   tooltip: 'Minhas Listas',
                 ),
                 IconButton(
                   onPressed: () => Navigator.pushNamed(context, "/rewards"), 
                   icon: const Icon(Icons.card_giftcard),
                   tooltip: 'Recompensas',
                 ),
                 IconButton(
                   onPressed: () => Navigator.pushNamed(context, "/metrics"), 
                   icon: const Icon(Icons.analytics),
                   tooltip: 'Métricas',
                 ),
               ]
             ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children:[
            Expanded(
              child: TextField(
                controller: _q,
                decoration: InputDecoration(
                  hintText: "Search like 'burger', 'pizza', 'sushi'...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  prefixIcon: const Icon(Icons.search),
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
                              });
                            },
                          )
                        : null,
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ]),
        ),
        if (_lastSearchQuery.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Text(
              'Searching for: "$_lastSearchQuery" (${_markers.length} results)',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Expanded(child: mapArea)
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _loadNearby, child: const Icon(Icons.near_me)),
    );
  }
}
