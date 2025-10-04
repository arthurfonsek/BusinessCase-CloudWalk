import 'package:flutter/material.dart';
import '../services/api.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  
  const RestaurantDetailScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _api = Api();
  final _reviewController = TextEditingController();
  final _ratingController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escreva uma avaliação')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement API call to submit review
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Track first review for referral funnel
      // In a real app, you'd check if this is the user's first review
      await _api.track('DEMO123', 'first_review');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _reviewController.clear();
        _ratingController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                restaurant['name'] ?? 'Restaurante',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFd60000),
                      const Color(0xFFd60000).withOpacity(0.8),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber[600]),
                              const SizedBox(width: 8),
                              Text(
                                '${restaurant['rating_avg'] ?? 'N/A'} ⭐',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Nível de preço: \$${restaurant['price_level'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${restaurant['address'] ?? 'Endereço não disponível'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Review form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.rate_review, color: const Color(0xFFd60000)),
                              const SizedBox(width: 8),
                              Text(
                                'Deixe sua avaliação',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFd60000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Rating input
                          TextFormField(
                            controller: _ratingController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nota (1-5)',
                              prefixIcon: Icon(Icons.star),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Nota é obrigatória';
                              final rating = double.tryParse(value);
                              if (rating == null || rating < 1 || rating > 5) {
                                return 'Nota deve ser entre 1 e 5';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Review text
                          TextFormField(
                            controller: _reviewController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Sua avaliação',
                              hintText: 'Conte sua experiência neste restaurante...',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitReview,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(_isSubmitting ? 'Enviando...' : 'Enviar Avaliação'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFd60000),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Add to favorites
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Adicionado aos favoritos!')),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Favoritar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[600],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Share restaurant
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copiado para compartilhar!')),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green[600],
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
        ],
      ),
    );
  }
}
