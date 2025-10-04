import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service_simple.dart';
import '../widgets/responsive_button.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Simular envio de email
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _emailSent = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removido authState - não mais necessário
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),
                
                // Header
                _buildHeader(context, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 40 : 60),
                
                // Conteúdo baseado no estado
                if (_emailSent)
                  _buildEmailSentContent(context, isSmallScreen)
                else
                  _buildRequestForm(context, isSmallScreen),
                
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.lock_reset,
            size: isSmallScreen ? 40 : 50,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        Text(
          _emailSent ? 'Email Enviado!' : 'Esqueceu sua senha?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            fontSize: isSmallScreen ? 24 : 32,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          _emailSent 
            ? 'Enviamos instruções para redefinir sua senha'
            : 'Digite seu email para receber instruções de recuperação',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 16 : 18,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRequestForm(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Campo de email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
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
              return 'Email é obrigatório';
            }
            if (!value.contains('@')) {
              return 'Email inválido';
            }
            return null;
          },
        ),
        
        SizedBox(height: isSmallScreen ? 24 : 32),
        
        // Botão de solicitar
        PrimaryButton(
          text: 'Enviar Instruções',
          onPressed: _requestPasswordReset,
          size: isSmallScreen ? ButtonSize.medium : ButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildEmailSentContent(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read,
                size: isSmallScreen ? 48 : 64,
                color: Colors.green[600],
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'Verifique sua caixa de entrada',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                'Enviamos um email para ${_emailController.text} com instruções para redefinir sua senha.',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                'Não recebeu o email? Verifique sua pasta de spam.',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: isSmallScreen ? 12 : 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 24 : 32),
        
        // Botões de ação
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reenviar Email'),
                  ],
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: PrimaryButton(
                text: 'Voltar ao Login',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                size: isSmallScreen ? ButtonSize.medium : ButtonSize.large,
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
        // Link para voltar ao login
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Voltar ao login',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 8 : 12),
        
        // Link para criar conta
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
      ],
    );
  }
}
