import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message to an inquiry
  Future<void> sendMessageToInquiry(String inquiryId, Message message) async {
    await _firestore
        .collection('inquiries')
        .doc(inquiryId)
        .collection('messages')
        .add(message.toFirestore());
  }

  // Stream messages for an inquiry
  Stream<List<Message>> streamInquiryMessages(String inquiryId) {
    return _firestore
        .collection('inquiries')
        .doc(inquiryId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  // Send a message to an order
  Future<void> sendMessageToOrder(String orderId, Message message) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .add(message.toFirestore());
  }

  // Stream messages for an order
  Stream<List<Message>> streamOrderMessages(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }
}