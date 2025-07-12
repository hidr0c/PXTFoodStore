import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/services/ai_chat_service.dart';
import 'package:intl/intl.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _aiChatService = AIChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];
  int _remainingMessages = 10;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _checkRemainingMessages();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final chatHistory = await _aiChatService.getChatHistory(user.uid);
        if (mounted) {
          setState(() {
            _messages = chatHistory;
            _isLoading = false;
          });

          // Scroll to bottom after loading messages
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
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkRemainingMessages() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final remaining = await _aiChatService.getRemainingMessages(user.uid);
        if (mounted) {
          setState(() {
            _remainingMessages = remaining;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking remaining messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear text field immediately for better UX
    _messageController.clear();

    // Check if user is logged in
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đăng nhập để sử dụng trò chuyện AI')),
      );
      return;
    }

    // Check remaining messages
    if (_remainingMessages <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Bạn đã sử dụng hết số lần trò chuyện hôm nay. Vui lòng thử lại vào ngày mai.')),
      );
      return;
    }

    // Add user message to UI immediately
    setState(() {
      _messages.insert(0, {
        'id': DateTime.now().toString(),
        'message': message,
        'timestamp': DateTime.now(),
        'isUser': true,
      });
    });

    // Scroll to bottom after adding message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Show typing indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Send message to AI and get response
      final response = await _aiChatService.sendMessageToAI(message);

      if (mounted) {
        // Remove typing indicator
        setState(() {
          _isLoading = false;

          // Add AI response to UI
          if (response != null) {
            _messages.insert(0, {
              'id': DateTime.now().toString(),
              'message': response,
              'timestamp': DateTime.now(),
              'isUser': false,
            });
          }
        });

        // Update remaining messages count
        _checkRemainingMessages();

        // Scroll to bottom after adding response
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
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Trợ lý AI',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Còn $_remainingMessages tin nhắn',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _auth.currentUser == null
                ? _buildLoginPrompt()
                : _messages.isEmpty && !_isLoading
                    ? _buildEmptyChatView()
                    : _buildChatList(),
          ),

          // Typing indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Trợ lý đang nhập...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          // Input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Vui lòng đăng nhập để sử dụng trợ lý AI',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Hỏi trợ lý AI của chúng tôi về món ăn, thông tin đơn hàng hoặc các câu hỏi khác liên quan đến cửa hàng.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    // Sort messages by timestamp (newest at bottom)
    final sortedMessages = List<Map<String, dynamic>>.from(_messages)
      ..sort((a, b) =>
          (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        final isUser = message['isUser'] as bool;
        final messageText = message['message'] as String;
        final timestamp = message['timestamp'] as DateTime;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(isUser),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isUser ? AppTheme.primaryColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        messageText,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildAvatar(isUser),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isUser ? AppTheme.secondaryColor : AppTheme.primaryColor,
      child: Icon(
        isUser ? Icons.person : Icons.support_agent,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                enabled: _auth.currentUser != null &&
                    _remainingMessages > 0 &&
                    !_isLoading,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          MaterialButton(
            onPressed: _isLoading ||
                    _auth.currentUser == null ||
                    _remainingMessages <= 0
                ? null
                : _sendMessage,
            shape: const CircleBorder(),
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.all(12),
            disabledColor: Colors.grey[300],
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
