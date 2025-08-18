import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/utils/logger.dart';

class PaginationHelper<T> {
  final Query query;
  final int pageSize;
  final T Function(DocumentSnapshot) fromFirestore;
  
  PaginationHelper({
    required this.query,
    required this.pageSize,
    required this.fromFirestore,
  });
  
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoading = false;
  
  /// Get next page of data
  Future<List<T>> getNextPage() async {
    if (_isLoading || !_hasMoreData) {
      return [];
    }
    
    _isLoading = true;
    
    try {
      Query paginatedQuery = query.limit(pageSize);
      
      if (_lastDocument != null) {
        paginatedQuery = paginatedQuery.startAfterDocument(_lastDocument!);
      }
      
      final snapshot = await paginatedQuery.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        return [];
      }
      
      _lastDocument = snapshot.docs.last;
      
      final items = snapshot.docs.map(fromFirestore).toList();
      
      Logger.log('Pagination: Loaded ${items.length} items (page_size: $pageSize, has_more: $_hasMoreData)');
      
      return items;
    } catch (e, stackTrace) {
      Logger.logError('Pagination error', e, stackTrace);
      return [];
    } finally {
      _isLoading = false;
    }
  }
  
  /// Reset pagination
  void reset() {
    _lastDocument = null;
    _hasMoreData = true;
    _isLoading = false;
  }
  
  /// Check if more data is available
  bool get hasMoreData => _hasMoreData;
  
  /// Check if currently loading
  bool get isLoading => _isLoading;
}

class PaginationConfig {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 5;
  
  static int validatePageSize(int pageSize) {
    if (pageSize < minPageSize) return minPageSize;
    if (pageSize > maxPageSize) return maxPageSize;
    return pageSize;
  }
}