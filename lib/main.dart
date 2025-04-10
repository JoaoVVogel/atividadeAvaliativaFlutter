import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VeioApp',
      theme: ThemeData(
        primaryColor: const Color(0xFF075E54),
        scaffoldBackgroundColor: const Color(0xFF424242),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF075E54),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF25D366),
        ),
      ),
      home: const ElderCareChatScreen(),
    );
  }
}

class ElderCareChatScreen extends StatefulWidget {
  const ElderCareChatScreen({Key? key}) : super(key: key);

  @override
  State<ElderCareChatScreen> createState() => _ElderCareChatScreenState();
}

class _ElderCareChatScreenState extends State<ElderCareChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({'sender': 'bot', 'text': 'Como podemos te ajudar hoje?'});
  }

  Future<void> _sendMessage() async {
    final String userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final String apiKey = 'AIzaSyByNl11D03ZbtEZI5Sl-jEBfczthRScpQ8';
      final String apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

      final String prompt = '''
        O usuário enviou a seguinte mensagem ou pergunta: "$userMessage"
        
        Por favor, forneça uma resposta prática e útil para auxiliar no cuidado de idosos. A resposta deve incluir informações relevantes sobre saúde, segurança, alimentação, exercícios ou cuidados gerais com idosos. Seja claro, objetivo e útil.
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 800,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String content =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({'sender': 'bot', 'text': content});
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text':
                'Erro ao obter resposta: ${response.statusCode}\n${response.body}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Erro ao conectar com a API: $e',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('../VeioApp.png', height: 50),
            const SizedBox(width: 8),
            const Text('VeioApp'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          isUser
                              ? const Color(0xFFECE5DD)
                              : const Color(0xFFDCF8C6),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child:
                        isUser
                            ? Text(
                              message['text']!,
                              style: const TextStyle(fontSize: 16),
                            )
                            : MarkdownBody(
                              data: message['text']!,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 16),
                              ),
                            ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          Colors.white,
                      hintText: 'Digite sua mensagem ou pergunta...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
