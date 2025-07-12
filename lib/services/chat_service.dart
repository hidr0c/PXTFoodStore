import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie/models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat
  Future<String> createChat({
    required String userId,
    required String userName,
  }) async {
    // Check if a chat already exists for this user
    final existingChats = await _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    // Return existing chat if found
    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    // Create a new chat
    final chatDoc = await _firestore.collection('chats').add({
      'userId': userId,
      'userName': userName,
      'lastMessage': '',
      'lastMessageTime': DateTime.now(),
      'createdAt': DateTime.now(),
      'unreadCount': 0,
      'isActive': true,
    });

    return chatDoc.id;
  }

  // Get all chats (admin feature)
  Stream<QuerySnapshot> getChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get chat by ID
  Stream<DocumentSnapshot> getChat(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  // Get messages for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    // Add message to the chat's messages subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    // Update the chat document with the latest message info
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp,
      // If the sender is not the user, increment unread count
      'unreadCount':
          FieldValue.increment(message.senderId.contains('admin') ? 0 : 1),
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    // Skip for admin messages
    if (userId.contains('admin')) return;

    // Get all unread messages from other senders
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    // Create a batch operation to update all messages
    final batch = _firestore.batch();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Reset unread count in the chat document
    batch
        .update(_firestore.collection('chats').doc(chatId), {'unreadCount': 0});

    // Commit the batch
    await batch.commit();
  }

  // Delete a chat (admin feature)
  Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat document
    batch.delete(_firestore.collection('chats').doc(chatId));

    // Commit the batch
    await batch.commit();
  }
}
