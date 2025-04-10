import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'order_query_screen.dart'; // Importe a tela de consulta de pedidos

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nomeCliente = 'Portal do Cliente'; // Valor padrão

  @override
  void initState() {
    super.initState();
    _getNomeCliente();
  }

  Future<void> _getNomeCliente() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeCliente = prefs.getString('nomeCliente') ?? 'Portal do Cliente';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nomeCliente), // Exibir o nome do cliente
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Navegue de volta para a tela de login
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bem-vindo ao Portal do Cliente!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Essa é uma versão de demonstração inicial do aplicativo. As funcionalidades de histórico de pedidos, notas fiscais e financeiro serão implementadas nas próximas etapas.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildFeatureCard(
              context,
              'Meus Pedidos',
              'Veja o histórico de pedidos e status atual',
              Icons.shopping_cart,
              Colors.blue,
              () { // Adicionado o callback para a navegação
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderQueryScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Notas Fiscais',
              'Acesse suas notas fiscais',
              Icons.receipt,
              Colors.green,
                  () { // Adicionado o callback para a navegação
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Financeiro',
              'Consulte pagamentos e faturas',
              Icons.account_balance_wallet,
              Colors.purple,
                  () { // Adicionado o callback para a navegação
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle, IconData icon, Color color, [VoidCallback? onTap]) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap, // Usar o callback para a navegação
      ),
    );
  }
}