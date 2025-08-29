import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/product_interaction_model.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/utils/logger.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _interactionsCollection = 'product_interactions';
  static const String _rfqTrackingCollection = 'rfq_tracking';
  static const String _analyticsCollection = 'rfq_analytics';

  /// Track product interaction (view, RFQ click, etc.)
  Future<void> trackProductInteraction({
    required ProductModel product,
    required UserModel user,
    required String interactionType,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final interaction = ProductInteractionModel(
        id: '', // Firestore will generate
        productId: product.id,
        productName: product.name,
        userId: user.uid,
        userName: user.name,
        userEmail: user.email ?? 'unknown@example.com',
        userRole: user.role.toString().split('.').last,
        interactionType: interactionType,
        timestamp: DateTime.now(),
        productDetails: {
          'category': product.category ?? 'uncategorized',
          'subcategory': product.subcategory ?? '',
          'price': product.price,
          'brand': product.brand ?? 'unknown',
          'gauge': product.gauge ?? '',
          'profile': product.profile ?? '',
          'type': product.type,
          'thickness': product.thickness,
          'color': product.color,
          'dimensions': product.dimensions,
          'stock': product.stock,
          'serviceProvider': product.serviceProvider,
          'isHot': product.isHot,
        },
        userContext: {
          'userRole': user.role.toString().split('.').last,
          'userLocation': user.location ?? 'Unknown',
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalContext,
        },
        sessionId: _generateSessionId(),
        deviceInfo: _getDeviceInfo(),
        location: user.location,
      );

      await _firestore.collection(_interactionsCollection).add(interaction.toMap());

      // Log analytics event with null safety and proper typing
      final parameters = <String, Object>{
        'product_id': product.id,
        'product_name': product.name,
        'interaction_type': interactionType,
        'user_role': user.role.toString().split('.').last,
      };
      
      // Add category if it's not null
      final category = product.category;
      if (category != null) {
        parameters['category'] = category;
      }
      
      Logger.logEvent('product_interaction', parameters: parameters);

      Logger.log('Product interaction tracked: ${product.name} - $interactionType by ${user.name}');
    } catch (e, s) {
      Logger.logError('Error tracking product interaction', e, s);
    }
  }

  /// Track RFQ creation with detailed information
  Future<void> trackRFQCreation({
    required String rfqId,
    required ProductModel product,
    required UserModel engineer,
    required Map<String, dynamic> rfqDetails,
    int? quantity,
    String? preferredDeliveryDate,
    String? budgetRange,
  }) async {
    try {
      final rfqTracking = RFQTrackingModel(
        id: '', // Firestore will generate
        rfqId: rfqId,
        productId: product.id,
        productName: product.name,
        engineerId: engineer.uid,
        engineerName: engineer.name,
        engineerEmail: engineer.email ?? 'unknown@example.com',
        status: 'initiated',
        createdAt: DateTime.now(),
        productSpecs: {
          'category': product.category ?? 'uncategorized',
          'subcategory': product.subcategory ?? '',
          'brand': product.brand ?? 'unknown',
          'gauge': product.gauge ?? '',
          'profile': product.profile ?? '',
          'type': product.type,
          'thickness': product.thickness,
          'color': product.color,
          'dimensions': product.dimensions,
          'price': product.price,
        },
        rfqDetails: rfqDetails,
        supplierViews: [],
        statusHistory: [
          {
            'status': 'initiated',
            'timestamp': DateTime.now().toIso8601String(),
            'userId': engineer.uid,
            'userName': engineer.name,
            'notes': 'RFQ created by engineer',
          }
        ],
        quantity: quantity ?? 0,
        preferredDeliveryDate: preferredDeliveryDate,
        budgetRange: budgetRange,
      );

      await _firestore.collection(_rfqTrackingCollection).add(rfqTracking.toMap());

      // Update analytics
      await _updateProductAnalytics(product.id, product.name, 'rfq_created');

      Logger.logEvent('rfq_created', parameters: {
        'rfq_id': rfqId,
        'product_id': product.id,
        'product_name': product.name,
        'engineer_id': engineer.uid,
        'quantity': quantity ?? 1,
      });

      Logger.log('RFQ tracking created: ${product.name} by ${engineer.name}');
    } catch (e, s) {
      Logger.logError('Error tracking RFQ creation', e, s);
    }
  }

  /// Track when a supplier views an RFQ
  Future<void> trackSupplierRFQView({
    required String rfqId,
    required String supplierId,
    required String supplierName,
  }) async {
    try {
      final docRef = await _firestore
          .collection(_rfqTrackingCollection)
          .where('rfqId', isEqualTo: rfqId)
          .limit(1)
          .get();

      if (docRef.docs.isNotEmpty) {
        final doc = docRef.docs.first;
        final data = doc.data();
        final supplierViews = List<String>.from(data['supplierViews'] ?? []);
        
        if (!supplierViews.contains(supplierId)) {
          supplierViews.add(supplierId);
          
          final statusHistory = List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
          statusHistory.add({
            'status': 'viewed_by_supplier',
            'timestamp': DateTime.now().toIso8601String(),
            'userId': supplierId,
            'userName': supplierName,
            'notes': 'RFQ viewed by supplier',
          });

          await doc.reference.update({
            'supplierViews': supplierViews,
            'statusHistory': statusHistory,
            'lastUpdated': DateTime.now(),
            'status': 'viewed_by_supplier',
          });

          Logger.logEvent('rfq_viewed_by_supplier', parameters: {
            'rfq_id': rfqId,
            'supplier_id': supplierId,
            'supplier_name': supplierName,
          });
        }
      }
    } catch (e, s) {
      Logger.logError('Error tracking supplier RFQ view', e, s);
    }
  }

  /// Get product interactions for a specific product
  Stream<List<ProductInteractionModel>> getProductInteractions(String productId) {
    return _firestore
        .collection(_interactionsCollection)
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductInteractionModel.fromFirestore(doc))
            .toList());
  }

  /// Get RFQ tracking data for supplier dashboard
  Stream<List<RFQTrackingModel>> getSupplierRFQs(String supplierId) {
    return _firestore
        .collection(_rfqTrackingCollection)
        .where('supplierViews', arrayContains: supplierId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RFQTrackingModel.fromFirestore(doc))
            .toList());
  }

  /// Get all RFQ tracking data for admin dashboard
  Stream<List<RFQTrackingModel>> getAllRFQTracking() {
    return _firestore
        .collection(_rfqTrackingCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RFQTrackingModel.fromFirestore(doc))
            .toList());
  }

  /// Get product analytics
  Future<RFQAnalyticsModel?> getProductAnalytics(String productId) async {
    try {
      final doc = await _firestore
          .collection(_analyticsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return RFQAnalyticsModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e, s) {
      Logger.logError('Error getting product analytics', e, s);
      return null;
    }
  }

  /// Get top products by RFQ activity
  Future<List<RFQAnalyticsModel>> getTopProductsByRFQActivity({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_analyticsCollection)
          .orderBy('totalRFQs', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RFQAnalyticsModel.fromMap(doc.data()))
          .toList();
    } catch (e, s) {
      Logger.logError('Error getting top products by RFQ activity', e, s);
      return [];
    }
  }

  /// Update product analytics
  Future<void> _updateProductAnalytics(String productId, String productName, String eventType) async {
    try {
      final docRef = _firestore.collection(_analyticsCollection).doc(productId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data()!;
          final analytics = RFQAnalyticsModel.fromMap(data);
          
          // Update counters based on event type
          int newViews = analytics.totalViews;
          int newRFQs = analytics.totalRFQs;
          int newQuotes = analytics.totalQuotes;
          
          switch (eventType) {
            case 'view':
              newViews++;
              break;
            case 'rfq_created':
              newRFQs++;
              break;
            case 'quote_received':
              newQuotes++;
              break;
          }
          
          final updatedAnalytics = RFQAnalyticsModel(
            productId: productId,
            productName: productName,
            totalViews: newViews,
            totalRFQs: newRFQs,
            totalQuotes: newQuotes,
            conversionRate: newViews > 0 ? newRFQs / newViews : 0.0,
            quoteRate: newRFQs > 0 ? newQuotes / newRFQs : 0.0,
            topEngineers: analytics.topEngineers,
            topSuppliers: analytics.topSuppliers,
            statusBreakdown: analytics.statusBreakdown,
            lastUpdated: DateTime.now(),
          );
          
          transaction.update(docRef, updatedAnalytics.toMap());
        } else {
          // Create new analytics record
          final newAnalytics = RFQAnalyticsModel(
            productId: productId,
            productName: productName,
            totalViews: eventType == 'view' ? 1 : 0,
            totalRFQs: eventType == 'rfq_created' ? 1 : 0,
            totalQuotes: eventType == 'quote_received' ? 1 : 0,
            conversionRate: 0.0,
            quoteRate: 0.0,
            topEngineers: [],
            topSuppliers: [],
            statusBreakdown: {},
            lastUpdated: DateTime.now(),
          );
          
          transaction.set(docRef, newAnalytics.toMap());
        }
      });
    } catch (e, s) {
      Logger.logError('Error updating product analytics', e, s);
    }
  }

  /// Generate session ID
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Get device information
  String _getDeviceInfo() {
    if (kIsWeb) {
      return 'Web Browser';
    } else {
      try {
        return Platform.operatingSystem;
      } catch (e) {
        return 'Unknown';
      }
    }
  }
}
