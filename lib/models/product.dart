class Product {
  final int id;
  final String category;
  final String name;
  final String? description;
  final int price;
  final String? unit;
  final String? imageUrl;
  final String? vendorName;
  final String pickupAddress;

  const Product({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    required this.price,
    this.unit,
    this.imageUrl,
    this.vendorName,
    required this.pickupAddress,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        category: json['category'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: json['price'] as int,
        unit: json['unit'] as String?,
        imageUrl: json['image_url'] as String?,
        vendorName: json['vendor_name'] as String?,
        pickupAddress: json['pickup_address'] as String,
      );
}

class PaymentMethodInfo {
  final String method;
  final String label;
  final String merchantNumber;

  const PaymentMethodInfo({required this.method, required this.label, required this.merchantNumber});

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) => PaymentMethodInfo(
        method: json['method'] as String,
        label: json['label'] as String,
        merchantNumber: json['merchant_number'] as String,
      );
}

class PaymentInfo {
  final String merchantName;
  final String? instructions;
  final List<PaymentMethodInfo> methods;

  const PaymentInfo({required this.merchantName, this.instructions, required this.methods});

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
        merchantName: json['merchant_name'] as String? ?? 'VOOM Delivery',
        instructions: json['instructions'] as String?,
        methods: (json['methods'] as List).map((m) => PaymentMethodInfo.fromJson(m as Map<String, dynamic>)).toList(),
      );
}
