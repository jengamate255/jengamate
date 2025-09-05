@echo off
echo ========================================
echo FIXING ALL REMAINING MODEL FILES
echo ========================================
echo.

echo Step 1: Creating FAQItem model
echo.

powershell -Command "New-Item -ItemType File -Path lib/models/faq_model_fixed.dart -Force; Add-Content lib/models/faq_model_fixed.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class FAQItem {  final String id;  final String question;  final String answer;  final String category;  final int order;  final bool isActive;  FAQItem({    required this.id,    required this.question,    required this.answer,    required this.category,    required this.order,    this.isActive = true,  });  factory FAQItem.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return FAQItem(      id: doc.id,      question: data[''question''] ?? '''',      answer: data[''answer''] ?? '''',      category: data[''category''] ?? '''',      order: data[''order''] ?? 0,      isActive: data[''isActive''] ?? true,    );  }  Map<String, dynamic> toMap() {    return {      ''question'': question,      ''answer'': answer,      ''category'': category,      ''order'': order,      ''isActive'': isActive,    };  }}'"

echo.
echo Step 2: Creating Inquiry model
echo.

powershell -Command "New-Item -ItemType File -Path lib/models/inquiry_model_fixed.dart -Force; Add-Content lib/models/inquiry_model_fixed.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class Inquiry {  final String id;  final String userId;  final String productId;  final String message;  final DateTime createdAt;  final String status;  Inquiry({    required this.id,    required this.userId,    required this.productId,    required this.message,    required this.createdAt,    required this.status,  });  factory Inquiry.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return Inquiry(      id: doc.id,      userId: data[''userId''] ?? '''',      productId: data[''productId''] ?? '''',      message: data[''message''] ?? '''',      createdAt: (data[''createdAt''] as Timestamp).toDate(),      status: data[''status''] ?? ''pending'',    );  }  Map<String, dynamic> toMap() {    return {      ''userId'': userId,      ''productId'': productId,      ''message'': message,      ''createdAt'': Timestamp.fromDate(createdAt),      ''status'': status,    };  }}'"

echo.
echo Step 3: Creating ChatMessageModel
echo.

powershell -Command "New-Item -ItemType File -Path lib/models/chat_message_model_fixed.dart -Force; Add-Content lib/models/chat_message_model_fixed.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class ChatMessageModel {  final String id;  final String chatRoomId;  final String senderId;  final String message;  final DateTime timestamp;  final bool isRead;  ChatMessageModel({    required this.id,    required this.chatRoomId,    required this.senderId,    required this.message,    required this.timestamp,    this.isRead = false,  });  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return ChatMessageModel(      id: doc.id,      chatRoomId: data[''chatRoomId''] ?? '''',      senderId: data[''senderId''] ?? '''',      message: data[''message''] ?? '''',      timestamp: (data[''timestamp''] as Timestamp).toDate(),      isRead: data[''isRead''] ?? false,    );  }  Map<String, dynamic> toMap() {    return {      ''chatRoomId'': chatRoomId,      ''senderId'': senderId,      ''message'': message,      ''timestamp'': Timestamp.fromDate(timestamp),      ''isRead'': isRead,    };  }}'"

echo.
echo Step 4: Creating ChatRoomModel
echo.

powershell -Command "New-Item -ItemType File -Path lib/models/chat_room_model.dart -Force; Add-Content lib/models/chat_room_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class ChatRoomModel {  final String id;  final List<String> participants;  final String lastMessage;  final DateTime lastMessageAt;  final Map<String, dynamic> metadata;  ChatRoomModel({    required this.id,    required this.participants,    required this.lastMessage,    required this.lastMessageAt,    this.metadata = const {},  });  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return ChatRoomModel(      id: doc.id,      participants: List<String>.from(data[''participants''] ?? []),      lastMessage: data[''lastMessage''] ?? '''',      lastMessageAt: (data[''lastMessageAt''] as Timestamp).toDate(),      metadata: data[''metadata''] ?? {},    );  }  Map<String, dynamic> toMap() {    return {      ''participants'': participants,      ''lastMessage'': lastMessage,      ''lastMessageAt'': Timestamp.fromDate(lastMessageAt),      ''metadata'': metadata,    };  }}'"

echo.
echo Step 5: Creating ContentReportModel
echo.

