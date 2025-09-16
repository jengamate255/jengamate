import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/supplier_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/models/enums/order_enums.dart';
// import 'package:intl/intl.dart'; // Removed unused import
import 'package:jengamate/screens/rfq/widgets/product_selection_screen.dart'; // Import for ProductSelectionScreen
import 'package:jengamate/screens/order/widgets/user_selection_screen.dart'; // Import for UserSelectionScreen
import 'package:jengamate/screens/order/widgets/supplier_selection_screen.dart'; // Import for SupplierSelectionScreen
import 'package:jengamate/models/order_item_model.dart'; // Import for OrderItem

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _orderNumberController = TextEditingController();

  UserModel? _selectedCustomer;
  ProductModel? _selectedProduct;
  SupplierModel? _selectedSupplier;
  OrderStatus _selectedStatus = OrderStatus.pending;
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isLoading = false;

  @override
  void dispose() {
    _customerController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _deliveryAddressController.dispose();
    _notesController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer() async {
    final selected = await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserSelectionScreen()));
    if (selected != null && selected is UserModel) {
      setState(() {
        _selectedCustomer = selected;
        _customerController.text = '${selected.firstName} ${selected.lastName}';
      });
    }
  }

  Future<void> _selectProduct() async {
    final selected = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductSelectionScreen()));
    if (selected != null && selected is Map<String, String>) {
      setState(() {
        _selectedProduct = ProductModel(
          id: selected['productId']!,
          name: selected['productName']!,
          description: '',
          imageUrl: '',
          price: 0.0,
          stock: 0,
          categoryId: '',
          supplierId: _selectedSupplier?.id ?? '', // Use selected supplier
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'active',
          isActive: true,
        );
        _productController.text = selected['productName']!;
        _priceController.text = _selectedProduct!.price.toStringAsFixed(2); // Auto-fill price from product
      });
    }
  }

  Future<void> _selectSupplier() async {
    final selected = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplierSelectionScreen()));
    if (selected != null && selected is SupplierModel) {
      setState(() {
        _selectedSupplier = selected;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newOrder = OrderModel(
        id: '', // Firestore will generate this
        orderNumber: _orderNumberController.text.trim().isNotEmpty ? _orderNumberController.text.trim() : null,
        customerId: _selectedCustomer!.uid,
        customerName: _customerController.text,
        customerEmail: _selectedCustomer?.email ?? 'unknown@example.com',
        customerPhone: _selectedCustomer?.phoneNumber,
        deliveryAddress: _deliveryAddressController.text.trim(),
        supplierId: _selectedSupplier?.id ?? '',
        supplierName: _selectedSupplier?.name ?? 'No supplier selected',
        items: [
          OrderItem(
            productId: _selectedProduct?.id ?? '',
            productName: _selectedProduct?.name ?? '',
            quantity: int.parse(_quantityController.text),
            price: double.parse(_priceController.text),
          ),
        ],
        totalAmount: double.parse(_priceController.text) * int.parse(_quantityController.text),
        status: _selectedStatus,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Additional fields can be added as needed
      );

      // Try inserting into Supabase first, otherwise use Firestore
      final supabaseOk = await _databaseService.addOrderSupabase(newOrder);
      if (!supabaseOk) {
        await _databaseService.addOrder(newOrder);
      }
      Logger.log('Order created: ${newOrder.orderNumber ?? newOrder.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${newOrder.orderNumber ?? newOrder.id} created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.logError('Error creating order', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order Number (Optional)
                    TextFormField(
                      controller: _orderNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Order Number (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment Method selection
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: <String>[
                        'Cash on Delivery',
                        'Mobile Money',
                        'Bank Transfer',
                      ].map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Customer Selection
                    TextFormField(
                      controller: _customerController,
                      readOnly: true,
                      onTap: _selectCustomer,
                      decoration: InputDecoration(
                        labelText: 'Select Customer',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _selectCustomer,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 16),
                    // Supplier Selection
                    TextFormField(
                      controller: TextEditingController(text: _selectedSupplier?.name ?? ''),
                      readOnly: true,
                      onTap: _selectSupplier,
                      decoration: InputDecoration(
                        labelText: 'Select Supplier',
                        hintText: 'Choose a supplier for this order',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.business),
                          onPressed: _selectSupplier,
                        ),
                      ),
                      validator: (value) => _selectedSupplier == null ? 'Please select a supplier' : null,
                    ),
                    const SizedBox(height: 16),
                    // Product Selection
                    TextFormField(
                      controller: _productController,
                      readOnly: true,
                      onTap: _selectProduct,
                      decoration: InputDecoration(
                        labelText: 'Select Product',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _selectProduct,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please select a product' : null,
                    ),
                    const SizedBox(height: 16),
                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter quantity';
                        if (int.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Price (auto-filled but editable)
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter price';
                        if (double.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Status Dropdown
                    DropdownButtonFormField<OrderStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Order Status',
                        border: OutlineInputBorder(),
                      ),
                      items: OrderStatus.values.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status.toString().split('.').last));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Delivery Address
                    TextFormField(
                      controller: _deliveryAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter delivery address' : null,
                    ),
                    const SizedBox(height: 16),
                    // Additional Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Order'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
