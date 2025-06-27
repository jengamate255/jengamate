import 'package:image_picker/image_picker.dart';

class Product {
  String type;
  String thickness;
  String color;
  String dimensions;
  int quantity;
  XFile? technicalDrawing; // Used for picking the file in the UI
  String drawingUrl;      // Used for storing the download URL in Firestore

  Product({
    this.type = '',
    this.thickness = '',
    this.color = '',
    this.dimensions = '',
    this.quantity = 1,
    this.technicalDrawing,
    this.drawingUrl = '',
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      type: map['type'] ?? '',
      thickness: map['thickness'] ?? '',
      color: map['color'] ?? '',
      dimensions: map['dimensions'] ?? '',
      quantity: map['quantity'] ?? 1,
      drawingUrl: map['drawingUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'thickness': thickness,
      'color': color,
      'dimensions': dimensions,
      'quantity': quantity,
      'drawingUrl': drawingUrl,
    };
  }
}
