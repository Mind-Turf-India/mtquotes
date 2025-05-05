import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InvoiceProductItem {
  final ProductModel product;
  final int quantity;

  InvoiceProductItem({
    required this.product,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(includeTimestamp: false),
      'quantity': quantity,
    };
  }

  factory InvoiceProductItem.fromMap(Map<String, dynamic> map) {
    return InvoiceProductItem(
      product: ProductModel.fromMap(map['product']),
      quantity: map['quantity'] ?? 1,
    );
  }
}

class InvoiceModel {
  final String id;
  final String date;
  final String invoiceNo;
  final Map<String, dynamic> myDetails;
  final Map<String, dynamic> buyerDetails;
  final List<InvoiceProductItem> products; // Changed from List<ProductModel>
  final Map<String, dynamic>? bankDetails;
  final String? signature;

  InvoiceModel({
    required this.id,
    required this.date,
    required this.invoiceNo,
    required this.myDetails,
    required this.buyerDetails,
    required this.products,
    this.bankDetails,
    this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'invoiceNo': invoiceNo,
      'myDetails': myDetails,
      'buyerDetails': buyerDetails,
      'products': products.map((item) => item.toMap()).toList(),
      'bankDetails': bankDetails,
      'signature': signature,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      date: map['date'],
      invoiceNo: map['invoiceNo'],
      myDetails: Map<String, dynamic>.from(map['myDetails']),
      buyerDetails: Map<String, dynamic>.from(map['buyerDetails']),
      products: List<InvoiceProductItem>.from(
        (map['products'] as List).map((item) => InvoiceProductItem.fromMap(item)),
      ),
      bankDetails: map['bankDetails'] != null
          ? Map<String, dynamic>.from(map['bankDetails'])
          : null,
      signature: map['signature'],
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String itemType; // Goods or Services
  final double salePrice;
  final String unit;
  final bool isTaxInclusive;
  final double gstRate;
  final String gstType; // GST @ 0, GST @ 5%, etc.
  final double cessRate;
  final String cessType; // Percent Wise or Fixed
  final double purchasePrice;
  final String gstTreatment; // Exclusive GST, etc.
  final double wholesalePrice;
  final int minWholesaleQty;
  final bool maintainStock;
  final int openingStock;
  final String openingStockUnit;
  final DateTime openingStockDate;
  final int lowStockAlert;
  final String barcode;
  final String hsn;

  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.itemType = 'Goods',
    required this.salePrice,
    this.unit = 'NOS',
    this.isTaxInclusive = false,
    this.gstRate = 0,
    this.gstType = 'GST @ 0',
    this.cessRate = 0,
    this.cessType = '% Percent Wise',
    this.purchasePrice = 0,
    this.gstTreatment = 'Exclusive GST',
    this.wholesalePrice = 0,
    this.minWholesaleQty = 0,
    this.maintainStock = false,
    this.openingStock = 0,
    this.openingStockUnit = '',
    DateTime? openingStockDate,
    this.lowStockAlert = 0,
    this.barcode = '',
    this.hsn = '',
  }) : openingStockDate = openingStockDate ?? DateTime.now();

  // Helper method to get GST rate from GST type
  static double getGstRateFromType(String gstType) {
    switch (gstType) {
      case 'GST @ 5%':
        return 5.0;
      case 'GST @ 12%':
        return 12.0;
      case 'GST @ 18%':
        return 18.0;
      case 'GST @ 28%':
        return 28.0;
      case 'GST @ 0':
      default:
        return 0.0;
    }
  }

  // Helper method to get GST type from GST rate
  static String getGstTypeFromRate(double gstRate) {
    if (gstRate == 5.0) return 'GST @ 5%';
    if (gstRate == 12.0) return 'GST @ 12%';
    if (gstRate == 18.0) return 'GST @ 18%';
    if (gstRate == 28.0) return 'GST @ 28%';
    return 'GST @ 0';
  }

  // Calculate price excluding GST (if tax inclusive)
  // In ProductModel class

// Calculate price excluding GST (if tax inclusive)
  double get priceExcludingGst {
    if (isTaxInclusive && gstRate > 0) {
      return salePrice / (1 + (gstRate / 100));
    }
    return salePrice;
  }

// Calculate GST amount for given quantity
  double calculateGstAmount(int quantity) {
    double taxableValue = priceExcludingGst * quantity;
    return taxableValue * (gstRate / 100);
  }

// Calculate CGST amount for given quantity
  double calculateCgstAmount(int quantity) {
    return calculateGstAmount(quantity) / 2;
  }

// Calculate SGST amount for given quantity
  double calculateSgstAmount(int quantity) {
    return calculateGstAmount(quantity) / 2;
  }

// Calculate total amount including GST for given quantity
  double calculateTotalAmount(int quantity) {
    double taxableValue = priceExcludingGst * quantity;
    double gstAmount = calculateGstAmount(quantity);
    return taxableValue + gstAmount;
  }

