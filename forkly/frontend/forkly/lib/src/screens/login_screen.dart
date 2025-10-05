import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service_simple.dart';
import '../widgets/responsive_button.dart';
import '../widgets/primary_button.dart';
import '../widgets/forkly_logo.dart';
import 'home_screen.dart';
import '../app.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authService = AuthService();
      await authService.initialize(); // Inicializar o serviço
      final success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Server-truth check: if dashboard endpoint works, this is an owner
        try {
          final api = Api();
          await api.getRestaurantDashboard();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/restaurant-dashboard');
          return;
        } catch (_) {
          // Fallback to role/home
          final user = authService.currentUser;
          if (user != null && user.role.isRestaurantOwner) {
            Navigator.of(context).pushReplacementNamed('/restaurant-dashboard');
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RoleBasedHome()),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciais inválidas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login: ${e.toString()}'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isSmallScreen ? 40 : 60),
                
                // Logo e título
                _buildHeader(context, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 40 : 60),
                
                // Formulário de login
                _buildLoginForm(context, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Botão de login
                _buildLoginButton(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Opções adicionais
                _buildAdditionalOptions(context, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Links de navegação
                _buildNavigationLinks(context, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Remove ícone duplicado; manter apenas o logo principal com cor/borda vermelha
        SizedBox(height: isSmallScreen ? 16 : 24),
        ForklyLogoVertical(
          fontSize: isSmallScreen ? 28 : 36,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'Bem-vindo de volta!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Campo de usuário
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Usuário ou Email',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 16 : 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Usuário ou email é obrigatório';
            }
            return null;
          },
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Campo de senha
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 16 : 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Senha é obrigatória';
            }
            return null;
          },
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Lembrar-me e esqueci minha senha
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text(
                  'Lembrar-me',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/forgot-password');
              },
              child: Text(
                'Esqueci minha senha',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        text: 'Entrar',
        onPressed: _login,
        size: isSmallScreen ? ButtonSize.medium : ButtonSize.large,
      ),
    );
  }

  Widget _buildAdditionalOptions(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Divisor
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
              child: Text(
                'ou',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Login social (placeholder)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implementar login com Google
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login com Google em breve'),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.g_mobiledata),
                    SizedBox(width: 8),
                    Text('Google'),
                  ],
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implementar login com Apple
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login com Apple em breve'),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apple),
                    SizedBox(width: 8),
                    Text('Apple'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationLinks(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Link para registro
        Text(
          'Não tem uma conta?',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              icon: const Icon(Icons.person, size: 20),
              label: Text(
                'Sou Cliente',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFd60000),
                side: const BorderSide(color: Color(0xFFd60000), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/restaurant-register');
              },
              icon: const Icon(Icons.restaurant, size: 20),
              label: Text(
                'Sou Restaurante',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd60000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        
        // Removido: continuar como convidado
      ],
    );
  }
}
