import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class FirstAccessScreen extends StatefulWidget {
  const FirstAccessScreen({super.key});

  @override
  _FirstAccessScreenState createState() => _FirstAccessScreenState();
}

class _FirstAccessScreenState extends State<FirstAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _razaoSocialController = TextEditingController();
  final _cnpjCpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _termsAgreed = false;
  
  // Máscara para telefone
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _razaoSocialController.dispose();
    _cnpjCpfController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Função para enviar o email
  Future<bool> _sendEmail() async {
    // Configurações do servidor SMTP
    final smtpServer = SmtpServer(
      'email-ssl.com.br',
      username: 'portaldocliente@mvk.com.br',
      password: '@Vendas3200', // Senha omitida por razões de segurança
      port: 465,
      ssl: true,
      allowInsecure: false,
      ignoreBadCertificate: false
    );

    final message = Message()
      ..from = const Address('portaldocliente@mvk.com.br', 'Portal do Cliente MVK')
      ..recipients.add('diego.chacon@mvk.com.br')
      ..subject = 'Nova solicitação de acesso - ${_razaoSocialController.text}'
      ..html = '''
        <h2>Nova solicitação de acesso recebida</h2>
        <table style="border-collapse: collapse; width: 100%;">
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Razão Social:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">${_razaoSocialController.text}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">CNPJ/CPF:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">${_cnpjCpfController.text}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">E-mail:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">${_emailController.text}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Nome Completo:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">${_nameController.text}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Telefone/Whatsapp:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">${_phoneController.text}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Data da solicitação:</td>
            <td style="padding: 8px; border: 1px solid #ddd;">${DateTime.now().toString()}</td>
          </tr>
        </table>
        <p>Esta solicitação foi enviada através do aplicativo do Portal do Cliente.</p>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email enviado: ${sendReport.toString()}');
      return true;
    } on MailerException catch (e) {
      print('Erro ao enviar email: $e');
      for (var p in e.problems) {
        print('Problema: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Erro desconhecido ao enviar email: $e');
      return false;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_termsAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você precisa concordar com os termos para continuar.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool emailSent = await _sendEmail();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (emailSent) {
          // Limpar os campos após o envio bem-sucedido
          _formKey.currentState!.reset();
          _razaoSocialController.clear();
          _cnpjCpfController.clear();
          _emailController.clear();
          _nameController.clear();
          _phoneController.clear();
          setState(() {
            _termsAgreed = false;
          });
          
          // Mostrar mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Solicitação enviada com sucesso! Entraremos em contato em breve.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          // Voltar para a tela de login após 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          // Mostrar mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro ao enviar o email. Tente novamente mais tarde.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao enviar a solicitação. Tente novamente mais tarde.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Acesso'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Preencha os dados para solicitar seu acesso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Campo Razão Social
                  TextFormField(
                    controller: _razaoSocialController,
                    decoration: InputDecoration(
                      labelText: 'Razão Social',
                      hintText: 'Insira a razão social da empresa',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a razão social';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo CNPJ/CPF
                  TextFormField(
                    controller: _cnpjCpfController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CNPJ/CPF',
                      hintText: 'Insira o CNPJ ou CPF',
                      prefixIcon: const Icon(Icons.assignment_ind),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o CNPJ ou CPF';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
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
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Por favor, insira um email válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo Nome Completo
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      hintText: 'Insira seu nome completo',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome completo';
                      }
                      if (!value.contains(' ')) {
                        return 'Por favor, insira seu nome completo com sobrenome';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo Telefone/Whatsapp
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMaskFormatter],
                    decoration: InputDecoration(
                      labelText: 'Telefone/Whatsapp',
                      hintText: '(00) 00000-0000',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu telefone';
                      }
                      if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                        return 'Por favor, insira um número de telefone válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Caixa de seleção de concordância com os termos
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Ao preencher e enviar as informações solicitadas neste formulário, você, como cliente, concorda voluntariamente em compartilhar os dados informados. Esses dados serão utilizados exclusivamente para geração do ser cadastro em nosso portal e tratados em conformidade com as normas de proteção de dados vigentes, incluindo a Lei Geral de Proteção de Dados (Lei nº 13.709/2018).',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAgreed,
                              onChanged: (value) {
                                setState(() {
                                  _termsAgreed = value!;
                                });
                              },
                              activeColor: Colors.blue.shade700,
                            ),
                            const Expanded(
                              child: Text(
                                'Concordo com os termos acima',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botão de Enviar Solicitação
                  ElevatedButton(
                    onPressed: _isLoading || !_termsAgreed ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blue.shade700,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'ENVIAR SOLICITAÇÃO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Texto explicativo
                  Text(
                    'Após o envio da solicitação, nossa equipe irá analisar e entrar em contato para confirmar seus dados e liberar o acesso.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
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