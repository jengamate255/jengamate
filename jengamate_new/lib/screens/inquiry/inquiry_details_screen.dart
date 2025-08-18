import 'package:flutter/material.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class InquiryDetailsScreen extends StatelessWidget {
  final Inquiry inquiry;

  const InquiryDetailsScreen({super.key, required this.inquiry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inquiry #${inquiry.id.substring(0, 8)}'),
      ),
      body: AdaptivePadding(
        child: ListView(
          children: [
            _buildProjectInfoCard(),
            const SizedBox(height: JMSpacing.md),
            _buildProductList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfoCard() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: JMSpacing.sm),
            Text('Project Name: ${inquiry.projectInfo['projectName']}'),
            Text('Delivery Address: ${inquiry.projectInfo['deliveryAddress']}'),
            Text(
                'Expected Delivery Date: ${inquiry.projectInfo['expectedDeliveryDate']}'),
            Text(
                'Transport Needed: ${inquiry.projectInfo['transportNeeded'] ? 'Yes' : 'No'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: JMSpacing.sm),
        ...inquiry.products.map((product) {
          return JMCard(
            margin: const EdgeInsets.only(bottom: JMSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(JMSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product Type: ${product['type']}'),
                  Text('Thickness: ${product['thickness']}'),
                  Text('Color: ${product['color']}'),
                  Text('Length: ${product['length']}'),
                  Text('Quantity: ${product['quantity']}'),
                  Text('Remarks: ${product['remarks']}'),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}