powershell -Command "New-Item -ItemType File -Path lib/models/content_report_model.dart -Force; Add-Content lib/models/content_report_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class ContentReportModel {  final String id;  final String contentType;  final String contentId;  final String reportedBy;  final String reporterName;  final String reason;  final String description;  final String severity;  final DateTime createdAt;  final String status;  ContentReportModel({    required this.id,    required this.contentType,    required this.contentId,    required this.reportedBy,    required this.reporterName,    required this.reason,    required this.description,    required this.severity,    required this.createdAt,    required this.status,  });  factory ContentReportModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return ContentReportModel(      id: doc.id,      contentType: data[''contentType''] ?? ''unknown'',      contentId: data[''contentId''] ?? '''',      reportedBy: data[''reportedBy''] ?? '''',      reporterName: data[''reporterName''] ?? ''Unknown User'',      reason: data[''reason''] ?? '''',      description: data[''description''] ?? '''',      severity: data[''severity''] ?? ''low'',      createdAt: (data[''createdAt''] as Timestamp).toDate(),      status: data[''status''] ?? ''pending'',    );  }  Map<String, dynamic> toMap() {    return {      ''contentType'': contentType,      ''contentId'': contentId,      ''reportedBy'': reportedBy,      ''reporterName'': reporterName,      ''reason'': reason,      ''description'': description,      ''severity'': severity,      ''createdAt'': Timestamp.fromDate(createdAt),      ''status'': status,    };  }}'"

echo.
echo Step 6: Creating SystemConfigModel
echo.

powershell -Command "New-Item -ItemType File -Path lib/models/system_config_model.dart -Force; Add-Content lib/models/system_config_model.dart 'import ''package:cloud_firestore/cloud_firestore.dart'';class SystemConfigModel {  final String id;  final String siteName;  final String siteDescription;  final int maxFileSize;  final List<String> allowedFileTypes;  final bool maintenanceMode;  final String contactEmail;  final String contactPhone;  final String defaultCurrency;  final bool commissionEnabled;  final bool withdrawalEnabled;  final double minWithdrawalAmount;  final double maxWithdrawalAmount;  SystemConfigModel({    required this.id,    required this.siteName,    required this.siteDescription,    required this.maxFileSize,    required this.allowedFileTypes,    required this.maintenanceMode,    required this.contactEmail,    required this.contactPhone,    required this.defaultCurrency,    required this.commissionEnabled,    required this.withdrawalEnabled,    required this.minWithdrawalAmount,    required this.maxWithdrawalAmount,  });  factory SystemConfigModel.fromFirestore(DocumentSnapshot doc) {    final data = doc.data() as Map<String, dynamic>;    return SystemConfigModel(      id: doc.id,      siteName: data[''siteName''] ?? ''JengaMate'',      siteDescription: data[''siteDescription''] ?? ''Your trusted construction marketplace'',      maxFileSize: data[''maxFileSize''] ?? 10,      allowedFileTypes: List<String>.from(data[''allowedFileTypes''] ?? [''jpg'', ''jpeg'', ''png'', ''pdf'']),      maintenanceMode: data[''maintenanceMode''] ?? false,      contactEmail: data[''contactEmail''] ?? ''support@jengamate.com'',      contactPhone: data[''contactPhone''] ?? ''+254700000000'',      defaultCurrency: data[''defaultCurrency''] ?? ''KES'',      commissionEnabled: data[''commissionEnabled''] ?? true,      withdrawalEnabled: data[''withdrawalEnabled''] ?? true,      minWithdrawalAmount: (data[''minWithdrawalAmount''] ?? 1000).toDouble(),      maxWithdrawalAmount: (data[''maxWithdrawalAmount''] ?? 100000).toDouble(),    );  }  Map<String, dynamic> toMap() {    return {      ''siteName'': siteName,      ''siteDescription'': siteDescription,      ''maxFileSize'': maxFileSize,      ''allowedFileTypes'': allowedFileTypes,      ''maintenanceMode'': maintenanceMode,      ''contactEmail'': contactEmail,      ''contactPhone'': contactPhone,      ''defaultCurrency'': defaultCurrency,      ''commissionEnabled'': commissionEnabled,      ''withdrawalEnabled'': withdrawalEnabled,      ''minWithdrawalAmount'': minWithdrawalAmount,      ''maxWithdrawalAmount'': maxWithdrawalAmount,    };  }}'"

echo.
echo Step 7: Replacing all model files
echo.

copy lib\models\faq_model_fixed.dart lib\models\faq_model.dart
copy lib\models\inquiry_model_fixed.dart lib\models\inquiry_model.dart
copy lib\models\chat_message_model_fixed.dart lib\models\chat_message_model.dart

echo.
echo ========================================
echo MODEL FILES FIXED SUCCESSFULLY!
echo ========================================
echo.
echo All model files have been created and replaced with proper formatting.
echo.
echo Next steps:
echo 1. Run: flutter analyze
echo 2. Check for remaining errors
echo 3. Fix any remaining import issues
echo.
pause