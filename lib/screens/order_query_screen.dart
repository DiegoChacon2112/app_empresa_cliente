import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path_provider/path_provider.dart';

class OrderQueryScreen extends StatefulWidget {
  const OrderQueryScreen({super.key});

  @override
  _OrderQueryScreenState createState() => _OrderQueryScreenState();
}

void _showMessageDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _OrderQueryScreenState extends State<OrderQueryScreen> {
  bool _todos = false;
  final TextEditingController _dataInicialController = TextEditingController();
  final TextEditingController _dataFinalController = TextEditingController();
  final TextEditingController _numeroPropostaController = TextEditingController();
  final TextEditingController _numeroPedidoController = TextEditingController();
  List<Map<String, dynamic>> _pedidos = [];
  String _codigoCliente = '';
  String _nomeCliente = '';
  bool _isLoading = false;
  bool _searchPerformed = false; // Para controlar se uma busca foi realizada
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    
    // Inicializar a data inicial com 30 dias atrás
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    _dataInicialController.text = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    
    // Inicializar a data final com hoje
    _dataFinalController.text = DateFormat('yyyy-MM-dd').format(now);
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _getCodigoCliente();
  }

  Future<void> _getCodigoCliente() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Obter todos os dados armazenados para debug
    final allKeys = _prefs!.getKeys();
    
    print('DEBUG: Todas as chaves armazenadas no SharedPreferences:');
    for (var key in allKeys) {
      print('- $key: ${_prefs!.get(key)}');
    }
    
    final codigo = _prefs!.getString('CodigoCliente');
    final nome = _prefs!.getString('nomeCliente');
    
    print('DEBUG: Código do cliente recuperado: $codigo');
    print('DEBUG: Nome do cliente recuperado: $nome');
    
    setState(() {
      _codigoCliente = codigo ?? '';
      _nomeCliente = nome ?? '';
      
      if (_codigoCliente.isEmpty) {
        print('AVISO: Código do cliente não encontrado nas preferências. Usando valor padrão para testes.');
        _codigoCliente = '12345'; // Valor de exemplo apenas para testes
      }
    });
  }

  Future<void> _buscarPedidos() async {
    if (_codigoCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código do cliente não encontrado. Faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
    });

    final url = Uri.parse('https://192.168.0.251:8409/rest/VKPCLILPED');
    final basicAuth = 'Basic ${base64Encode(utf8.encode('admin:msmvk'))}';

     // Converter as datas para o formato AAAAMMDD
    String dataInicialFormatada = _dataInicialController.text.replaceAll('-', '');
    String dataFinalFormatada = _dataFinalController.text.replaceAll('-', '');

    // Novo formato do JSON conforme solicitado, incluindo o código do cliente
    final body = jsonEncode({
      'Todos': _todos ? 'Sim' : 'Não',
      'Datainicio': dataInicialFormatada,
      'Datafim': dataFinalFormatada,
      'Proposta': _numeroPropostaController.text,
      'Pedido': _numeroPedidoController.text,
      'CodigoCliente': _codigoCliente  // Adicionado o código do cliente aqui
    });

    print('DEBUG: Enviando JSON para API: $body');
    print('DEBUG: Código do cliente enviado: $_codigoCliente');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      print('DEBUG: Resposta da API: ${response.statusCode}');
      print('DEBUG: Corpo da resposta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['success'] == true) {
            print('DEBUG: Pedidos encontrados: ${jsonResponse['pedido']}');
            setState(() {
              _pedidos = List<Map<String, dynamic>>.from(jsonResponse['pedido']);
            });
            
            if (_pedidos.isEmpty) {
              _showMessageDialog('Nenhum pedido encontrado', 'Não foram encontrados pedidos com os critérios selecionados.');
            }
          } else {
            print('DEBUG: Nenhum pedido encontrado (success=false)');
            setState(() {
              // Se success for false, a API retorna um único item com mensagem de pedido não encontrado
              _pedidos = [];
            });
            _showMessageDialog('Nenhum pedido encontrado', 'Não foram encontrados pedidos com os critérios selecionados.');
          }
        } catch (e) {
          print('ERRO: Parsing do JSON: $e');
          _showMessageDialog('Erro', 'Erro ao processar a resposta do servidor: $e');
          setState(() {
            _pedidos = [];
          });
        }
      } else {
        print('ERRO: Requisição: ${response.statusCode}');
        _showMessageDialog('Erro de Conexão', 'Erro ao comunicar com o servidor. Código: ${response.statusCode}');
        setState(() {
          _pedidos = [];
        });
      }
    } catch (e) {
      print('ERRO: Durante a requisição: $e');
      _showMessageDialog('Erro de Conexão', 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.');
      setState(() {
        _pedidos = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      // Converte a data no formato YYYY/MM/DD para DD/MM/YYYY
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de Pedidos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Widget de depuração (apenas em modo de debug)
        
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros de Busca',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Switch para Todos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Todos os Pedidos:',
                          style: TextStyle(fontSize: 16),
                        ),
                        FlutterSwitch(
                          width: 55.0,
                          height: 25.0,
                          valueFontSize: 12.0,
                          toggleSize: 18.0,
                          value: _todos,
                          borderRadius: 30.0,
                          padding: 4.0,
                          showOnOff: true,
                          activeText: 'Sim',
                          inactiveText: 'Não',
                          onToggle: (value) {
                            setState(() {
                              _todos = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Campos de filtro (desabilitados se "Todos" estiver ativo)
                    AbsorbPointer(
                      absorbing: _todos,
                      child: Opacity(
                        opacity: _todos ? 0.5 : 1.0,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dataInicialController,
                                    decoration: InputDecoration(
                                      labelText: 'Data Inicial',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      suffixIcon: const Icon(Icons.calendar_today),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                        locale: const Locale('pt', 'BR'),
                                      );
                                      if (pickedDate != null) {
                                        String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                        setState(() {
                                          _dataInicialController.text = formattedDate;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _dataFinalController,
                                    decoration: InputDecoration(
                                      labelText: 'Data Final',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      suffixIcon: const Icon(Icons.calendar_today),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                        locale: const Locale('pt', 'BR'),
                                      );
                                      if (pickedDate != null) {
                                        String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                        setState(() {
                                          _dataFinalController.text = formattedDate;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _numeroPropostaController,
                                    decoration: InputDecoration(
                                      labelText: 'Número da Proposta',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _numeroPedidoController,
                                    decoration: InputDecoration(
                                      labelText: 'Número do Pedido',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Botão de busca
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text(
                          'Buscar Pedidos',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _buscarPedidos,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Indicador de carregamento
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Consultando pedidos...'),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_searchPerformed) 
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Resultados da Busca',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    if (_searchPerformed && _pedidos.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum pedido encontrado',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tente modificar os filtros de busca',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_searchPerformed)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _pedidos.length,
                          itemBuilder: (context, index) {
                            final pedido = _pedidos[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  'Pedido: ${pedido['Numero'] ?? "N/A"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Data: ${_formatDate(pedido['Data'] ?? "N/A")}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  // Exibir detalhes do pedido ao clicar
                                  _showPedidoDetails(context, pedido);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showPedidoDetails(BuildContext context, Map<String, dynamic> pedido) {
  // Primeiro buscamos os detalhes do pedido na API
  _fetchPedidoDetails(context, pedido['Numero']);
}

// Função para gerar a nota fiscal em PDF
Future<void> _generateNotaFiscalPDF(BuildContext context, String chaveAcesso) async {
  final url = Uri.parse('https://192.168.0.251:8409/rest/VKPCLIPNF');
  final basicAuth = 'Basic ${base64Encode(utf8.encode('admin:msmvk'))}';

  // Mostrar carregamento enquanto o PDF é gerado
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // Enviar a chave de acesso para a API
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode({"chaveacesso": chaveAcesso}),
    );


    if (response.statusCode == 200) {
      // Decodificar o JSON e o Base64
      final decodedResponse = jsonDecode(response.body);
      final pdfBase64 = decodedResponse['PDF64'];

      if (pdfBase64 != null) {
        // Decodificar a string Base64 para bytes
        final pdfBytes = base64Decode(pdfBase64);

        // Salvar o arquivo PDF localmente
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/nota_fiscal_$chaveAcesso.pdf';
        final pdfFile = File(filePath);
        await pdfFile.writeAsBytes(pdfBytes);

        // Fechar o diálogo de carregamento
        Navigator.of(context).pop();

        // Exibir uma mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nota Fiscal gerada com sucesso! Arquivo salvo em: $filePath'),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () {
                // Abrir o arquivo PDF (implementar caso necessário)
              },
            ),
          ),
        );
      } else {
        throw Exception('PDF64 não encontrado na resposta.');
      }
    } else {
      throw Exception('Erro na API: Código ${response.statusCode}');
    }
  } catch (error) {
    // Fechar o diálogo de carregamento
    Navigator.of(context).pop();

    // Exibir mensagem de erro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao gerar Nota Fiscal: $error'),
      ),
    );
  }
}

Future<void> _fetchPedidoDetails(BuildContext context, String numeroPedido) async {
  // Adicionando o contexto como parâmetro para resolver o problema
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  final url = Uri.parse('https://192.168.0.251:8409/rest/VKPCLIDPED');
  final basicAuth = 'Basic ${base64Encode(utf8.encode('admin:msmvk'))}';

  
  try {
    print('DEBUG: Buscando detalhes do pedido: $numeroPedido');
    final body = jsonEncode({
      'pedido': numeroPedido
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    print('DEBUG: Corpo da resposta: ${response.body}');

    // Fechar o diálogo de carregamento
    Navigator.of(context).pop();

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        // Corrigir JSON mal-formado (se necessário)
        String responseBody = response.body;
        responseBody = responseBody.replaceAll(RegExp(r',(\s*[\]}])'), r'$1');
        
        final detalhes = jsonDecode(responseBody);
        _showDetailBottomSheet(context, numeroPedido, detalhes);
      } catch (e) {
        print('ERRO: Parsing do JSON de detalhes: $e');
        _showMessageDialog(context, 'Erro', 'Erro ao processar os detalhes do pedido: $e');
      }
    } else {
      print('ERRO: Requisição detalhes: ${response.statusCode}');
      _showMessageDialog(context, 'Erro de Conexão', 'Erro ao buscar detalhes do pedido. Código: ${response.statusCode}');
    }
  } catch (e) {
    // Fechar o diálogo de carregamento em caso de erro
    Navigator.of(context).pop();
    
    print('ERRO: Durante a requisição de detalhes: $e');
    _showMessageDialog(context, 'Erro de Conexão', 'Não foi possível obter os detalhes do pedido. Verifique sua conexão com a internet.');
  }
}

void _showDetailBottomSheet(context, String numeroPedido, Map<String, dynamic> detalhes) {
  // Formatar valores monetários
  final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final totalPedido = double.tryParse(detalhes['totalpedido'].toString()) ?? 0.0;
  
  // Armazenar a chave de acesso da nota fiscal
  final String? chaveAcesso = detalhes['chaveacesso'];

  // Extrair status
  final statusList = detalhes['status'] as List;
  final status = statusList.isNotEmpty ? statusList[0] as Map<String, dynamic> : {};
  
  final conferido = status['conferido']?.toString().toLowerCase() == 'sim';
  final producaoIniciada = status['producaoiniciada']?.toString().toLowerCase() == 'sim';
  final producaoConcluida = status['Producaoconcluida']?.toString().toLowerCase() == 'sim';
  final faturado = status['faturado']?.toString().toLowerCase() == 'sim';
  final expedido = status['expedido']?.toString().toLowerCase() == 'sim';
  
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      // Altura máxima para evitar problemas com teclados virtuais
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Detalhes do Pedido $numeroPedido',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bloco de informações do pedido
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações Gerais',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Número do Pedido', numeroPedido),
                          _buildDetailRow('Número da Proposta', detalhes['proposta']?.toString() ?? "Não informado"),
                          _buildDetailRow('Transportadora', detalhes['transportadora']?.toString() ?? "Não informada"),
                          _buildDetailRow('Tipo de Operação', detalhes['tipooperacao']?.toString() ?? "Não informado"),
                          const Divider(),
                          _buildDetailRow('Total do Pedido', 
                            formatoMoeda.format(totalPedido),
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bloco de status do pedido
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status do Pedido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Barra de progresso com status
                          SizedBox(
                            height: 100,
                            child: Row(
                              children: [
                                _buildStatusStep('Conferido', conferido, 1),
                                _buildStatusConnector(conferido && producaoIniciada),
                                _buildStatusStep('Produção\nIniciada', producaoIniciada, 2),
                                _buildStatusConnector(producaoIniciada && producaoConcluida),
                                _buildStatusStep('Produção\nConcluída', producaoConcluida, 3),
                                _buildStatusConnector(producaoConcluida && faturado),
                                _buildStatusStep('Faturado', faturado, 4),
                                _buildStatusConnector(faturado && expedido),
                                _buildStatusStep('Expedido', expedido, 5),
                              ],
                            ),
                          ),

                           if (faturado)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('Gerar Nota Fiscal'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 190, 211, 236),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Função para gerar a nota fiscal
                                    if (chaveAcesso != null) {
                                      _generateNotaFiscalPDF(context, chaveAcesso);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Chave de acesso não disponível.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botões de ação
                  Center(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Visualizar PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Função de visualização de PDF será implementada em breve.'),
                              ),
                            );
                          },
                        ),
                        
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Função de compartilhamento será implementada em breve.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



Widget _buildStatusStep(String label, bool completed, int step) {
  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: completed ? Colors.green : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? Colors.green.shade700 : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: completed 
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  step.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: completed ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: completed ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatusConnector(bool active) {
  return Container(
    width: 15,
    height: 4,
    color: active ? Colors.green : Colors.grey.shade300,
  );
}

Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ?? const TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

