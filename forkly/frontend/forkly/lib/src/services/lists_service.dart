import 'api.dart';

class ListsService {
  final Api _api = Api();

  Future<List<Map<String, dynamic>>> getMyLists() async {
    try {
      final response = await _api.getMyLists();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao carregar minhas listas: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsLists() async {
    try {
      final response = await _api.getFriendsLists();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao carregar listas dos amigos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createList(String title, {String? description, bool isPublic = true}) async {
    try {
      final response = await _api.createList(title, description: description, isPublic: isPublic);
      return response;
    } catch (e) {
      print('Erro ao criar lista: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNetworkRecommendations() async {
    try {
      final response = await _api.getNetworkRecommendations();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao carregar recomendações da rede: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPopularRestaurants() async {
    try {
      final response = await _api.getPopularRestaurants();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao carregar restaurantes populares: $e');
      return [];
    }
  }
}
