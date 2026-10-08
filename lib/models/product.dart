/// Élément d'un pack (nom du produit et quantité).
class PackItem {
  final String name;
  final int quantity;
  final String? unit;

  const PackItem({required this.name, required this.quantity, this.unit});

  factory PackItem.fromJson(Map<String, dynamic> json) => PackItem(
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        unit: json['unit'] as String?,
      );
}

class Product {
  final int id;
  final String category;
  final int? subcategoryId;

  /// `product` ou `pack`.
  final String type;
  final String name;
  final String? description;
  final int price;
  final String? unit;
  final String? imageUrl;
  final String? vendorName;
  final String pickupAddress;
  final List<PackItem> items;

  const Product({
    required this.id,
    required this.category,
    this.subcategoryId,
    this.type = 'product',
    required this.name,
    this.description,
    required this.price,
    this.unit,
    this.imageUrl,
    this.vendorName,
    required this.pickupAddress,
    this.items = const [],
  });

  bool get isPack => type == 'pack';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        category: json['category'] as String,
        subcategoryId: json['subcategory_id'] as int?,
        type: json['type'] as String? ?? 'product',
        name: json['name'] as String,
        description: json['description'] as String?,
        price: json['price'] as int,
        unit: json['unit'] as String?,
        imageUrl: json['image_url'] as String?,
        vendorName: json['vendor_name'] as String?,
        pickupAddress: json['pickup_address'] as String,
        items: ((json['items'] as List?) ?? const []).map((e) => PackItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Sous-catégorie (onglet vertical), nommée par l'admin.
class Subcategory {
  final int id;
  final String name;

  const Subcategory({required this.id, required this.name});

  factory Subcategory.fromJson(Map<String, dynamic> json) =>
      Subcategory(id: json['id'] as int, name: json['name'] as String);
}

/// Annonce promo (bandeau de l'accueil).
class Promotion {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final Product? product;

  const Promotion({required this.id, required this.title, required this.body, this.imageUrl, this.product});

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        imageUrl: json['image_url'] as String?,
        product:
            json['product'] is Map<String, dynamic> ? Product.fromJson(json['product'] as Map<String, dynamic>) : null,
      );
}

class PaymentMethodInfo {
  final String method;
  final String label;

  /// Numéro marchand (mode manuel uniquement).
  final String? merchantNumber;

  const PaymentMethodInfo({required this.method, required this.label, this.merchantNumber});

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) => PaymentMethodInfo(
        method: json['method'] as String,
        label: json['label'] as String,
        merchantNumber: json['merchant_number'] as String?,
      );
}

class PaymentInfo {
  /// `gateway` : paiement automatique via l'agrégateur ; `manual` : capture d'écran vérifiée par l'agence.
  final String mode;
  final String? gateway;
  final String? feeNote;
  final String merchantName;
  final String? instructions;
  final List<PaymentMethodInfo> methods;

  const PaymentInfo({
    this.mode = 'manual',
    this.gateway,
    this.feeNote,
    required this.merchantName,
    this.instructions,
    required this.methods,
  });

  bool get isGateway => mode == 'gateway';

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
        mode: json['mode'] as String? ?? 'manual',
        gateway: json['gateway'] as String?,
        feeNote: json['fee_note'] as String?,
        merchantName: json['merchant_name'] as String? ?? 'VOOM Delivery',
        instructions: json['instructions'] as String?,
        methods: (json['methods'] as List).map((m) => PaymentMethodInfo.fromJson(m as Map<String, dynamic>)).toList(),
      );
}

/// Réponse de POST /deliveries/{id}/checkout.
class CheckoutStart {
  final int paymentId;

  /// `ussd` : validation sur le téléphone (PayGate) ; `redirect` : page de paiement à ouvrir (KKiaPay).
  final String mode;
  final String message;
  final String? redirectUrl;

  const CheckoutStart({required this.paymentId, required this.mode, required this.message, this.redirectUrl});

  factory CheckoutStart.fromJson(Map<String, dynamic> json) => CheckoutStart(
        paymentId: (json['payment'] as Map<String, dynamic>)['id'] as int,
        mode: json['mode'] as String,
        message: json['message'] as String,
        redirectUrl: json['redirect_url'] as String?,
      );
}
