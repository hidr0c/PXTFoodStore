import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/models/chat_message.dart';

class AIChatService {
  // Using Hugging Face free inference API
  // You can get a free API key from: https://huggingface.co/settings/tokens
  static const String _apiUrl =
      "https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium";

  // Free Hugging Face API key (replace with your own)
  // Sign up at huggingface.co for free API access
  static const String _apiKey = "hf_YOUR_FREE_API_KEY";

  // Alternative: Use Google Gemini free API
  // static const String _geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";
  // static const String _geminiKey = "YOUR_GEMINI_API_KEY";

  // Control how many messages we allow to be sent
  static const int _maxFreeMessagesPerDay = 10;
  static const int _maxMessageLength = 300;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a message to the AI and get a response
  Future<String?> sendMessageToAI(String message, {String chatId = ''}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to use AI chat');
    }

    // Check if user has exceeded daily message limit
    if (!await _canUserSendMessage(user.uid)) {
      throw Exception(
          'You have reached your daily message limit. Please try again tomorrow.');
    }

    // Restrict message length
    if (message.length > _maxMessageLength) {
      throw Exception(
          'Message too long. Please limit your message to $_maxMessageLength characters.');
    }

    // Make sure the message is appropriate for a food store context
    if (!_isAppropriateMessage(message)) {
      throw Exception(
          'Please keep your questions related to food, ordering, or customer service.');
    }

