import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service_simple.dart';
import '../widgets/responsive_button.dart';
import 'home_screen.dart';

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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
        Container(
          width: isSmallScreen ? 80 : 100,
          height: isSmallScreen ? 80 : 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant,
            size: isSmallScreen ? 40 : 50,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        Text(
          'Forkly',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            fontSize: isSmallScreen ? 28 : 36,
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Não tem uma conta? ',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isSmallScreen ? 8 : 12),
        
        // Link para visitar como convidado
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/');
          },
          child: Text(
            'Continuar como convidado',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
