import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIAPI {
  static const String apiKey = 'YOUR_OPENAI_API_KEY';

  static Future<String> translateToRunyankore(String text) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4.1-mini',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a translator. Translate the following text to Runyankore-Rukiga language. Only provide the translation, no additional text.',
        },
        {'role': 'user', 'content': text},
      ],
    });
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Translation failed: ${response.body}');
    }
  }
}
