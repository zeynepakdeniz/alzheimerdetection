import 'package:flutter/material.dart';
import 'services/chatbot_service.dart'; 

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  TextEditingController _controller = TextEditingController(); 
  List<Map<String, String>> messages = []; 
  ChatbotService _chatbotService = ChatbotService(); 

 
  Future<void> sendMessage() async {
    if (_controller.text.isEmpty) return; 

    String userMessage = _controller.text; 
    setState(() {
      messages.add({'sender': 'user', 'message': userMessage}); 
    });

    try {
      
      String botResponse = await _chatbotService.sendMessage(userMessage);

      setState(() {
        messages.add({'sender': 'bot', 'message': botResponse}); 
      });
    } catch (e) {
      setState(() {
        messages.add({'sender': 'bot', 'message': 'Bot ile iletişim kurulurken hata oluştu.'}); 
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'), 
        backgroundColor: Colors.blueAccent, 
      ),
      body: Column(
        children: [
          
          Expanded(
            child: ListView.builder(
              itemCount: messages.length, 
              itemBuilder: (context, index) {
                bool isUserMessage = messages[index]['sender'] == 'user'; 
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUserMessage ? Colors.blueAccent : Colors.grey[300], 
                        borderRadius: BorderRadius.circular(12), 
                      ),
                      child: Text(
                        messages[index]['message'] ?? '',
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black, 
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller, 
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...', 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30), 
                        borderSide: BorderSide.none, 
                      ),
                      filled: true, 
                      fillColor: Colors.grey[200], 
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Colors.blueAccent, 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}