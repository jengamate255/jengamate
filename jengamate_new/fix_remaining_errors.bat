@echo off
echo ========================================
echo FIXING REMAINING COMPILATION ERRORS
echo ========================================
echo.

echo Step 1: Adding fromFirestore method to AuditLogModel
echo.

powershell -Command "(Get-Content lib/models/audit_log_model.dart -Raw) -replace '  factory AuditLogModel\.fromMap\(Map<String, dynamic> map\) \{', '  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return AuditLogModel.fromMap(data);  }  factory AuditLogModel.fromMap(Map<String, dynamic> map) {' | Set-Content lib/models/audit_log_model.dart"

echo.
echo Step 2: Fixing OrderStatus enum conflicts
echo.

echo Removing duplicate OrderStatus enum from order_status_enum.dart
powershell -Command "if (Test-Path lib/models/order_status_enum.dart) { Remove-Item lib/models/order_status_enum.dart }"

echo.
echo Step 3: Adding missing model classes
echo.

echo Creating SupportTicketModel...
powershell -Command "New-Item -ItemType File -Path lib/models/support_ticket_model.dart -Force; Add-Content lib/models/support_ticket_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class SupportTicketModel {  final String id;  final String userId;  final String subject;  final String description;  final String status;  final String priority;  final DateTime createdAt;  final DateTime? resolvedAt;  SupportTicketModel({    required this.id,    required this.userId,    required this.subject,    required this.description,    required this.status,    required this.priority,    required this.createdAt,    this.resolvedAt,  });  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return SupportTicketModel(      id: doc.id,      userId: data[''userId''] ?? '''',      subject: data[''subject''] ?? '''',      description: data[''description''] ?? '''',      status: data[''status''] ?? ''open'',      priority: data[''priority''] ?? ''medium'',      createdAt: (data[''createdAt''] as Timestamp).toDate(),      resolvedAt: data[''resolvedAt''] != null ? (data[''resolvedAt''] as Timestamp).toDate() : null,    );  }  Map<String, dynamic> toMap() {    return {      ''userId'': userId,      ''subject'': subject,      ''description'': description,      ''status'': status,      ''priority'': priority,      ''createdAt'': Timestamp.fromDate(createdAt),      ''resolvedAt'': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,    };  }}'"

echo Creating FAQItem...
powershell -Command "New-Item -ItemType File -Path lib/models/faq_model.dart -Force; Add-Content lib/models/faq_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class FAQItem {  final String id;  final String question;  final String answer;  final String category;  final int order;  final bool isActive;  FAQItem({    required this.id,    required this.question,    required this.answer,    required this.category,    required this.order,    this.isActive = true,  });  factory FAQItem.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return FAQItem(      id: doc.id,      question: data[''question''] ?? '''',      answer: data[''answer''] ?? '''',      category: data[''category''] ?? '''',      order: data[''order''] ?? 0,      isActive: data[''isActive''] ?? true,    );  }  Map<String, dynamic> toMap() {    return {      ''question'': question,      ''answer'': answer,      ''category'': category,      ''order'': order,      ''isActive'': isActive,    };  }}'"

echo Creating Inquiry model...
powershell -Command "New-Item -ItemType File -Path lib/models/inquiry_model.dart -Force; Add-Content lib/models/inquiry_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class Inquiry {  final String id;  final String userId;  final String productId;  final String message;  final DateTime createdAt;  final String status;  Inquiry({    required this.id,    required this.userId,    required this.productId,    required this.message,    required this.createdAt,    required this.status,  });  factory Inquiry.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return Inquiry(      id: doc.id,      userId: data[''userId''] ?? '''',      productId: data[''productId''] ?? '''',      message: data[''message''] ?? '''',      createdAt: (data[''createdAt''] as Timestamp).toDate(),      status: data[''status''] ?? ''pending'',    );  }  Map<String, dynamic> toMap() {    return {      ''userId'': userId,      ''productId'': productId,      ''message'': message,      ''createdAt'': Timestamp.fromDate(createdAt),      ''status'': status,    };  }}'"

echo Creating ChatMessageModel...
powershell -Command "New-Item -ItemType File -Path lib/models/chat_message_model.dart -Force; Add-Content lib/models/chat_message_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class ChatMessageModel {  final String id;  final String chatRoomId;  final String senderId;  final String message;  final DateTime timestamp;  final bool isRead;  ChatMessageModel({    required this.id,    required this.chatRoomId,    required this.senderId,    required this.message,    required this.timestamp,    this.isRead = false,  });  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return ChatMessageModel(      id: doc.id,      chatRoomId: data[''chatRoomId''] ?? '''',      senderId: data[''senderId''] ?? '''',      message: data[''message''] ?? '''',      timestamp: (data[''timestamp''] as Timestamp).toDate(),      isRead: data[''isRead''] ?? false,    );  }  Map<String, dynamic> toMap() {    return {      ''chatRoomId'': chatRoomId,      ''senderId'': senderId,      ''message'': message,      ''timestamp'': Timestamp.fromDate(timestamp),      ''isRead'': isRead,    };  }}'"

echo.
echo Step 4: Fixing analytics service platformFee issue
echo.

echo Fixing platformFee issue in analytics_service.dart...
powershell -Command "(Get-Content lib/services/analytics_service.dart -Raw) -replace 'platformCommission \+= order\.platformFee;', 'platformCommission += order.totalAmount * 0.1; // 10% platform fee' | Set-Content lib/services/analytics_service.dart"

echo.
echo Step 5: Fixing OrderModel issues
echo.

echo Adding missing fields to OrderModel...
powershell -Command "(Get-Content lib/models/order_model.dart -Raw) -replace '  final String status;', '  final String status;  final double platformFee;  final String productId;' | Set-Content lib/models/order_model.dart"

echo Fixing OrderModel fromMap method...
powershell -Command "(Get-Content lib/models/order_model.dart -Raw) -replace '      status: map\[''status''] \?\? ''pending'',', '      status: OrderStatus.values.firstWhere((e) => e.value == (map[''status''] ?? ''pending''), orElse: () => OrderStatus.pending).value,      platformFee: (map[''platformFee''] ?? 0.0).toDouble(),      productId: map[''productId''] ?? '''',' | Set-Content lib/models/order_model.dart"

echo.
echo Step 6: Fixing UserModel issues
echo.

echo Adding userType field to UserModel...
powershell -Command "(Get-Content lib/models/user_model.dart -Raw) -replace '  final String role;', '  final String role;  final String userType;' | Set-Content lib/models/user_model.dart"

echo Fixing UserModel fromMap method...
powershell -Command "(Get-Content lib/models/user_model.dart -Raw) -replace '      role: map\[''role''] \?\? ''user'',', '      role: map[''role''] ?? ''user'',      userType: map[''userType''] ?? ''customer'',' | Set-Content lib/models/user_model.dart"

echo.
echo ========================================
echo REMAINING MANUAL STEPS:
echo ========================================
echo.
echo 1. Run: flutter clean
echo 2. Run: flutter pub get
echo 3. Run: flutter analyze
echo 4. Fix any remaining errors
echo 5. Run: flutter run
echo.
echo ========================================
echo Press any key to continue...
pause >nul