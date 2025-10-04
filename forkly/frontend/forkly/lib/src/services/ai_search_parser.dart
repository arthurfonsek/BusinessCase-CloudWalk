import 'dart:math';

class AISearchParser {
  // Palavras-chave para diferentes tipos de comida
  static const Map<String, List<String>> foodKeywords = {
    'sushi': ['sushi', 'sashimi', 'japonês', 'japonesa', 'temaki', 'maki', 'niguiri'],
    'burger': ['hambúrguer', 'burger', 'lanche', 'fast food', 'sanduíche'],
    'pizza': ['pizza', 'italiana', 'massa', 'margherita', 'pepperoni'],
    'chinese': ['chinesa', 'chines', 'wok', 'yakisoba', 'chop suey'],
    'vegan': ['vegano', 'vegana', 'vegetariano', 'vegetariana', 'orgânico'],
    'coffee': ['café', 'coffee', 'espresso', 'cappuccino', 'latte'],
    'ramen': ['ramen', 'lámen', 'sopa', 'japonesa'],
    'steak': ['churrasco', 'steak', 'carne', 'bife', 'picanha'],
    'seafood': ['frutos do mar', 'peixe', 'camarão', 'lagosta', 'salmão'],
    'dessert': ['sobremesa', 'doce', 'sorvete', 'açaí', 'pudim'],
  };

  // Palavras-chave para contexto social
  static const Map<String, List<String>> socialKeywords = {
    'friends': ['amigos', 'amigo', 'recomendado', 'recomendação', 'indicação'],
    'popular': ['popular', 'famoso', 'conhecido', 'bem avaliado', 'top'],
    'nearby': ['perto', 'próximo', 'perto de mim', 'na região', 'local'],
    'cheap': ['barato', 'econômico', 'acessível', 'promoção'],
    'expensive': ['caro', 'luxo', 'premium', 'sofisticado'],
  };

  // Palavras-chave para tipos de estabelecimento
  static const Map<String, List<String>> establishmentKeywords = {
    'restaurant': ['restaurante', 'lanchonete', 'casa', 'local'],
    'cafe': ['café', 'cafeteria', 'lanchonete'],
    'bar': ['bar', 'pub', 'boteco', 'cervejaria'],
    'fastfood': ['fast food', 'lanche rápido', 'delivery'],
  };

  /// Analisa uma consulta em linguagem natural e retorna termos de busca otimizados
  static SearchQuery parseNaturalLanguage(String query) {
    final lowerQuery = query.toLowerCase().trim();
    
    // Se a query é muito curta (1-2 caracteres), retorna como está
    if (lowerQuery.length <= 2) {
      return SearchQuery(
        originalQuery: query,
        searchTerms: [query],
        foodTypes: [],
        socialContext: [],
        establishmentTypes: [],
        priceRange: null,
        locationContext: null,
      );
    }

    // Extrai tipos de comida
    final foodTypes = _extractFoodTypes(lowerQuery);
    
    // Extrai contexto social
    final socialContext = _extractSocialContext(lowerQuery);
    
    // Extrai tipos de estabelecimento
    final establishmentTypes = _extractEstablishmentTypes(lowerQuery);
    
    // Extrai faixa de preço
    final priceRange = _extractPriceRange(lowerQuery);
    
    // Extrai contexto de localização
    final locationContext = _extractLocationContext(lowerQuery);
    
    // Gera termos de busca otimizados
    final searchTerms = _generateSearchTerms(
      lowerQuery, 
      foodTypes, 
      socialContext, 
      establishmentTypes
    );

    return SearchQuery(
      originalQuery: query,
      searchTerms: searchTerms,
      foodTypes: foodTypes,
      socialContext: socialContext,
      establishmentTypes: establishmentTypes,
      priceRange: priceRange,
      locationContext: locationContext,
    );
  }

  /// Extrai tipos de comida da consulta
  static List<String> _extractFoodTypes(String query) {
    final foodTypes = <String>[];
    
    for (final entry in foodKeywords.entries) {
      for (final keyword in entry.value) {
        if (query.contains(keyword)) {
          foodTypes.add(entry.key);
          break;
        }
      }
    }
    
    return foodTypes;
  }

  /// Extrai contexto social da consulta
  static List<String> _extractSocialContext(String query) {
    final socialContext = <String>[];
    
    for (final entry in socialKeywords.entries) {
      for (final keyword in entry.value) {
        if (query.contains(keyword)) {
          socialContext.add(entry.key);
          break;
        }
      }
    }
    
    return socialContext;
  }

  /// Extrai tipos de estabelecimento da consulta
  static List<String> _extractEstablishmentTypes(String query) {
    final establishmentTypes = <String>[];
    
    for (final entry in establishmentKeywords.entries) {
      for (final keyword in entry.value) {
        if (query.contains(keyword)) {
          establishmentTypes.add(entry.key);
          break;
        }
      }
    }
    
    return establishmentTypes;
  }

