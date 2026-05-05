import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiDesignAssistantScreen extends StatefulWidget {
  const AiDesignAssistantScreen({super.key});

  @override
  State<AiDesignAssistantScreen> createState() =>
      _AiDesignAssistantScreenState();
}

class _AiDesignAssistantScreenState extends State<AiDesignAssistantScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _briefController = TextEditingController(
    text: 'A streetwear T-shirt for a campus technology event',
  );

  String _selectedTone = 'Minimal';
  String _selectedAudience = 'Students';
  String _response = '';
  bool _isGenerating = false;

  static const List<String> _tones = [
    'Minimal',
    'Bold',
    'Vintage',
    'Futuristic',
  ];

  static const List<String> _audiences = [
    'Students',
    'Developers',
    'Tourists',
    'Streetwear fans',
  ];

  Future<void> _generateRecommendation() async {
    final apiKey = _apiKeyController.text.trim();
    final brief = _briefController.text.trim();

    if (apiKey.isEmpty || brief.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a Gemini API key and design brief first.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _response = '';
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      final prompt = '''
You are a T-shirt studio creative assistant.
Create a concise production-ready recommendation for this design brief:
"$brief"

Tone: $_selectedTone
Audience: $_selectedAudience

Return exactly these sections:
1. Concept
2. Slogan
3. Color Palette
4. Print Placement
5. Production Notes

Keep it practical for a custom T-shirt app.
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (!mounted) return;
      setState(() {
        _response = response.text?.trim() ?? 'No recommendation returned.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _response = 'AI generation failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _applySampleBrief(String brief) {
    setState(() => _briefController.text = brief);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Design Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInputPanel(),
          const SizedBox(height: 16),
          _buildSampleBriefs(),
          const SizedBox(height: 16),
          _buildResultPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LLM-Powered Shirt Brief',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Generate concept, slogan, palette, placement, and production notes.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _briefController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Design Brief',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTone,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tone',
                      border: OutlineInputBorder(),
                    ),
                    items: _tones
                        .map(
                          (tone) => DropdownMenuItem<String>(
                            value: tone,
                            child: Text(tone),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedTone = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAudience,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Audience',
                      border: OutlineInputBorder(),
                    ),
                    items: _audiences
                        .map(
                          (audience) => DropdownMenuItem<String>(
                            value: audience,
                            child: Text(audience),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedAudience = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateRecommendation,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Recommendation',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleBriefs() {
    const briefs = [
      'A bold black T-shirt for a mobile programming final project demo',
      'A retro beach shirt for a Bali pop-up merchandise drop',
      'A clean white shirt for a London tech meetup',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: briefs
          .map(
            (brief) => ActionChip(
              avatar: const Icon(Icons.lightbulb_outline, size: 18),
              label: Text(brief),
              onPressed: () => _applySampleBrief(brief),
            ),
          )
          .toList(),
    );
  }

  Widget _buildResultPanel() {
    if (_response.isEmpty) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('AI recommendations will appear here.'),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SelectableText(
          _response,
          style: const TextStyle(height: 1.35),
        ),
      ),
    );
  }
}