  Map<String, dynamic> toMap({bool includeTimestamp = true}) {
    final map = {
      'id': id,
      'name': name,
      'description': description,
      'itemType': itemType,
      'salePrice': salePrice,
      'unit': unit,
      'isTaxInclusive': isTaxInclusive,
      'gstRate': gstRate,
      'gstType': gstType,
      'cessRate': cessRate,
      'cessType': cessType,
      'purchasePrice': purchasePrice,
      'gstTreatment': gstTreatment,
      'wholesalePrice': wholesalePrice,
      'minWholesaleQty': minWholesaleQty,
      'maintainStock': maintainStock,
      'openingStock': openingStock,
      'openingStockUnit': openingStockUnit,
      'openingStockDate': openingStockDate.toIso8601String(),
      'lowStockAlert': lowStockAlert,
      'barcode': barcode,
      'hsn': hsn,
    };

    if (includeTimestamp) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      itemType: map['itemType'] ?? 'Goods',
      salePrice: (map['salePrice'] is int)
          ? (map['salePrice'] as int).toDouble()
          : (map['salePrice'] as double?) ?? 0.0,
      unit: map['unit'] ?? 'NOS',
      isTaxInclusive: map['isTaxInclusive'] ?? false,
      gstRate: (map['gstRate'] is int)
          ? (map['gstRate'] as int).toDouble()
          : (map['gstRate'] as double?) ?? 0.0,
      gstType: map['gstType'] ?? 'GST @ 0',
      cessRate: (map['cessRate'] is int)
          ? (map['cessRate'] as int).toDouble()
          : (map['cessRate'] as double?) ?? 0.0,
      cessType: map['cessType'] ?? '% Percent Wise',
      purchasePrice: (map['purchasePrice'] is int)
          ? (map['purchasePrice'] as int).toDouble()
          : (map['purchasePrice'] as double?) ?? 0.0,
      gstTreatment: map['gstTreatment'] ?? 'Exclusive GST',
      wholesalePrice: (map['wholesalePrice'] is int)
          ? (map['wholesalePrice'] as int).toDouble()
          : (map['wholesalePrice'] as double?) ?? 0.0,
      minWholesaleQty: map['minWholesaleQty'] ?? 0,
      maintainStock: map['maintainStock'] ?? false,
      openingStock: map['openingStock'] ?? 0,
      openingStockUnit: map['openingStockUnit'] ?? '',
      openingStockDate: map['openingStockDate'] is String
          ? DateTime.parse(map['openingStockDate'])
          : map['openingStockDate'] is Timestamp
          ? (map['openingStockDate'] as Timestamp).toDate()
          : DateTime.now(),
      lowStockAlert: map['lowStockAlert'] ?? 0,
      barcode: map['barcode'] ?? '',
      hsn: map['hsn'] ?? '',
    );
  }
}


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get the current user's document ID (email with dots replaced by underscores)
  String get _userDocId {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    String userEmail = _auth.currentUser!.email!;
    return userEmail.replaceAll('.', '_');
  }

  // Get user details from Firestore
  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('details')
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  // Save user details to Firestore
  Future<void> saveUserDetails(Map<String, dynamic> details) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('details')
          .set({'myDetails': details}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user details: $e');
    }
  }

  // Save an invoice to Firestore
  Future<void> saveInvoice(InvoiceModel invoice) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc(invoice.id)
          .set(invoice.toMap());
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  // Get all invoices
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) =>
          InvoiceModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get invoices: $e');
    }
  }

  // Get a specific invoice
  Future<InvoiceModel?> getInvoice(String invoiceId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc(invoiceId)
          .get();

      if (doc.exists) {
        return InvoiceModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc(invoiceId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  // Upload a logo file
  Future<String> uploadLogo(File file) async {
    try {
      final String fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('users/$_userDocId/logo/$fileName');

      final uploadTask = storageRef.putFile(file);
      final taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload logo: $e');
    }
  }

  // Upload a signature image
  Future<String> uploadSignature(File file) async {
    try {
      final String fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('users/$_userDocId/signatures/$fileName');

      final uploadTask = storageRef.putFile(file);
      final taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload signature: $e');
    }
  }

  // Save a product to Firestore
  Future<void> saveProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('products')
          .collection('items')
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      throw Exception('Failed to save product: $e');
    }
  }

  // Get a product from Firestore
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('products')
          .collection('items')
          .doc(productId)
          .get();

      if (doc.exists) {
        return ProductModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Get all products from Firestore
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('products')
          .collection('items')
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Delete a product from Firestore
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('products')
          .collection('items')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}