  /// Extrai faixa de preço da consulta
  static PriceRange? _extractPriceRange(String query) {
    if (query.contains('barato') || query.contains('econômico') || query.contains('acessível')) {
      return PriceRange.low;
    } else if (query.contains('caro') || query.contains('luxo') || query.contains('premium')) {
      return PriceRange.high;
    } else if (query.contains('médio') || query.contains('moderado')) {
      return PriceRange.medium;
    }
    return null;
  }

  /// Extrai contexto de localização da consulta
  static LocationContext? _extractLocationContext(String query) {
    if (query.contains('perto') || query.contains('próximo') || query.contains('local')) {
      return LocationContext.nearby;
    } else if (query.contains('centro') || query.contains('downtown')) {
      return LocationContext.center;
    } else if (query.contains('shopping') || query.contains('mall')) {
      return LocationContext.shopping;
    }
    return null;
  }

  /// Gera termos de busca otimizados baseados na análise
  static List<String> _generateSearchTerms(
    String originalQuery,
    List<String> foodTypes,
    List<String> socialContext,
    List<String> establishmentTypes,
  ) {
    final searchTerms = <String>[];
    
    // Adiciona tipos de comida identificados
    searchTerms.addAll(foodTypes);
    
    // Se não encontrou tipos específicos, tenta extrair palavras-chave gerais
    if (foodTypes.isEmpty) {
      final words = originalQuery.split(' ');
      for (final word in words) {
        if (word.length > 3 && !_isStopWord(word)) {
          searchTerms.add(word);
        }
      }
    }
    
    // Adiciona contexto social se relevante
    if (socialContext.contains('friends')) {
      searchTerms.add('recomendado');
    }
    if (socialContext.contains('popular')) {
      searchTerms.add('popular');
    }
    
    // Adiciona tipos de estabelecimento
    searchTerms.addAll(establishmentTypes);
    
    // Remove duplicatas e retorna
    return searchTerms.toSet().toList();
  }

  /// Verifica se uma palavra é uma stop word (palavra comum sem significado)
  static bool _isStopWord(String word) {
    const stopWords = {
      'de', 'da', 'do', 'das', 'dos', 'em', 'na', 'no', 'nas', 'nos',
      'para', 'por', 'com', 'sem', 'sobre', 'entre', 'até', 'desde',
      'que', 'quem', 'onde', 'quando', 'como', 'porque', 'se', 'mas',
      'e', 'ou', 'então', 'também', 'muito', 'mais', 'menos',
      'perto', 'próximo', 'recomendado', 'amigos', 'amigo'
    };
    return stopWords.contains(word.toLowerCase());
  }

  /// Gera uma descrição amigável da busca interpretada
  static String generateSearchDescription(SearchQuery query) {
    final parts = <String>[];
    
    if (query.foodTypes.isNotEmpty) {
      parts.add('${query.foodTypes.join(', ')}');
    }
    
    if (query.socialContext.contains('friends')) {
      parts.add('recomendado por amigos');
    }
    
    if (query.socialContext.contains('popular')) {
      parts.add('popular');
    }
    
    if (query.locationContext == LocationContext.nearby) {
      parts.add('perto de você');
    }
    
    if (query.priceRange == PriceRange.low) {
      parts.add('econômico');
    } else if (query.priceRange == PriceRange.high) {
      parts.add('premium');
    }
    
    if (parts.isEmpty) {
      return 'Resultados para "${query.originalQuery}"';
    }
    
    return 'Buscando: ${parts.join(' ')}';
  }
}

/// Representa uma consulta de busca processada pela IA
class SearchQuery {
  final String originalQuery;
  final List<String> searchTerms;
  final List<String> foodTypes;
  final List<String> socialContext;
  final List<String> establishmentTypes;
  final PriceRange? priceRange;
  final LocationContext? locationContext;

  const SearchQuery({
    required this.originalQuery,
    required this.searchTerms,
    required this.foodTypes,
    required this.socialContext,
    required this.establishmentTypes,
    this.priceRange,
    this.locationContext,
  });

  /// Retorna se a busca tem contexto social (recomendado por amigos, etc.)
  bool get hasSocialContext => socialContext.isNotEmpty;
  
  /// Retorna se a busca tem tipos de comida específicos
  bool get hasFoodTypes => foodTypes.isNotEmpty;
  
  /// Retorna se a busca tem preferência de preço
  bool get hasPricePreference => priceRange != null;
  
  /// Retorna se a busca tem contexto de localização
  bool get hasLocationContext => locationContext != null;
}

/// Faixa de preço
enum PriceRange { low, medium, high }

/// Contexto de localização
enum LocationContext { nearby, center, shopping }
