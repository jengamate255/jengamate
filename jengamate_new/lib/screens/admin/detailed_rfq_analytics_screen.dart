import 'package:flutter/material.dart';
import 'package:jengamate/models/product_interaction_model.dart';

class DetailedRFQAnalyticsScreen extends StatelessWidget {
  const DetailedRFQAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed RFQ Analytics'),
      ),
      body: const Center(
        child: Text('Detailed RFQ Analytics will be displayed here.'),
      ),
    );
  }
}
