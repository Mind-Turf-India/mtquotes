import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';
import 'components/bank_details_screen.dart';
import 'components/buyer_details_screen.dart';
import 'components/my_details_screen.dart';
import 'components/product_details_screen.dart';
import 'invoice_model.dart';
import 'invoice_preview.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _invoiceNoController = TextEditingController();
  Map<String, dynamic>? myDetails;
  Map<String, dynamic>? buyerDetails;
  List<ProductModel> availableProducts = []; // All products from database
  List<InvoiceProductItem> invoiceProducts = []; // Products added to this invoice
  Map<String, dynamic>? bankDetails;
  String? signature;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadProducts(); // Load existing products
    _setDefaults();
  }

  void _setDefaults() {
    // Set default date to current date
    final now = DateTime.now();
    _dateController.text = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    // Set default invoice number to 1
    _invoiceNoController.text = "1";
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDetails = await _firebaseService.getUserDetails();
      if (userDetails != null && userDetails.containsKey('myDetails')) {
        setState(() {
          myDetails = userDetails['myDetails'];
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allProducts = await _firebaseService.getAllProducts();
      setState(() {
        availableProducts = allProducts; // Store in availableProducts
      });
    } catch (e) {
      print('Error loading products: $e');
      // Don't show error to user, we'll just start with an empty list
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMyDetailsScreen() async {
    try {
      // Get the current user's document ID (using the email with dots replaced)
      String userEmail = FirebaseAuth.instance.currentUser!.email!;
      String userDocId = userEmail.replaceAll('.', '_');

      // Fetch the user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .get();

      Map<String, dynamic>? initialDetails;
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('myDetails')) {
          initialDetails = userData['myDetails'] as Map<String, dynamic>;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyDetailsScreen(
            initialDetails: initialDetails,
            onSave: (details) {
              setState(() {
                myDetails = details;
              });
            },
          ),
        ),
      );
    } catch (e) {
      print('Error loading user details: $e');

      // If there's an error, still show the screen but without initial data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyDetailsScreen(
            onSave: (details) {
              setState(() {
                myDetails = details;
              });
            },
          ),
        ),
      );
    }
  }

  void _showBuyerDetailsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuyerDetailsScreen(
          initialDetails: buyerDetails,
          onSave: (details) {
            setState(() {
              buyerDetails = details;
            });
          },
        ),
      ),
    );
  }

  void _showProductDetailsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: null,
          onSave: (product) {
            // Add the new product to available products
            setState(() {
              availableProducts.add(product);
            });

            // Optionally, also add it to the invoice
            setState(() {
              invoiceProducts.add(InvoiceProductItem(
                product: product,
                quantity: 1,
              ));
            });
          },
        ),
      ),
    );
  }

  void _showProductsList() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Select Products'),
          content: availableProducts.isEmpty
              ? const Text('No products available. Please add products first.')
              : SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: availableProducts.length,
                    itemBuilder: (context, index) {
                      final product = availableProducts[index];

                      // Find existing item in invoice
                      final existingIndex = invoiceProducts.indexWhere(
                            (item) => item.product.id == product.id,
                      );

                      final existingItem = existingIndex >= 0
                          ? invoiceProducts[existingIndex]
                          : null;

                      final quantity = existingItem?.quantity ?? 0;

                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('₹${product.salePrice} per ${product.unit}'),
                        trailing: quantity > 0
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantity > 1) {
                                  // Update quantity
                                  invoiceProducts[existingIndex] = InvoiceProductItem(
                                    product: product,
                                    quantity: quantity - 1,
                                  );
                                } else {
                                  // Remove from invoice
                                  invoiceProducts.removeAt(existingIndex);
                                }

                                // Update both dialog and parent state
                                setDialogState(() {});
                                setState(() {});
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (existingIndex >= 0) {
                                  invoiceProducts[existingIndex] = InvoiceProductItem(
                                    product: product,
                                    quantity: quantity + 1,
                                  );
                                } else {
                                  invoiceProducts.add(InvoiceProductItem(
                                    product: product,
                                    quantity: 1,
                                  ));
                                }

                                // Update both dialog and parent state
                                setDialogState(() {});
                                setState(() {});
                              },
                            ),
                          ],
                        )
                            : ElevatedButton(
                          child: const Text('Add'),
                          onPressed: () {
                            invoiceProducts.add(InvoiceProductItem(
                              product: product,
                              quantity: 1,
                            ));

                            // Update both dialog and parent state
                            setDialogState(() {});
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: _showProductDetailsScreen,
              child: const Text('Create New Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProductsList() {
    if (invoiceProducts.isEmpty) {
      return const Text('No products added');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${invoiceProducts.length} products added:'),
        const SizedBox(height: 4),
        ...invoiceProducts.map((item) => Text(
          '• ${item.product.name} × ${item.quantity} ${item.product.unit}',
          style: const TextStyle(fontSize: 12),
        )).toList(),
      ],
    );
  }



  void _showBankDetailsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankDetailsScreen(
          initialDetails: bankDetails,
          onSave: (details) {
            setState(() {
              bankDetails = details;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (myDetails == null || buyerDetails == null || invoiceProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoice = InvoiceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _dateController.text,
        invoiceNo: _invoiceNoController.text,
        myDetails: myDetails!,
        buyerDetails: buyerDetails!,
        products: invoiceProducts,
        bankDetails: bankDetails,
        signature: signature,
      );

      await _firebaseService.saveInvoice(invoice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully')),
      );

      // Navigate to PDF Preview screen instead
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(invoice: invoice),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving invoice: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Text('Duplicate'),
              ),
              const PopupMenuItem(
                value: 'open_pdf',
                child: Text('Open PDF'),
              ),
              const PopupMenuItem(
                value: 'print_pdf',
                child: Text('Print PDF'),
              ),
              const PopupMenuItem(
                value: 'save_pdf',
                child: Text('Save PDF to Phone'),
              ),
              const PopupMenuItem(
                value: 'share_pdf',
                child: Text('Share PDF'),
              ),
              const PopupMenuItem(
                value: 'cancel_invoice',
                child: Text('Cancel Invoice'),
              ),
            ],
            onSelected: (value) {
              // Handle menu item selection
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date',style: TextStyle(color: Colors.black),),
                        TextField(
                          controller: _dateController,
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: dividerColor),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryBlue),
                            ),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                _dateController.text = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice No.',style: TextStyle(color: Colors.black)),
                        TextField(
                          controller: _invoiceNoController,
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: dividerColor),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('My Details'),
                subtitle: myDetails != null
                    ? Text(myDetails!['companyName'] ?? 'Details added')
                    : const Text('No details added'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showMyDetailsScreen,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Buyer Details'),
                subtitle: buyerDetails != null
                    ? Text(buyerDetails!['customerName'] ?? 'Details added')
                    : const Text('No details added'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showBuyerDetailsScreen,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Product Details'),
                subtitle: _buildSelectedProductsList(),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Button to view/select existing products
                    IconButton(
                      icon: const Icon(Icons.list),
                      onPressed: _showProductsList,
                    ),
                    // Button to add a new product
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showProductDetailsScreen,
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Bank Details (Optional)'),
                subtitle: bankDetails != null
                    ? Text(bankDetails!['bankName'] ?? 'Details added')
                    : const Text('No details added'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showBankDetailsScreen,
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Handle delete
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                  ElevatedButton(
                    onPressed: _saveInvoice,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoicePreviewScreen {
}