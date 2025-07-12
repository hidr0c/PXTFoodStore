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

    // BURGER related keywords
    if (lowerMessage.contains('burger') ||
        lowerMessage.contains('hamburger') ||
        lowerMessage.contains('cheeseburger')) {
      if (lowerMessage.contains('best') || lowerMessage.contains('recommend')) {
        return 'Hamburger bò phô mai của chúng tôi được đánh giá cao nhất, với thịt bò Wagyu nhập khẩu và phô mai Cheddar thơm ngon. Bạn cũng có thể thử burger gà cay nếu thích vị cay!';
      } else if (lowerMessage.contains('price') ||
          lowerMessage.contains('cost')) {
        return 'Các loại burger của chúng tôi có giá từ 55.000đ đến 120.000đ tùy loại. Burger bò phô mai đặc biệt có giá 95.000đ. Tất cả burger đều được phục vụ kèm khoai tây chiên.';
      } else {
        return 'Chúng tôi có 8 loại burger khác nhau, từ burger bò cổ điển đến burger gà, burger chay. Burger được làm từ nguyên liệu tươi ngon và phục vụ kèm khoai tây chiên giòn rụm.';
      }
    }

    // PIZZA related keywords
    if (lowerMessage.contains('pizza')) {
      if (lowerMessage.contains('best') || lowerMessage.contains('recommend')) {
        return 'Pizza hải sản đặc biệt của chúng tôi rất được ưa chuộng! Đế bánh mỏng giòn, phủ đầy hải sản tươi ngon như tôm, mực, cùng phô mai Mozzarella thượng hạng.';
      } else if (lowerMessage.contains('price') ||
          lowerMessage.contains('cost')) {
        return 'Pizza cỡ nhỏ (20cm) có giá từ 90.000đ, cỡ vừa (28cm) từ 150.000đ và cỡ lớn (36cm) từ 250.000đ. Hiện chúng tôi có chương trình giảm 20% cho pizza cỡ lớn vào thứ Ba.';
      } else {
        return 'Menu pizza của chúng tôi có 12 lựa chọn, từ pizza truyền thống như Margherita đến các loại đặc biệt như pizza 4 loại thịt, pizza hải sản cao cấp. Bạn có thể chọn đế dày hoặc mỏng theo ý thích.';
      }
    }

    // CHICKEN related keywords
    if (lowerMessage.contains('chicken') ||
        lowerMessage.contains('gà') ||
        lowerMessage.contains('cánh gà')) {
      if (lowerMessage.contains('best') || lowerMessage.contains('recommend')) {
        return 'Cánh gà sốt Buffalo cay của chúng tôi là món rất được yêu thích. Giòn bên ngoài, mềm bên trong và phủ lớp sốt cay ngọt đậm đà.';
      } else if (lowerMessage.contains('price') ||
          lowerMessage.contains('cost')) {
        return 'Cánh gà 6 miếng giá 65.000đ, 12 miếng giá 120.000đ. Gà rán sốt đặc biệt 8 miếng giá 145.000đ. Combo gà rán và khoai tây chiên giá 99.000đ.';
      } else {
        return 'Chúng tôi có các món gà đa dạng: gà rán, cánh gà sốt (Buffalo, BBQ, mật ong tỏi), gà nướng, và gà tẩm bột chiên giòn. Tất cả đều được chế biến từ gà tươi ngon mỗi ngày.';
      }
    }

    // DRINKS related keywords
    if (lowerMessage.contains('drink') ||
        lowerMessage.contains('beverage') ||
        lowerMessage.contains('nước') ||
        lowerMessage.contains('đồ uống')) {
      if (lowerMessage.contains('alcohol') ||
          lowerMessage.contains('beer') ||
          lowerMessage.contains('wine')) {
        return 'Xin lỗi, chúng tôi không phục vụ đồ uống có cồn. Nhưng chúng tôi có nhiều loại nước trái cây tươi, sinh tố, nước ngọt và trà đá rất ngon!';
      } else if (lowerMessage.contains('price') ||
          lowerMessage.contains('cost')) {
        return 'Giá đồ uống của chúng tôi dao động từ 20.000đ đến 45.000đ. Nước ngọt từ 20.000đ, sinh tố trái cây từ 35.000đ, và các loại trà đặc biệt từ 25.000đ.';
      } else {
        return 'Chúng tôi có nhiều loại đồ uống: nước ngọt các loại, sinh tố (xoài, dâu, bơ), nước ép trái cây tươi, trà đào, trà sữa, cà phê và các loại trà đặc biệt.';
      }
    }

    // DESSERT related keywords
    if (lowerMessage.contains('dessert') ||
        lowerMessage.contains('tráng miệng') ||
        lowerMessage.contains('bánh ngọt') ||
        lowerMessage.contains('kem')) {
      if (lowerMessage.contains('best') || lowerMessage.contains('recommend')) {
        return 'Cheesecake dâu tây của chúng tôi được yêu thích nhất! Được làm từ cream cheese Pháp và dâu tây tươi, kết hợp với đế bánh giòn từ biscuit bơ.';
      } else if (lowerMessage.contains('price') ||
          lowerMessage.contains('cost')) {
        return 'Các món tráng miệng có giá từ 35.000đ đến 65.000đ. Cheesecake 55.000đ/miếng, kem gelato Ý 45.000đ/ly, và bánh chocolate lava 65.000đ.';
      } else {
        return 'Thực đơn tráng miệng của chúng tôi bao gồm cheesecake nhiều hương vị, bánh chocolate lava, tiramisu, gelato Ý, bánh flan caramel và các loại bánh ngọt khác được làm mới mỗi ngày.';
      }
    }

    // COMBO/DEALS related keywords
    if (lowerMessage.contains('combo') ||
        lowerMessage.contains('deal') ||
        lowerMessage.contains('discount') ||
        lowerMessage.contains('khuyến mãi') ||
        lowerMessage.contains('giảm giá')) {
      return 'Chúng tôi có nhiều combo hấp dẫn: Combo gia đình (1 pizza cỡ lớn + 4 món phụ + 4 đồ uống) giá 450.000đ giảm còn 350.000đ. Combo đôi (2 burger + 2 khoai tây + 2 đồ uống) giá 200.000đ. Thứ Tư giảm 15% tất cả các món, và thứ Hai giảm 20% cho khách hàng mới!';
    }

    // DELIVERY related keywords
    if (lowerMessage.contains('delivery') ||
        lowerMessage.contains('ship') ||
        lowerMessage.contains('giao hàng') ||
        lowerMessage.contains('vận chuyển')) {
      return 'Chúng tôi giao hàng miễn phí trong bán kính 5km với đơn hàng từ 150.000đ. Phí ship chỉ 15.000đ cho các khu vực khác. Thời gian giao hàng trung bình từ 30-45 phút tùy khoảng cách và thời gian cao điểm.';
    }

    // ORDER PROCESS related keywords
    if (lowerMessage.contains('order') ||
        lowerMessage.contains('đặt hàng') ||
        lowerMessage.contains('thanh toán')) {
      return 'Bạn có thể đặt hàng trực tiếp trên ứng dụng này: chọn món ăn, thêm vào giỏ hàng, điền thông tin giao hàng và chọn phương thức thanh toán. Chúng tôi chấp nhận thanh toán khi giao hàng (COD), thẻ ngân hàng, và các ví điện tử phổ biến.';
    }

    // VEGETARIAN related keywords
    if (lowerMessage.contains('vegetarian') ||
        lowerMessage.contains('vegan') ||
        lowerMessage.contains('chay')) {
      return 'Chúng tôi có nhiều lựa chọn cho thực khách ăn chay: pizza rau củ Địa Trung Hải, burger chay với patty từ đậu và nấm, salad Caesar chay, và các món phụ như khoai tây chiên, rau củ nướng. Tất cả đều được chế biến riêng biệt với các món mặn.';
    }

    // ALLERGY related keywords
    if (lowerMessage.contains('allergy') ||
        lowerMessage.contains('allergic') ||
        lowerMessage.contains('dị ứng')) {
      return 'Chúng tôi rất coi trọng vấn đề dị ứng thực phẩm. Vui lòng thông báo cho nhân viên về bất kỳ dị ứng nào khi đặt hàng. Thông tin chi tiết về thành phần của từng món ăn được liệt kê đầy đủ trong mục mô tả sản phẩm.';
    }

    // HOURS/LOCATION related keywords
    if (lowerMessage.contains('hour') ||
        lowerMessage.contains('time') ||
        lowerMessage.contains('open') ||
        lowerMessage.contains('close') ||
        lowerMessage.contains('giờ') ||
        lowerMessage.contains('địa chỉ') ||
        lowerMessage.contains('location')) {
      return 'Cửa hàng mở cửa từ 10:00 sáng đến 22:00 tối mỗi ngày. Địa chỉ các chi nhánh có thể tìm thấy trong mục "Vị trí cửa hàng" trong ứng dụng. Chi nhánh trung tâm ở 123 Nguyễn Huệ, Quận 1, TP.HCM.';
    }

    // Greeting or simple hello
    if (lowerMessage.contains('hi') ||
        lowerMessage.contains('hello') ||
        lowerMessage.contains('xin chào') ||
        lowerMessage.contains('chào')) {
      return 'Xin chào! Tôi là trợ lý ảo của PXTFoodStore. Tôi có thể giúp bạn tìm hiểu về menu, đặt hàng, giao hàng, khuyến mãi hoặc bất kỳ thông tin nào khác về nhà hàng của chúng tôi. Bạn muốn biết thông tin gì?';
    }

    // Thank you responses
    if (lowerMessage.contains('thanks') ||
        lowerMessage.contains('thank you') ||
        lowerMessage.contains('cảm ơn')) {
      return 'Rất vui được hỗ trợ bạn! Nếu bạn có bất kỳ câu hỏi nào khác hoặc cần thêm thông tin, đừng ngần ngại hỏi nhé. Chúc bạn có một bữa ăn ngon miệng!';
    }

    // Default response
    return 'Cảm ơn bạn đã liên hệ với PXTFoodStore. Tôi có thể giúp bạn tìm hiểu về menu đa dạng của chúng tôi, các chương trình khuyến mãi hấp dẫn, thông tin giao hàng, hoặc trả lời các câu hỏi về món ăn cụ thể. Bạn muốn biết thêm về điều gì?';
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
