import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/auth_service_simple.dart';
import '../widgets/primary_button.dart';
import '../widgets/forkly_logo.dart';

class RestaurantRegisterScreen extends StatefulWidget {
  const RestaurantRegisterScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantRegisterScreen> createState() => _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState extends State<RestaurantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _averageTicketController = TextEditingController();
  final _capacityController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasDelivery = false;
  bool _hasTakeaway = true;
  bool _hasReservations = true;
  
  String _selectedCategory = 'restaurante';
  int _priceLevel = 1;
  
  final List<String> _categories = [
    'restaurante',
    'lanchonete',
    'pizzaria',
    'hamburgueria',
    'japonês',
    'italiano',
    'brasileiro',
    'churrascaria',
    'café',
    'bar',
    'sorveteria',
    'outro'
  ];

  @override
  void dispose() {
    _userNameController.dispose();
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _averageTicketController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _registerRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = Api();
      
      // Dados do restaurante
      final restaurantData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'lat': -23.5505, // São Paulo como padrão - em produção seria obtido via geolocalização
        'lng': -46.6333,
        'categories': _selectedCategory,
        'price_level': _priceLevel,
      };

      // Dados do perfil
      final profileData = {
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'average_ticket': double.tryParse(_averageTicketController.text) ?? 0.0,
        'capacity': int.tryParse(_capacityController.text) ?? 0,
        'has_delivery': _hasDelivery,
        'has_takeaway': _hasTakeaway,
        'has_reservations': _hasReservations,
        'payment_methods': ['dinheiro', 'cartão', 'pix'],
        'special_features': ['wifi', 'estacionamento'],
        'opening_hours': {
          'monday': {'open': '09:00', 'close': '22:00'},
          'tuesday': {'open': '09:00', 'close': '22:00'},
          'wednesday': {'open': '09:00', 'close': '22:00'},
          'thursday': {'open': '09:00', 'close': '22:00'},
          'friday': {'open': '09:00', 'close': '22:00'},
          'saturday': {'open': '09:00', 'close': '22:00'},
          'sunday': {'open': '09:00', 'close': '22:00'},
        }
      };

      // Primeiro, cadastrar o usuário
      final userData = {
        'username': _userNameController.text.trim(), // Usar nome completo como username
        'email': _userEmailController.text.trim(),
        'password': _userPasswordController.text,
        'first_name': _userNameController.text.trim(),
        'last_name': '',
      };

      await api.register(
        _userNameController.text.trim(), // Nome como username
        _userEmailController.text.trim(), // Email
        _userPasswordController.text,     // Senha
      );
      
      await api.registerRestaurant(restaurantData, profileData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurante cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Fazer login automático após cadastro
        try {
          final authService = AuthService();
          await authService.initialize();
          final loginSuccess = await authService.login(
            _userEmailController.text.trim(),
            _userPasswordController.text,
          );
          
          if (loginSuccess && mounted) {
            Navigator.pushReplacementNamed(context, '/restaurant-dashboard');
          } else if (mounted) {
            Navigator.pushReplacementNamed(context, '/restaurant-dashboard');
          }
        } catch (e) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/restaurant-dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro no cadastro do restaurante';
        
        if (e.toString().contains('400')) {
          errorMessage = 'Dados inválidos. Verifique os campos obrigatórios.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else {
          errorMessage = 'Erro: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Restaurante'),
        backgroundColor: const Color(0xFFd60000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Center(
                child: Column(
                  children: [
                    // Mantém somente o logo com borda/vermelha
                    ForklyLogoVertical(
                      fontSize: 28,
                      color: const Color(0xFFd60000),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cadastre seu restaurante no Forkly',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mensagem removida conforme solicitação
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // User information section (tema vermelho do app)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: const Color(0xFFd60000)),
                        const SizedBox(width: 8),
                        Text(
                          'Dados do Proprietário',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFd60000),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email é obrigatório';
                        }
                        if (!value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _userPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Senha *',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar Senha *',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value != _userPasswordController.text) {
                                return 'Senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Restaurant information section (tema vermelho do app)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant, color: const Color(0xFFd60000)),
                        const SizedBox(width: 8),
                        Text(
                          'Dados do Restaurante',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFd60000),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Restaurant name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do restaurante *',
                        prefixIcon: Icon(Icons.restaurant),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome do restaurante é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Endereço é obrigatório';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category and Price Level
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.capitalize()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _priceLevel,
                      decoration: const InputDecoration(
                        labelText: 'Faixa de preço',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('\$ - Econômico')),
                        DropdownMenuItem(value: 1, child: Text('\$\$ - Moderado')),
                        DropdownMenuItem(value: 2, child: Text('\$\$\$ - Caro')),
                        DropdownMenuItem(value: 3, child: Text('\$\$\$\$ - Muito caro')),
                        DropdownMenuItem(value: 4, child: Text('\$\$\$\$\$ - Luxo')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _priceLevel = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Contact info
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Website
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website (opcional)',
                  prefixIcon: Icon(Icons.web),
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição do restaurante',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Business info
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _averageTicketController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ticket médio (R\$)',
                        prefixIcon: Icon(Icons.monetization_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacidade (pessoas)',
                        prefixIcon: Icon(Icons.people),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Services (tema vermelho do app)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serviços oferecidos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFFd60000),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Delivery'),
                      subtitle: const Text('Entrega em domicílio'),
                      value: _hasDelivery,
                      onChanged: (value) => setState(() => _hasDelivery = value!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Retirada'),
                      subtitle: const Text('Cliente retira no local'),
                      value: _hasTakeaway,
                      onChanged: (value) => setState(() => _hasTakeaway = value!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Reservas'),
                      subtitle: const Text('Aceita reservas de mesa'),
                      value: _hasReservations,
                      onChanged: (value) => setState(() => _hasReservations = value!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register button
              PrimaryButton(
                text: 'Cadastrar Restaurante',
                onPressed: _isLoading ? null : _registerRestaurant,
                isLoading: _isLoading,
                size: MediaQuery.of(context).size.width < 600 ? ButtonSize.medium : ButtonSize.large,
              ),
              
              const SizedBox(height: 16),
              
              // Botão de pular removido conforme solicitação
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
