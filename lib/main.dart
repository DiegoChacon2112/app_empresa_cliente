import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  // Garantir que o Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Portal do Cliente',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Use uma abordagem mais simples - inicie com SplashScreen
        home: SplashScreenWrapper(),
      ),
    );
  }
}

// Nova classe para gerenciar a transição do splash
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Navegue para a próxima tela após um atraso fixo
    _navigateToNextScreen();
  }

  // Função simples para navegar para a tela de login após 3 segundos
  Future<void> _navigateToNextScreen() async {
    // Espere 3 segundos
    await Future.delayed(const Duration(seconds: 3));
    
    // Verifique se o widget ainda está montado
    if (!mounted) return;
    
    // Navegue para a tela de login (por enquanto, sempre vai para login)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }
}

// Placeholder para a tela inicial do app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal do Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Logout do usuário
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bem-vindo ao Portal do Cliente!'),
      ),
    );
  }
}