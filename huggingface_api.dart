import 'dart:convert';
import 'package:http/http.dart' as http;
import 'openai_api.dart';

class HuggingFaceAPI {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';
  static const String _hfToken = 'YOUR_HF_TOKEN';

  static Future<String> detectLanguage(String text) async {
    final url = Uri.parse(
      '$_baseUrl/papluca/xlm-roberta-base-language-detection',
    );
    final headers = {
      'Authorization': 'Bearer $_hfToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'inputs': text});

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        final predictions = data[0] as List;
        if (predictions.isNotEmpty) {
          final topPrediction = predictions[0] as Map;
          return topPrediction['label'] as String;
        }
      }
    }
    throw Exception('Language detection failed: ${response.body}');
  }

  static Future<String> translateToRunyankole(String text) async {
    // Using OpenAI for translation to Runyankore-Rukiga
    return await OpenAIAPI.translateToRunyankore(text);
  }
}