    try {
      // Record this message in the user's chat history
      await _recordUserMessage(user.uid, message, chatId);

      // For demo purposes, if no API key is set, return a mock response
      if (_apiKey == "hf_YOUR_FREE_API_KEY") {
        await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
        final mockResponse = _generateMockResponse(message);
        await _recordAIResponse(user.uid, mockResponse, chatId);
        return mockResponse;
      }

      // Make the API request to Hugging Face
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'inputs': message,
          'parameters': {
            'max_length': 150,
            'temperature': 0.7,
            'do_sample': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        String aiResponse = '';

        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          aiResponse = jsonResponse[0]['generated_text'] ??
              'Xin lỗi, tôi không thể trả lời câu hỏi này.';
        } else {
          aiResponse = 'Xin lỗi, tôi không thể trả lời câu hỏi này.';
        }

        // Clean up the response to make it more appropriate for food store context
        aiResponse = _cleanAIResponse(aiResponse, message);

        // Record the AI's response
        await _recordAIResponse(user.uid, aiResponse, chatId);

        return aiResponse;
      } else {
        debugPrint(
            'API request failed: ${response.statusCode}, ${response.body}');
        return 'Xin lỗi, tôi không thể xử lý yêu cầu của bạn lúc này. Vui lòng thử lại sau.';
      }
    } catch (e) {
      debugPrint('Error sending message to AI: $e');
      return 'Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại sau.';
    }
  }

  // Check if the user has exceeded their daily message limit
  Future<bool> _canUserSendMessage(String userId) async {
    try {
      // Get today's date at midnight for comparison
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Query messages sent by this user today
      final messagesSnapshot = await _firestore
          .collection('ai_chat_usage')
          .doc(userId)
          .collection('messages')
          .where('timestamp', isGreaterThanOrEqualTo: today)
          .count()
          .get();

      return (messagesSnapshot.count ?? 0) < _maxFreeMessagesPerDay;
    } catch (e) {
      debugPrint('Error checking message limit: $e');
      return false; // Fail closed - if we can't check, don't allow more messages
    }
  }

  // Get the number of messages remaining for today
  Future<int> getRemainingMessages(String userId) async {
    try {
      // Get today's date at midnight for comparison
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Query messages sent by this user today
      final messagesSnapshot = await _firestore
          .collection('ai_chat_usage')
          .doc(userId)
          .collection('messages')
          .where('timestamp', isGreaterThanOrEqualTo: today)
          .count()
          .get();

      return _maxFreeMessagesPerDay - (messagesSnapshot.count ?? 0);
    } catch (e) {
      debugPrint('Error checking remaining messages: $e');
      return 0; // Fail closed - if we can't check, don't allow more messages
    }
  }

  // Check if message is appropriate for food store context
  bool _isAppropriateMessage(String message) {
    // Convert to lowercase for easier checking
    final lowerMessage = message.toLowerCase();

    // List of food-related keywords
    final foodKeywords = [
      'food',
      'meal',
      'order',
      'delivery',
      'menu',
      'dish',
      'restaurant',
      'eat',
      'drink',
      'hungry',
      'appetite',
      'taste',
      'flavor',
      'cuisine',
      'price',
      'discount',
      'special',
      'chef',
      'recipe',
      'ingredient',
      'vegetarian',
      'vegan',
      'gluten',
      'allergy',
      'spicy',
      'sweet',
      'sour',
      'bitter',
      'breakfast',
      'lunch',
      'dinner',
      'snack',
      'dessert',
      'beverage',
      'reservation',
      'table',
      'takeout',
      'opening',
      'closing',
      'hour',
      'location',
      'address',
      'contact',
      'feedback',
      'rating',
      'review',
      'recommend',
      'popular',
      'best'
    ];

    // Check if message contains at least one food-related keyword
    for (final keyword in foodKeywords) {
      if (lowerMessage.contains(keyword)) {
        return true;
      }
    }

    // If no food keywords are found, check message length
    // Short messages might be greetings or simple questions
    if (message.length < 20) {
      return true;
    }

    // If it's a longer message with no food keywords, it might be off-topic
    return false;
  }

  // Record a user message in Firestore
  Future<void> _recordUserMessage(
      String userId, String message, String chatId) async {
    try {
      final timestamp = DateTime.now();

      // Record in the AI chat usage collection
      await _firestore
          .collection('ai_chat_usage')
          .doc(userId)
          .collection('messages')
          .add({
        'message': message,
        'timestamp': timestamp,
        'isUser': true,
      });

      // If we have a chat ID, also record in the regular chat collection
      if (chatId.isNotEmpty) {
        final chatMessage = ChatMessage(
          senderId: userId,
          senderName: 'User',
          text: message,
          timestamp: timestamp,
          isRead: false,
        );

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(chatMessage.toMap());

        // Update the last message info in the chat document
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': message,
          'lastMessageTime': timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error recording user message: $e');
      // Continue execution even if recording fails
    }
  }

  // Record an AI response in Firestore
  Future<void> _recordAIResponse(
      String userId, String response, String chatId) async {
    try {
      final timestamp = DateTime.now();

      // Record in the AI chat usage collection
      await _firestore
          .collection('ai_chat_usage')
          .doc(userId)
          .collection('messages')
          .add({
        'message': response,
        'timestamp': timestamp,
        'isUser': false,
      });

      // If we have a chat ID, also record in the regular chat collection
      if (chatId.isNotEmpty) {
        final chatMessage = ChatMessage(
          senderId: 'ai-assistant',
          senderName: 'AI Assistant',
          text: response,
          timestamp: timestamp,
          isRead: false,
        );

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(chatMessage.toMap());

        // Update the last message info in the chat document
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': response,
          'lastMessageTime': timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error recording AI response: $e');
      // Continue execution even if recording fails
    }
  }

  // Generate a mock response when no API key is provided
  String _generateMockResponse(String message) {
    // Convert message to lowercase for easier matching
    final lowerMessage = message.toLowerCase();

    // Food ordering related responses
    if (lowerMessage.contains('order') || lowerMessage.contains('delivery')) {
      return 'Bạn có thể đặt món ăn trực tiếp thông qua ứng dụng của chúng tôi. Chỉ cần chọn món ăn yêu thích và thêm vào giỏ hàng, sau đó nhập địa chỉ giao hàng và phương thức thanh toán.';
    }

    // Menu related questions
    if (lowerMessage.contains('menu') ||
        lowerMessage.contains('food') ||
        lowerMessage.contains('dish') ||
        lowerMessage.contains('eat')) {
      return 'Thực đơn của chúng tôi có nhiều lựa chọn từ burger, pizza, đồ uống, đến các món ăn phụ. Bạn có thể xem toàn bộ thực đơn tại trang chủ của ứng dụng.';
    }

    // Price related questions
    if (lowerMessage.contains('price') ||
        lowerMessage.contains('cost') ||
        lowerMessage.contains('expensive') ||
        lowerMessage.contains('cheap')) {
      return 'Giá cả các món ăn của chúng tôi rất cạnh tranh. Burger từ 50.000đ, Pizza từ 90.000đ, và đồ uống từ 20.000đ. Chúng tôi thường xuyên có các chương trình khuyến mãi đặc biệt!';
    }

    // Location or hours related
    if (lowerMessage.contains('location') ||
        lowerMessage.contains('address') ||
        lowerMessage.contains('hour') ||
        lowerMessage.contains('open') ||
        lowerMessage.contains('close')) {
      return 'Cửa hàng chúng tôi mở cửa từ 8:00 sáng đến 22:00 tối mỗi ngày. Bạn có thể tìm thấy cửa hàng gần nhất thông qua tính năng "Vị trí" trong ứng dụng.';
    }

    // Special deals or discounts
    if (lowerMessage.contains('deal') ||
        lowerMessage.contains('discount') ||
        lowerMessage.contains('special') ||
        lowerMessage.contains('offer')) {
      return 'Chúng tôi có nhiều ưu đãi hấp dẫn! Giảm 20% cho đơn hàng đầu tiên, combo gia đình tiết kiệm đến 30%, và đặc biệt miễn phí giao hàng cho đơn từ 200.000đ.';
    }

    // Dietary restrictions
    if (lowerMessage.contains('vegetarian') ||
        lowerMessage.contains('vegan') ||
        lowerMessage.contains('gluten') ||
        lowerMessage.contains('allergy')) {
      return 'Chúng tôi có nhiều lựa chọn phù hợp với chế độ ăn đặc biệt. Bạn có thể lọc thực đơn theo các tiêu chí như đồ chay, không gluten, và xem đầy đủ thông tin về thành phần của từng món ăn.';
    }

    // Feedback or complaints
    if (lowerMessage.contains('feedback') ||
        lowerMessage.contains('complaint') ||
        lowerMessage.contains('issue') ||
        lowerMessage.contains('problem')) {
      return 'Chúng tôi rất tiếc nếu bạn gặp vấn đề. Vui lòng cung cấp chi tiết về đơn hàng hoặc trải nghiệm của bạn qua mục "Hỗ trợ" để chúng tôi có thể giúp đỡ bạn nhanh nhất.';
    }

    // Greeting or simple hello
    if (lowerMessage.contains('hi') ||
        lowerMessage.contains('hello') ||
        lowerMessage.contains('xin chào') ||
        lowerMessage.contains('chào')) {
      return 'Xin chào! Tôi là trợ lý ảo của cửa hàng thức ăn. Tôi có thể giúp gì cho bạn hôm nay?';
    }

    // Thank you responses
    if (lowerMessage.contains('thanks') ||
        lowerMessage.contains('thank you') ||
        lowerMessage.contains('cảm ơn')) {
      return 'Không có gì! Rất vui được giúp đỡ bạn. Nếu bạn cần hỗ trợ thêm, đừng ngần ngại hỏi nhé.';
    }

    // Default response
    return 'Cảm ơn bạn đã liên hệ. Chúng tôi luôn sẵn sàng hỗ trợ bạn với mọi câu hỏi về thực đơn, đặt hàng, hoặc dịch vụ khách hàng. Bạn có thể cho tôi biết cụ thể hơn về điều bạn đang tìm kiếm không?';
  }

  // Get AI chat history for a user
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('ai_chat_usage')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to recent messages
          .get();

      return messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'message': data['message'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'isUser': data['isUser'] ?? true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting chat history: $e');
      return [];
    }
  }

  // Clean up AI responses to keep them on-topic and appropriate
  String _cleanAIResponse(String aiResponse, String originalMessage) {
    // Strip out any potentially inappropriate content
    aiResponse = aiResponse.replaceAll(
        RegExp(r'(http|https):\/\/[^\s]+'), '[link removed]');

    // Remove any text that might be system prompts or instructions
    aiResponse = aiResponse.replaceAll(RegExp(r'<.*?>'), '');

    // If the response is empty after cleaning, provide a fallback
    if (aiResponse.trim().isEmpty) {
      return 'I understand your interest in our food. How can I help you today?';
    }

    // Keep responses food-focused if they've gone off track
    if (!_isAppropriateResponse(aiResponse)) {
      return _refocusResponse(aiResponse, originalMessage);
    }

    // Limit response length
    if (aiResponse.length > 300) {
      aiResponse = '${aiResponse.substring(0, 297)}...';
    }

    return aiResponse;
  }

  // Check if the AI response is appropriate for our context
  bool _isAppropriateResponse(String response) {
    final lowerResponse = response.toLowerCase();

    // Check for food-related content in the response
    final foodKeywords = [
      'food',
      'meal',
      'order',
      'delivery',
      'menu',
      'dish',
      'restaurant',
      'eat',
      'drink',
      'taste',
      'flavor',
      'price',
      'recipe',
      'ingredient'
    ];

    for (final keyword in foodKeywords) {
      if (lowerResponse.contains(keyword)) {
        return true;
      }
    }

    // Short responses are likely simple acknowledgements
    if (response.length < 40) {
      return true;
    }

    return false;
  }

  // Re-focus an off-topic response back to food
  String _refocusResponse(String response, String originalMessage) {
    final lowerOriginal = originalMessage.toLowerCase();

    // Handle common off-topic scenarios by refocusing on food
    if (lowerOriginal.contains('recipe') || lowerOriginal.contains('cook')) {
      return 'While I can\'t provide detailed recipes, our store offers a variety of ready-to-eat meals and ingredients. Would you like recommendations for specific dishes?';
    }

    if (lowerOriginal.contains('price') || lowerOriginal.contains('cost')) {
      return 'Our menu has options for every budget. Our app shows current prices and any special offers. Can I help you find something specific?';
    }

    if (lowerOriginal.contains('delivery') || lowerOriginal.contains('order')) {
      return 'You can place orders through our app for delivery or pickup. Delivery times average 30-45 minutes depending on your location. Would you like to know more about our ordering process?';
    }

    // Generic refocus response
    return 'Thank you for your question. As your food store assistant, I\'m here to help you with menu items, orders, delivery information, and food recommendations. How can I assist you with your food needs today?';
  }

  // Helper method for filtering inappropriate content
  String _filterInappropriateContent(String response) {
    // Remove URLs that might be in the response
    response = response.replaceAll(
        RegExp(r'(http|https):\/\/[^\s]+'), '[link removed]');

    // Remove any HTML-like tags
    response = response.replaceAll(RegExp(r'<.*?>'), '');

    // List of inappropriate terms to filter out (simplified example)
    final inappropriateTerms = [
      'alcohol',
      'beer',
      'wine',
      'liquor',
      'gambling',
      'betting',
      'lottery',
      'adult',
      'nsfw',
      'dating',
      'hookup'
    ];

    // Replace inappropriate terms with [removed]
    for (final term in inappropriateTerms) {
      response =
          response.replaceAll(RegExp(term, caseSensitive: false), '[removed]');
    }

    return response;
  }

  // Method to check if response is on-topic for food store
  bool _isResponseOnTopic(String response) {
    final lowerResponse = response.toLowerCase();

    // This is essentially the same as _isAppropriateResponse
    return _isAppropriateResponse(response);
  }
}
