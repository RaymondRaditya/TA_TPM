import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tpm_ta/services/groq_service.dart';

class AiDesignAssistantScreen extends StatefulWidget {
  const AiDesignAssistantScreen({super.key});

  @override
  State<AiDesignAssistantScreen> createState() =>
      _AiDesignAssistantScreenState();
}

class _AiDesignAssistantScreenState extends State<AiDesignAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GroqService _groqService = GroqService();

  String _selectedModel = 'llama-3.1-8b-instant';
  bool _isLoadingSettings = true;
  bool _isSending = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Halo! Saya asisten desain pakaian kustom Anda. '
          'Saya bisa membantu Anda merancang konsep desain, memilih slogan, '
          'menentukan palet warna, memilih bahan kain yang cocok, hingga teknik cetak/sablon untuk kaos, jaket, hoodie, topi, dll.\n\n'
          'Ada ide pakaian apa yang ingin Anda buat hari ini?',
    },
  ];

  final List<String> _suggestions = [
    'Ide desain kaos streetwear bertema teknologi',
    'Rekomendasi bahan jaket anti air & sablonnya',
    'Slogan keren untuk kaos vintage band Bali',
    'Kombinasi warna hoodie hitam bertema cyberpunk',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    setState(() {
      _isLoadingSettings = true;
    });

    try {
      final savedModel = await _secureStorage.read(key: 'groq_model');
      if (savedModel != null && savedModel.isNotEmpty) {
        _selectedModel = savedModel;
      }
    } catch (e) {
      debugPrint('Error loading saved Groq settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textPrompt]) async {
    final query = textPrompt ?? _messageController.text.trim();
    if (query.isEmpty) return;

    if (textPrompt == null) {
      _messageController.clear();
    }

    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final apiMessages = _messages
          .where((m) => m['content'] != null && m['content']!.isNotEmpty)
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();

      final response = await _groqService.chatWithGroq(
        messages: apiMessages,
        model: _selectedModel,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Maaf, terjadi kesalahan saat menghubungi asisten AI: $e',
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'assistant',
        'content':
            'Chat dikosongkan. Ada konsep desain custom pakaian baru yang ingin Anda bahas?',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return Scaffold(
        appBar: AppBar(title: const Text('Groq AI Assistant')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groq AI Assistant'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Kosongkan Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: _buildChatInterface(),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Model badge and status info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 10),
                  const SizedBox(width: 8),
                  Text(
                    'Model: $_selectedModel',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
              GesturefulDropdownBadge(
                currentModel: _selectedModel,
                onChanged: (newModel) async {
                  if (newModel != null) {
                    setState(() => _selectedModel = newModel);
                    await _secureStorage.write(
                      key: 'groq_model',
                      value: newModel,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        // Conversation List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message['role'] == 'user';
              return _buildMessageBubble(message['content'] ?? '', isUser);
            },
          ),
        ),
        // Loading status
        if (_isSending)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.deepPurple.shade300,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Asisten sedang mengetik...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        // Suggestions Chips (only show when not generating/sending)
        if (!_isSending && _messages.length <= 2)
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(
                      _suggestions[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.deepPurple.shade50,
                    side: BorderSide(color: Colors.deepPurple.shade100),
                    onPressed: () => _sendMessage(_suggestions[index]),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 6),
        // Message Input
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    final bgColor = isUser ? Colors.deepPurple.shade600 : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : Colors.black87;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final roundedSide = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: roundedSide,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(color: textColor, height: 1.35),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isUser ? 'Anda' : 'Asisten Desain',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pesan disalin ke papan klip!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tanyakan ide kaos, bahan jaket, sablon...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GesturefulDropdownBadge extends StatelessWidget {
  final String currentModel;
  final ValueChanged<String?> onChanged;

  const GesturefulDropdownBadge({
    super.key,
    required this.currentModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Pilih model alternatif',
      onSelected: onChanged,
      itemBuilder: (context) {
        return GroqService.models
            .map(
              (model) => PopupMenuItem(
                value: model,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: model == currentModel
                          ? Colors.deepPurple
                          : Colors.transparent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(model),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Row(
          children: [
            Text(
              'Ganti Model',
              style: TextStyle(
                fontSize: 11,
                color: Colors.deepPurple.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: Colors.deepPurple.shade800,
            ),
          ],
        ),
      ),
    );
  }
}
