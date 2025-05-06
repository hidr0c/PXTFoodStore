import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/chat_message_model.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> _quickResponses = [
    "Giao hàng",
    "Thanh toán",
    "Thời gian làm món",
    "Khác",
  ];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final message = _messageController.text;

      _firestore.collection('customer_support').add({
        'messageContent': message,
        'messageType': 'sender',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid,
      });

      _messageController.clear();
      _generateAutoResponse(message);
    }
  }

  void _generateAutoResponse(String userMessage) {
    String response;

    if (userMessage.contains("Thời gian làm món")) {
      response = "Thời gian làm món dự kiến của chúng tôi là 5-15 phút.";
    } else if (userMessage.contains("Thanh toán")) {
      response = "Chúng tôi chấp nhận thanh toán bằng thẻ và tiền mặt.";
    } else if (userMessage.contains("Giao hàng")) {
      response =
          "Chúng tôi sẽ giao hàng sớm nhất có thể.Vui lòng để ý số điện thoại";
    } else {
      response =
          "Cảm ơn bạn đã liên hệ! Chúng tôi sẽ phản hồi trong thời gian sớm nhất.";
    }

    Future.delayed(Duration(seconds: 1), () {
      _firestore.collection('customer_support').add({
        'messageContent': response,
        'messageType': 'receiver',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  void _deleteAllMessages() async {
    QuerySnapshot snapshot =
        await _firestore.collection('customer_support').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    _messageController.clear();
  }

  void _sendQuickResponse(String response) {
    _firestore.collection('customer_support').add({
      'messageContent': response,
      'messageType': 'sender',
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user?.uid,
    });

    _generateAutoResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hỗ trợ khách hàng"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('customer_support')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<ChatMessage> messages = snapshot.data!.docs.map((doc) {
                  return ChatMessage(
                    messageContent: doc['messageContent'],
                    messageType: doc['messageType'],
                  );
                }).toList();
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(messages[index]);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: _quickResponses.map((response) {
                return ElevatedButton(
                  onPressed: () {
                    _sendQuickResponse(response);
                  },
                  child: Text(response),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            _deleteAllMessages();
          },
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    bool isReceiver = message.messageType == "receiver";
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment:
            isReceiver ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isReceiver)
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/Group70.png'),
              radius: 20,
            ),
          SizedBox(width: 10),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isReceiver ? Colors.grey.shade200 : Colors.blue,
            ),
            padding: EdgeInsets.all(16),
            child: Text(
              message.messageContent,
              style: TextStyle(
                fontSize: 15,
                color: isReceiver ? Colors.black : Colors.white,
              ),
            ),
          ),
          if (!isReceiver) SizedBox(width: 10),
          if (!isReceiver)
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/image8.png'),
              radius: 20,
            ),
        ],
      ),
    );
  }
}
