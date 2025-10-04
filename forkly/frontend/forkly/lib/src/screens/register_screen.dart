import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../widgets/responsive_button.dart';
import '../widgets/primary_button.dart';
import '../widgets/forkly_logo.dart';

class RegisterScreen extends StatefulWidget {
  final String? referralCode;
  
  const RegisterScreen({Key? key, this.referralCode}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill referral code if provided
    if (widget.referralCode != null) {
      _referralCodeController.text = widget.referralCode!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = Api();
      
      // Track referral if code is provided
      if (_referralCodeController.text.trim().isNotEmpty) {
        try {
          await api.track(_referralCodeController.text.trim(), 'registered');
        } catch (e) {
          // Referral tracking failed, but continue with registration
          print('Erro ao rastrear referência: $e');
        }
      }
      
      // Register user
      await api.register(
        _emailController.text.trim(),
        _passwordController.text,
        referral: _referralCodeController.text.trim().isNotEmpty 
            ? _referralCodeController.text.trim() 
            : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro no registro';
        
        if (e.toString().contains('400')) {
          errorMessage = 'Dados inválidos. Verifique se a senha tem pelo menos 8 caracteres e o email é válido.';
        } else if (e.toString().contains('username')) {
          errorMessage = 'Nome de usuário já existe. Tente outro.';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Email já está em uso. Tente outro.';
        } else if (e.toString().contains('password')) {
          errorMessage = 'Senha muito fraca. Use pelo menos 8 caracteres com letras e números.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else {
          errorMessage = 'Erro no registro: ${e.toString()}';
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
        title: const Text('Registro'),
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
              
              // Logo/Title
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 80,
                      color: const Color(0xFFd60000),
                    ),
                    const SizedBox(height: 16),
                    ForklyLogoVertical(
                      fontSize: 32,
                      color: const Color(0xFFd60000),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descubra os melhores restaurantes',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
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
              
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
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
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Senha é obrigatória';
                  }
                  if (value.length < 8) {
                    return 'Senha deve ter pelo menos 8 caracteres';
                  }
                  if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                    return 'Senha deve conter letras e números';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Referral code section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFd60000).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFd60000).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, color: const Color(0xFFd60000)),
                        const SizedBox(width: 8),
                        Text(
                          'Código de Referência',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFd60000),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tem um código de referência? Cole aqui para ganhar benefícios!',
                      style: TextStyle(color: const Color(0xFFd60000).withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de referência (opcional)',
                        prefixIcon: const Icon(Icons.code),
                        border: const OutlineInputBorder(),
                        suffixIcon: _referralCodeController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _referralCodeController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register button
              PrimaryButton(
                text: 'Criar Conta',
                onPressed: _isLoading ? null : _register,
                isLoading: _isLoading,
                size: MediaQuery.of(context).size.width < 600 ? ButtonSize.medium : ButtonSize.large,
              ),
              
              const SizedBox(height: 16),
              
              // Login link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Já tem uma conta? Faça login',
                    style: TextStyle(color: const Color(0xFFd60000)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
