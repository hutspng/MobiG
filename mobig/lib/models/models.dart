class Product {
  final int? id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final bool onDemand;
  final DateTime? createdAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.onDemand = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'on_demand': onDemand ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      price: map['price'] as double,
      stock: map['stock'] as int,
      onDemand: (map['on_demand'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, String> toDisplayMap() {
    return {
      'name': name,
      'category': category,
      'price': 'R\$ ${price.toStringAsFixed(2)}',
      'stock': stock.toString(),
    };
  }
}

class Client {
  final int? id;
  final String name;
  final String? nickname;
  final int purchases;
  final double totalValue;
  final DateTime? createdAt;

  Client({
    this.id,
    required this.name,
    this.nickname,
    this.purchases = 0,
    this.totalValue = 0.0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'purchases': purchases,
      'total_value': totalValue,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      nickname: map['nickname'] as String?,
      purchases: map['purchases'] as int? ?? 0,
      totalValue: map['total_value'] as double? ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, String> toDisplayMap() {
    return {
      'name': name,
      'nickname': nickname ?? '',
      'purchases': purchases.toString(),
      'total': 'R\$ ${totalValue.toStringAsFixed(2)}',
      'email': nickname ?? '',
    };
  }
}

class Sale {
  final int? id;
  final int clientId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final DateTime? saleDate;
  final String? clientName;
  final String? productName;

  Sale({
    this.id,
    required this.clientId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.saleDate,
    this.clientName,
    this.productName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'sale_date': saleDate?.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      clientId: map['client_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as double,
      totalPrice: map['total_price'] as double,
      notes: map['notes'] as String?,
      saleDate: map['sale_date'] != null
          ? DateTime.parse(map['sale_date'] as String)
          : null,
      clientName: map['client_name'] as String?,
      productName: map['product_name'] as String?,
    );
  }
}
