import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  // NOTE: Replace this with your actual Gemini API Key from Google AI Studio.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  // Using gemini-1.5-flash as it is fast and suitable for short creative tasks
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  Future<String> askDesignAssistant(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "system_instruction": {
            "parts": {
              "text":
                  "You are an expert T-shirt design assistant. Keep answers short and creative.",
            },
          },
          "contents": [
            {
              "parts": [
                {"text": query},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Parse the standard Gemini response JSON structure
        final textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];
        return textResponse?.toString().trim() ?? 'No response received.';
      } else {
        return 'Error communicating with AI: ${response.statusCode}';
      }
    } catch (e) {
      return 'An exception occurred while reaching the design assistant: $e';
    }
  }
}
