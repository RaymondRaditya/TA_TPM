import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatService {
  // Retrieve the Groq configuration from environment variables
  final String _groqUrl = dotenv.env['_groqUrl'] ?? '';
  final String _apiKey = dotenv.env['_apiKey'] ?? '';

  Future<String> askDesignAssistant(String query) async {
    if (_apiKey.isEmpty || _groqUrl.isEmpty) {
      return 'Error: Groq configuration (URL/Key) is missing in .env file.';
    }

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert T-shirt design assistant. Keep answers short and creative.'
            },
            {
              'role': 'user',
              'content': query
            },
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return content?.toString().trim() ?? 'No response received from Groq.';
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorData['error']?['message'] ?? 'Unknown API error';
        return 'Error (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      return 'An exception occurred while reaching the design assistant: $e';
    }
  }
}
