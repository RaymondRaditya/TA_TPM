import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  // Static API key configured by the user
  final String _groqUrl = dotenv.env['_groqUrl'] ?? '';
  final String _apiKey = dotenv.env['_apiKey'] ?? '';

  // Available Groq models for custom design assistance
  static const List<String> models = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
  ];

  /// Sends a list of chat messages to the Groq API.
  /// [messages] should be a list of maps, where each map has 'role' and 'content' keys.
  /// [apiKey] is the user's Groq API Key, defaulting to the static apiKey above.
  /// [model] is the chosen Groq model, default is 'llama-3.1-8b-instant'.
  Future<String> chatWithGroq({
    required List<Map<String, String>> messages,
    String? apiKey,
    String model = 'llama-3.1-8b-instant',
  }) async {
    if (_groqUrl.isEmpty) {
      return 'Error: Groq URL is not configured. Please check your .env file.';
    }
    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${apiKey ?? _apiKey}',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert T-Shirt and Custom Apparel design assistant for the \'T-Shirt Studio\' app. '
                  'Your job is to help users design custom T-shirts, jackets, hoodies, hats, jerseys, and other apparel. '
                  'Offer advice on: '
                  '1. Design concepts, styles (streetwear, minimalist, vintage, futuristic), and slogans. '
                  '2. Color palettes (using hex codes and combinations). '
                  '3. Print placement (front chest, back print, sleeves, pocket). '
                  '4. Materials and fabrics (e.g. Cotton Combed 30s/24s, Fleece, Baby Terry, Drill, Taslan, etc.). '
                  '5. Printing and production methods (e.g. Sablon Plastisol/Discharge, DTF - Direct to Film, Bordir/Embroidery, Sublimasi/Sublimation). '
                  'Always answer in a friendly, creative, and professional tone. Provide structured responses using bullet points where appropriate. '
                  'Please respond in the same language as the user\'s message (e.g. Indonesian or English).',
            },
            ...messages,
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
        final errorMessage =
            errorData['error']?['message'] ?? 'Unknown API error';
        return 'Error (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      return 'An exception occurred while reaching Groq: $e';
    }
  }
}
