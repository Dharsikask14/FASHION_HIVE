class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> additionalImages;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviewCount;
  final bool isNew;
  final bool isFeatured;
  final int stock;
  final List<String> tags;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.description,
    this.sizes = const [],
    this.colors = const [],
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isNew = false,
    this.isFeatured = false,
    this.stock = 10,
    this.tags = const [],
  });

  bool get isOnSale => originalPrice != null && originalPrice! > price;
  double get discountPercentage =>
      isOnSale ? ((originalPrice! - price) / originalPrice! * 100) : 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'description': description,
      'sizes': sizes,
      'colors': colors,
      'rating': rating,
      'reviewCount': reviewCount,
      'isNew': isNew,
      'isFeatured': isFeatured,
      'stock': stock,
      'tags': tags,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: map['originalPrice'] != null ? (map['originalPrice'] as num).toDouble() : null,
      imageUrl: map['imageUrl'] ?? '',
      additionalImages: List<String>.from(map['additionalImages'] ?? []),
      description: map['description'] ?? '',
      sizes: List<String>.from(map['sizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isNew: map['isNew'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      stock: map['stock'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class CartItem {
  final Product product;
  String selectedSize;
  String selectedColor;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? selectedSize,
    String? selectedColor,
    int? quantity,
  }) {
    return CartItem(
      product: product,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(), // embed full product safely
      'productId': product.id,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, String docId) {
    return CartItem(
      product: Product.fromMap(Map<String, dynamic>.from(map['product'] ?? {}), map['productId'] ?? ''),
      selectedSize: map['selectedSize'] ?? '',
      selectedColor: map['selectedColor'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}

class Review {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime? date;
  final String? size;
  final bool verified;

  const Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    this.date,
    this.size,
    this.verified = false,
  });
}

class Address {
  String id;
  String name;
  String phone;
  String addressLine1;
  String addressLine2;
  String city;
  String district;
  String state;
  String pincode;
  bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault,
      };

  factory Address.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Address(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  String get fullAddress =>
      '$addressLine1${addressLine2.isNotEmpty ? ', $addressLine2' : ''}, $city, $district, $state - $pincode';
}


class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final Address address;
  final String status;
  final DateTime placedAt;
  final String paymentMethod;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.status,
    required this.placedAt,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'address': address.toMap(),
      'status': status,
      'placedAt': placedAt.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => CartItem.fromMap(Map<String, dynamic>.from(i), '')) // CartItem doesn't need external ID, we use product ID mapped inside
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      address: Address.fromMap(Map<String, dynamic>.from(map['address'] ?? {})),
      status: map['status'] ?? '',
      placedAt: map['placedAt'] != null ? DateTime.tryParse(map['placedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? '',
    );
  }
}
