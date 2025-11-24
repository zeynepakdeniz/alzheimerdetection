import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String apiKey = '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'; 
  static const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions'; 
  
  static const String siteUrl = 'https://your-site-url.com'; 
  static const String siteName = 'Your Site Name'; 

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': siteUrl, 
          'X-Title': siteName, 
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "model": "gpt-3.5-turbo", 
          "messages": [
            {"role": "system", "content": "Türkçe cevap ver."}, 
            {"role": "user", "content": message} 
          ],
        }),
      );

   
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)); 
        print('API Yanıtı: $data'); 

      
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ?? 'Chatbot yanıt vermedi.';
        } else {
          return 'Chatbot yanıt formatı beklenenden farklı.';
        }
      } else {
        print('API Hata: ${response.statusCode}, Body: ${response.body}'); 
        throw Exception('API Hata: ${response.statusCode}');
      }
    } catch (e) {
    
      print('Hata detayı: $e');
      throw Exception('Chatbot ile iletişim kurulamadı: $e');
    }
  }
}