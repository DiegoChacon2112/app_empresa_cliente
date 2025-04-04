import 'package:flutter/material.dart';
import '../home_screen.dart';
import 'first_access_screen.dart';  // Vamos criar esta tela a seguir

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simular um atraso de rede
    await Future.delayed(Duration(seconds: 2));

    // Verificar credenciais simples
    if (_emailController.text == 'teste@empresa.com' && 
        _passwordController.text == '123456') {
      // Login bem-sucedido - navegue para a tela principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Login falhou
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email ou senha incorretos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToFirstAccess() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FirstAccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40),
                  
                  // Título "Area do Cliente MVK"
                  Text(
                    'Área do Cliente MVK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Logo da empresa
                  Center(
                    child: Image.asset(
                      'assets/images/logo_mvk.png',  // Substitua pelo nome do seu arquivo
                      height: 120,
                      // Se a imagem não existir durante o desenvolvimento, use um placeholder
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: 200,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Text(
                              'Logo MVK',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: 50),
                  
                  // Campo de Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Insira seu email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Campo de Senha
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Insira sua senha',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Botão de Login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blue.shade700,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Link para primeiro acesso
                  InkWell(
                    onTap: _navigateToFirstAccess,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Primeiro acesso? Clique aqui e solicite seu usuário e senha.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Botão para mostrar credenciais de teste (somente durante desenvolvimento)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Use: teste@empresa.com / 123456'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    },
                    child: Text('Mostrar credenciais de teste'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}