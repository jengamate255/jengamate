import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:uuid/uuid.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _items = <InvoiceItem>[];
  bool _isLoading = false;
  bool _isCustomerExpanded = false;
  bool _isItemsExpanded = true;
  bool _isNotesExpanded = false;

  // Form controllers
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();
  final _taxRateController = TextEditingController(text: '18');
  final _discountAmountController = TextEditingController(text: '0');

  // Item form controllers
  final _itemDescriptionController = TextEditingController();
  final _itemQuantityController = TextEditingController(text: '1');
  final _itemUnitPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default dates
    final now = DateTime.now();
    _issueDateController.text = _formatDate(now);
    _dueDateController.text = _formatDate(now.add(const Duration(days: 30)));
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _issueDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    _taxRateController.dispose();
    _discountAmountController.dispose();
    _itemDescriptionController.dispose();
    _itemQuantityController.dispose();
    _itemUnitPriceController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  void _addItem() {
    if (_itemDescriptionController.text.isEmpty ||
        _itemQuantityController.text.isEmpty ||
        _itemUnitPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all item fields')),
      );
      return;
    }

    final quantity = int.tryParse(_itemQuantityController.text) ?? 1;
    final unitPrice = double.tryParse(_itemUnitPriceController.text) ?? 0.0;

    if (quantity <= 0 || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity and price')),
      );
      return;
    }

    setState(() {
      _items.add(
        InvoiceItem(
          id: const Uuid().v4(),
          description: _itemDescriptionController.text,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );

      // Clear the form
      _itemDescriptionController.clear();
      _itemQuantityController.text = '1';
      _itemUnitPriceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoice = InvoiceModel(
        id: const Uuid().v4(),
        invoiceNumber: InvoiceModel.generateInvoiceNumber(),
        customerId: 'customer_${_customerEmailController.text}',
        customerName: _customerNameController.text,
        customerEmail: _customerEmailController.text,
        customerPhone: _customerPhoneController.text.isNotEmpty
            ? _customerPhoneController.text
            : null,
        customerAddress: _customerAddressController.text.isNotEmpty
            ? _customerAddressController.text
            : null,
        issueDate: DateTime.parse(_issueDateController.text),
        dueDate: DateTime.parse(_dueDateController.text),
        items: _items,
        taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
        discountAmount: double.tryParse(_discountAmountController.text) ?? 0.0,
        status: 'draft',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        termsAndConditions: _termsController.text.isNotEmpty
            ? _termsController.text
            : 'Payment due within 30 days',
      );

      final invoiceService =
          Provider.of<InvoiceService>(context, listen: false);
      await invoiceService.createInvoice(invoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invoice: $e')),
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
        title: const Text('Create Invoice'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitInvoice,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Section
                    _buildSection(
                      title: 'Customer Information',
                      isExpanded: _isCustomerExpanded,
                      onExpand: (value) {
                        setState(() => _isCustomerExpanded = value);
                      },
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _customerNameController,
                            label: 'Customer Name',
                            isRequired: true,
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _customerEmailController,
                            label: 'Email',
                            isRequired: true,
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _customerPhoneController,
                            label: 'Phone (Optional)',
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _customerAddressController,
                            label: 'Address (Optional)',
                            maxLines: 2,
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dates Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            controller: _issueDateController,
                            label: 'Issue Date',
                            onTap: () => _selectDate(context, _issueDateController),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            controller: _dueDateController,
                            label: 'Due Date',
                            onTap: () => _selectDate(context, _dueDateController),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Items Section
                      _buildSection(
                        title: 'Items',
                        isExpanded: _isItemsExpanded,
                        onExpand: (value) {
                          setState(() => _isItemsExpanded = value);
                        },
                        child: Column(
                          children: [
                            // Items List
                            if (_items.isNotEmpty) ...[
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(item.description),
                                      subtitle: Text(
                                          '${item.quantity} x ${_formatCurrency(item.unitPrice)} = ${_formatCurrency(item.total)}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Add Item Form
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Add New Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _itemDescriptionController,
                              label: 'Description',
                              icon: Icons.description,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _itemQuantityController,
                                    label: 'Qty',
                                    keyboardType: TextInputType.number,
                                    icon: Icons.numbers,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _itemUnitPriceController,
                                    label: 'Unit Price',
                                    keyboardType: TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    icon: Icons.attach_money,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Tax & Discount
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _taxRateController,
                            label: 'Tax Rate (%)',
                            keyboardType: TextInputType.number,
                            icon: Icons.percent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _discountAmountController,
                            label: 'Discount (TSh)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            icon: Icons.discount,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes & Terms
                    _buildSection(
                      title: 'Additional Information',
                      isExpanded: _isNotesExpanded,
                      onExpand: (value) {
                        setState(() => _isNotesExpanded = value);
                      },
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _notesController,
                            label: 'Notes (Optional)',
                            maxLines: 3,
                            icon: Icons.notes,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _termsController,
                            label: 'Terms & Conditions',
                            maxLines: 3,
                            icon: Icons.gavel,
                            hint: 'Payment due within 30 days',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preview Button
                    if (_items.isNotEmpty) ...[
                      const Text(
                        'Invoice Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_items.length} Item${_items.length != 1 ? 's' : ''} • ${_calculateTotal().toStringAsFixed(2)} TSh',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subtotal: ${_formatCurrency(_calculateSubtotal())}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (double.tryParse(_taxRateController.text) != null &&
                                  double.tryParse(_taxRateController.text)! > 0)
                                Text(
                                  'Tax (${_taxRateController.text}%): ${_formatCurrency(_calculateTax())}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              if (double.tryParse(_discountAmountController.text) !=
                                      null &&
                                  double.tryParse(_discountAmountController.text)! >
                                      0)
                                Text(
                                  'Discount: -${_formatCurrency(double.tryParse(_discountAmountController.text) ?? 0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              const Divider(),
                              Text(
                                'Total: ${_formatCurrency(_calculateTotal())}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitInvoice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Invoice',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isExpanded,
    required ValueChanged<bool> onExpand,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpand,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }

  String _formatCurrency(double amount) {
    return 'TSh ${amount.toStringAsFixed(2)}';
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  double _calculateTax() {
    final subtotal = _calculateSubtotal();
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    return subtotal * (taxRate / 100);
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final tax = _calculateTax();
    final discount = double.tryParse(_discountAmountController.text) ?? 0.0;
    return (subtotal + tax) - discount;
  }
}
