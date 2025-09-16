import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/models/product_model.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> addProduct(ProductModel product) async {
    try {
      await _supabase.from('products').insert(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _supabase.from('products').update(product.toMap()).eq('id', product.id);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }
}
