import 'package:flutter/material.dart';
import 'package:jengamate/models/supplier_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/shared_components/loading_overlay.dart';
import 'package:jengamate/ui/design_system/tokens/colors.dart';

class SupplierSelectionScreen extends StatefulWidget {
  const SupplierSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SupplierSelectionScreen> createState() => _SupplierSelectionScreenState();
}

class _SupplierSelectionScreenState extends State<SupplierSelectionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<SupplierModel> _suppliers = [];
  List<SupplierModel> _filteredSuppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterSuppliers();
    });
  }

  void _filterSuppliers() {
    if (_searchQuery.isEmpty) {
      _filteredSuppliers = _suppliers;
    } else {
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(_searchQuery) ||
               (supplier.description?.toLowerCase().contains(_searchQuery) ?? false) ||
               (supplier.contactPerson?.toLowerCase().contains(_searchQuery) ?? false) ||
               (supplier.email?.toLowerCase().contains(_searchQuery) ?? false) ||
               (supplier.categories?.any((category) =>
                   category.toLowerCase().contains(_searchQuery)) ?? false);
      }).toList();
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      setState(() => _isLoading = true);

      // For now, create some sample suppliers since we don't have a suppliers collection yet
      // In a real implementation, this would fetch from Firestore
      final sampleSuppliers = [
        SupplierModel(
          id: 'sup_001',
          name: 'ABC Manufacturing Ltd',
          description: 'Leading manufacturer of industrial equipment and machinery',
          contactPerson: 'John Smith',
          email: 'john@abc-manufacturing.com',
          phone: '+255 700 123 456',
          address: '123 Industrial Road',
          city: 'Dar es Salaam',
          country: 'Tanzania',
          categories: ['Industrial Equipment', 'Machinery'],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        SupplierModel(
          id: 'sup_002',
          name: 'Global Supplies Co.',
          description: 'Comprehensive supplier of construction materials and tools',
          contactPerson: 'Sarah Johnson',
          email: 'sarah@globalsupplies.co.tz',
          phone: '+255 755 987 654',
          address: '456 Construction Avenue',
          city: 'Dodoma',
          country: 'Tanzania',
          categories: ['Construction Materials', 'Tools'],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now(),
        ),
        SupplierModel(
          id: 'sup_003',
          name: 'Tech Solutions Ltd',
          description: 'Technology and electronics supplier for modern businesses',
          contactPerson: 'Michael Chen',
          email: 'michael@techsolutions.co.tz',
          phone: '+255 780 456 789',
          address: '789 Technology Park',
          city: 'Arusha',
          country: 'Tanzania',
          categories: ['Electronics', 'Technology', 'Software'],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        ),
        SupplierModel(
          id: 'sup_004',
          name: 'Quality Foods Ltd',
          description: 'Premium food and beverage supplier for restaurants and retailers',
          contactPerson: 'Anna Wilson',
          email: 'anna@qualityfoods.co.tz',
          phone: '+255 712 345 678',
          address: '321 Food Street',
          city: 'Mwanza',
          country: 'Tanzania',
          categories: ['Food & Beverage', 'Restaurant Supplies'],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
        SupplierModel(
          id: 'sup_005',
          name: 'Medical Supplies Co.',
          description: 'Healthcare and medical equipment supplier',
          contactPerson: 'Dr. Robert Brown',
          email: 'robert@medsupplies.co.tz',
          phone: '+255 767 890 123',
          address: '654 Health Boulevard',
          city: 'Mbeya',
          country: 'Tanzania',
          categories: ['Medical Equipment', 'Healthcare'],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _suppliers = sampleSuppliers;
        _filteredSuppliers = sampleSuppliers;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suppliers: $e')),
        );
      }
    }
  }

  void _selectSupplier(SupplierModel supplier) {
    Navigator.of(context).pop(supplier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Supplier'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: JMLoadingOverlay(
        isLoading: _isLoading,
        loadingTitle: 'Loading Suppliers',
        loadingMessage: 'Fetching supplier information...',
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search suppliers by name, category, or contact...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),

            // Suppliers List
            Expanded(
              child: _filteredSuppliers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = _filteredSuppliers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: JMCard(
                            variant: JMCardVariant.elevated,
                            title: supplier.name,
                            subtitle: supplier.contactPerson != null
                                ? 'Contact: ${supplier.contactPerson}'
                                : null,
                            leading: CircleAvatar(
                              backgroundColor: JMColors.lightScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                supplier.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: JMColors.lightScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            trailing: JMButton(
                              variant: JMButtonVariant.primary,
                              size: JMButtonSize.small,
                              label: 'Select',
                              child: const SizedBox(),
                              onPressed: () => _selectSupplier(supplier),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (supplier.description != null) ...[
                                  Text(
                                    supplier.description!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    Icon(Icons.email, size: 16, color: JMColors.info),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        supplier.email ?? 'No email provided',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: JMColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      supplier.phone ?? 'No phone provided',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: JMColors.warning),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${supplier.city ?? 'Unknown'}, ${supplier.country ?? 'Tanzania'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                if (supplier.categories != null && supplier.categories!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: supplier.categories!.map((category) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: JMColors.lightScheme.secondary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: JMColors.lightScheme.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.business,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No suppliers found for "${_searchQuery}"'
                : 'No suppliers available',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try different search terms'
                : 'Contact support to add suppliers',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          JMButton(
            variant: JMButtonVariant.primary,
            label: 'Refresh List',
            icon: Icons.refresh,
            child: const SizedBox(),
            onPressed: _loadSuppliers,
          ),
        ],
      ),
    );
  }
}
