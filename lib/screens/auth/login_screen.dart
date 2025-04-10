import 'dart:convert';
import 'package:flutter/material.dart';
import '../home_screen.dart';
import 'first_access_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnpjCpfController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cnpjCpfController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> authenticateUser(String email, String password, String cgc) async {
    final url = Uri.parse('https://192.168.0.251:8409/rest/VKPCLILOGIN');
    final basicAuth = 'Basic ${base64Encode(utf8.encode('admin:msmvk'))}';

    final body = jsonEncode({
      'email': email,
      'Pass': password,
      'cgc': cgc,
    });

    print('Enviando JSON: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('Resposta da API: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(response.body);

          // Verificar se os campos existem e não são nulos
          if (jsonResponse['sucess'] == true) {
            final codigo = jsonResponse['Codigo']?.toString() ?? '';
            final nome = jsonResponse['Nome']?.toString() ?? '';
            final cgc = jsonResponse['cgc']?.toString() ?? '';
            final email = jsonResponse['email']?.toString() ?? '';

            return {
              'sucess': true,
              'Codigo': codigo,
              'Nome': nome,
              'cgc': cgc,
              'email': email,
            };
          } else {
            return {
              'sucess': false,
              'Codigo': jsonResponse['Codigo']?.toString() ?? 'Cliente não encontrado',
              'Nome': jsonResponse['Nome']?.toString() ?? 'Cliente não encontrado',
              'cgc': jsonResponse['cgc']?.toString() ?? 'Cliente não encontrado',
              'email': jsonResponse['email']?.toString() ?? 'Cliente não encontrado',
            };
          }
        } catch (e) {
          print('Erro ao fazer o parsing do JSON: $e');
          return {'sucess': false, 'Codigo': 'Erro ao fazer o parsing do JSON', 'Nome': 'Erro ao fazer o parsing do JSON', 'cgc': 'Erro ao fazer o parsing do JSON', 'email': 'Erro ao fazer o parsing do JSON'};
        }
      } else {
        print('Erro na requisição: ${response.statusCode}');
        return {'sucess': false, 'Codigo': 'Erro na requisição', 'Nome': 'Erro na requisição', 'cgc': 'Erro na requisição', 'email': 'Erro na requisição'};
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
      return {'sucess': false, 'Codigo': 'Erro durante a requisição', 'Nome': 'Erro durante a requisição', 'cgc': 'Erro durante a requisição', 'email': 'Erro durante a requisição'};
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;
    final cgc = _cnpjCpfController.text;

    final result = await authenticateUser(email, password, cgc);

    if (result['sucess'] == true) {
      // Salvar TODOS os dados relevantes do usuário no SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Salvar o código do cliente (importante para a consulta de pedidos)
      await prefs.setString('CodigoCliente', result['Codigo'] ?? '');
      
      // Salvar outros dados úteis
      await prefs.setString('nomeCliente', result['Nome'] ?? '');
      await prefs.setString('emailCliente', result['email'] ?? '');
      await prefs.setString('cgcCliente', result['cgc'] ?? '');
      
      // Log para depuração
      print('LOGIN BEM-SUCEDIDO: Código do cliente salvo: ${result['Codigo']}');
      print('Dados salvos no SharedPreferences:');
      print('- CodigoCliente: ${prefs.getString('CodigoCliente')}');
      print('- nomeCliente: ${prefs.getString('nomeCliente')}');
      
      // Navegar para a tela principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Login falhou
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email, senha ou CNPJ/CPF incorretos'),
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
                  const SizedBox(height: 40),
                  Text(
                    'Área do Cliente MVK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Image.asset(
                      'assets/images/logo_mvk.png',
                      height: 120,
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
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Insira seu email',
                      prefixIcon: const Icon(Icons.email),
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cnpjCpfController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CNPJ/CPF',
                      hintText: 'Insira seu CNPJ/CPF',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu CNPJ/CPF';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Insira sua senha',
                      prefixIcon: const Icon(Icons.lock),
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
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blue.shade700,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use: teste@empresa.com / 123456'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    },
                    child: const Text('Mostrar credenciais de teste'),
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