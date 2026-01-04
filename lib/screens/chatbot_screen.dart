import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/kalori_chatbot_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final KaloriChatbotService _service = KaloriChatbotService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _apiConnected = false;

  @override
  void initState() {
    super.initState();
    _checkApiConnection();
    // Hoş geldin mesajı
    _messages.add(ChatMessage(
      text: 'Merhaba! 👋\n\nNe yediğinizi yazın, size kalori miktarını hesaplayayım.\n\nÖrnek: "2 adet yumurta ve 1 dilim ekmek yedim"',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _checkApiConnection() async {
    final connected = await _service.checkHealth();
    setState(() {
      _apiConnected = connected;
    });
    if (!connected) {
      _addBotMessage(
        '⚠️ API bağlantısı yok. Lütfen backend API\'nin çalıştığından emin olun.\n\nAPI\'yi başlatmak için:\n1. api/ klasörüne gidin\n2. python app.py komutunu çalıştırın',
      );
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // API'ye istek gönder
    final response = await _service.predictCalories(text);

    setState(() {
      _isLoading = false;
    });

    // Bot yanıtını oluştur
    String botResponse = '';
    if (response.success) {
      if (response.details.isNotEmpty) {
        botResponse = '📊 **Besin Analizi:**\n\n';
        for (var detail in response.details) {
          botResponse +=
              '• ${detail.amount}g ${detail.food} (${detail.method}): ${detail.calories.toStringAsFixed(1)} kcal\n';
          botResponse +=
              '   → P: ${detail.protein.toStringAsFixed(1)}g | Y: ${detail.fat.toStringAsFixed(1)}g | K: ${detail.carbs.toStringAsFixed(1)}g\n';
        }
        botResponse += '\n🍽️ **TOPLAM DEĞERLER:**\n';
        botResponse += '🔥 Kalori: ${response.totalCalories.toStringAsFixed(1)} kcal\n';
        botResponse += '🥩 Protein: ${response.totalProtein.toStringAsFixed(1)} g\n';
        botResponse += '🧈 Yağ: ${response.totalFat.toStringAsFixed(1)} g\n';
        botResponse += '🍞 Karbonhidrat: ${response.totalCarbs.toStringAsFixed(1)} g';
      } else {
        botResponse = response.message;
      }
    } else {
      botResponse = '❌ ${response.message}';
    }

    _addBotMessage(botResponse);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      foregroundColor: Colors.white, // Geri butonu ve genel yazı rengini beyaz yapar
      backgroundColor: Theme.of(context).colorScheme.primary, // Yeşil arka plan
      title: Row(
        mainAxisSize: MainAxisSize.min, // Row'un alanı gereksiz kaplamasını önler
        children: [
          // DÜZELTME: İkon rengi beyaza çekildi
          const Icon(Icons.smart_toy, color: Colors.white), 
          const SizedBox(width: 8),
          Text(
            'Kalori Asistanı',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white, // Yazı renginin beyaz olduğundan emin oluyoruz
            ),
          ),
        ],
      ),
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _apiConnected ? Icons.check_circle : Icons.error_outline,
            // DÜZELTME: Bağlıyken yeşil yerine beyaz (veya açık gri) yapıyoruz
            color: _apiConnected ? Colors.white : Colors.orangeAccent, 
          ),
          onPressed: _checkApiConnection,
          tooltip: 'API Durumu',
        ),
      ],
    ),
    backgroundColor: const Color(0xFFF5F5F5),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) {
                return _buildLoadingIndicator();
              }
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),
        _buildInputArea(),
      ],
    ),
    bottomNavigationBar: const AppBottomNavigation(),
  );
}

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF4CAF50)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.poppins(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: GoogleFonts.poppins(
                color: message.isUser
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Hesaplanıyor...',
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ne yediniz? (örn: 2 adet yumurta)',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isLoading
                    ? Colors.grey
                    : const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

