class Product {
  String type;
  String thickness;
  String color;
  String length;
  String quantity;
  String remarks;
  List<String> drawings;

  Product({
    this.type = '',
    this.thickness = '',
    this.color = '',
    this.length = '',
    this.quantity = '',
    this.remarks = '',
    this.drawings = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'thickness': thickness,
      'color': color,
      'length': length,
      'quantity': quantity,
      'remarks': remarks,
      'drawings': drawings,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      type: map['type'] ?? '',
      thickness: map['thickness'] ?? '',
      color: map['color'] ?? '',
      length: map['length'] ?? '',
      quantity: map['quantity'] ?? '',
      remarks: map['remarks'] ?? '',
      drawings: List<String>.from(map['drawings'] ?? []),
    );
  }
}
