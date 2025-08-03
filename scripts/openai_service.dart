import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService {
  final String apiKey;
  final String model;

  OpenAIService(this.apiKey, this.model);

  Future<Map<String, dynamic>?> getResponse(String prompt) async {
    try {
      print("Sending request to OpenAI...");
      var response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": 'gpt-4-turbo',
          "messages": [
            {
              "role": "system",
              "content":
                  "Only respond with JSON object data. In short answer justifications (inside the JSON object response), refer to the user with 'You' and 'Your' instead of 'The user'."
            },
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.3,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];

        // Clean and parse the assistant's response
        content = content.trim();
        if (content.startsWith('```')) {
          content = content.substring(
              content.indexOf('\n') + 1, content.lastIndexOf('```'));
        }

        Map<String, dynamic> parsedContent = jsonDecode(content);

        // Ensure the parsed content is of the correct type
        parsedContent = Map<String, dynamic>.from(parsedContent);

        return parsedContent;
      } else {
        // Handle API errors
        print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
    }
  }
}
