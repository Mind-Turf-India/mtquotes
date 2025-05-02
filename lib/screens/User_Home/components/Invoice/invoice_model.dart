class Invoice {
  String id;
  String invoiceNumber;
  DateTime date;
  UserDetails sellerDetails;
  UserDetails buyerDetails;
  List<Product> products;
  BankDetails bankDetails;
  String signature;
  DateTime createdAt;
  double total;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.sellerDetails,
    required this.buyerDetails,
    required this.products,
    required this.bankDetails,
    required this.signature,
    required this.createdAt,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'sellerDetails': sellerDetails.toMap(),
      'buyerDetails': buyerDetails.toMap(),
      'products': products.map((product) => product.toMap()).toList(),
      'bankDetails': bankDetails.toMap(),
      'signature': signature,
      'createdAt': createdAt.toIso8601String(),
      'total': total,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      date: DateTime.parse(map['date']),
      sellerDetails: UserDetails.fromMap(map['sellerDetails']),
      buyerDetails: UserDetails.fromMap(map['buyerDetails']),
      products: List<Product>.from(
          map['products']?.map((x) => Product.fromMap(x)) ?? []),
      bankDetails: BankDetails.fromMap(map['bankDetails']),
      signature: map['signature'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      total: map['total']?.toDouble() ?? 0.0,
    );
  }
}

class UserDetails {
  String name;
  String email;
  String phone;
  String address;

  UserDetails({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
    );
  }
}

class Product {
  String name;
  double price;
  int quantity;
  String description;

  Product({
    this.name = '',
    this.price = 0.0,
    this.quantity = 1,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      description: map['description'] ?? '',
    );
  }
}

class BankDetails {
  String bankName;
  String accountNumber;
  String ifscCode;
  String accountName;

  BankDetails({
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.accountName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountName': accountName,
    };
  }

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      ifscCode: map['ifscCode'] ?? '',
      accountName: map['accountName'] ?? '',
    );
  }
}