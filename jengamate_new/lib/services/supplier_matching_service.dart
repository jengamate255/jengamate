import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';


class SupplierMatchingService {


  Future<List<UserModel>> findMatchingSuppliers(RFQModel rfq) async {
    final dbService = DatabaseService();

    // 1. Get the product from the RFQ to find its category.
    final product = await dbService.getProduct(rfq.productId);
    if (product == null) {
      // If the product doesn't exist, we can't match by category.
      return [];
    }
    final categoryId = product.categoryId;

    // 2. Get all approved suppliers.
    final allSuppliers = await dbService.getApprovedSuppliers();

    // 3. Filter suppliers who are subscribed to the product's category.
    final matchedSuppliers = allSuppliers.where((supplier) {
      return supplier.subscribedCategoryIds.contains(categoryId);
    }).toList();

    return matchedSuppliers;
  }
}