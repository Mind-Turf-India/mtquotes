import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mtquotes/screens/User_Home/files_screen.dart';

import 'invoice_model.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({Key? key}) : super(key: key);

  @override
  _InvoiceCreateScreenState createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  late Invoice _invoice;
  //final InvoiceService _invoiceService = InvoiceService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoice = Invoice(
      id: '',
      invoiceNumber: '1',
      date: DateTime.now(),
      sellerDetails: UserDetails(),
      buyerDetails: UserDetails(),
      products: [],
      bankDetails: BankDetails(),
      signature: '',
      createdAt: DateTime.now(),
      total: 0,
    );
  }

  Future<void> _saveInvoice() async {
    if (_invoice.sellerDetails.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your details')),
      );
      return;
    }

    if (_invoice.buyerDetails.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add buyer details')),
      );
      return;
    }

    if (_invoice.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add product details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      //await _invoiceService.saveInvoice(_invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
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
    ).then((value) {
      // Handle menu selection
      if (value != null) {
        switch (value) {
          case 'duplicate':
          // Duplicate functionality
            break;
          case 'open_pdf':
          // Open PDF functionality
            break;
          case 'print_pdf':
          // Print PDF functionality
            break;
          case 'save_pdf':
          // Save PDF functionality
            break;
          case 'share_pdf':
          // Share PDF functionality
            break;
          case 'cancel_invoice':
            Navigator.pop(context);
            break;
        }
      }
    });
  }

  void _showMyDetailsForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilesPage()
    );
  }

  void _showBuyerDetailsForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilesPage(),
    );
  }

  void _showProductDetailsForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilesPage(),
    );
  }

  void _showBankDetailsForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilesPage()
    );
  }

  void _calculateTotal() {
    double total = 0;
    for (var product in _invoice.products) {
      total += product.price * product.quantity;
    }
    setState(() {
      _invoice.total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Invoice',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Invoice Number Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(_invoice.date),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? picked =
                                  await showDatePicker(
                                    context: context,
                                    initialDate: _invoice.date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null &&
                                      picked != _invoice.date) {
                                    setState(() {
                                      _invoice.date = picked;
                                    });
                                  }
                                },
                                child: const Icon(Icons.calendar_today,
                                    size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice No.'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            initialValue: _invoice.invoiceNumber,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              _invoice.invoiceNumber = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // My Details Section
              Row(
                children: [
                  const Icon(Icons.business, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showMyDetailsForm,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
              if (_invoice.sellerDetails.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoice.sellerDetails.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_invoice.sellerDetails.address.isNotEmpty)
                        Text(_invoice.sellerDetails.address),
                      if (_invoice.sellerDetails.phone.isNotEmpty)
                        Text(_invoice.sellerDetails.phone),
                      if (_invoice.sellerDetails.email.isNotEmpty)
                        Text(_invoice.sellerDetails.email),
                    ],
                  ),
                ),

              const Divider(height: 32),

              // Buyer Details Section
              Row(
                children: [
                  const Icon(Icons.person, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Buyer Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showBuyerDetailsForm,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
              if (_invoice.buyerDetails.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoice.buyerDetails.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_invoice.buyerDetails.address.isNotEmpty)
                        Text(_invoice.buyerDetails.address),
                      if (_invoice.buyerDetails.phone.isNotEmpty)
                        Text(_invoice.buyerDetails.phone),
                      if (_invoice.buyerDetails.email.isNotEmpty)
                        Text(_invoice.buyerDetails.email),
                    ],
                  ),
                ),

              const Divider(height: 32),

              // Product Details Section
              Row(
                children: [
                  const Icon(Icons.shopping_bag, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showProductDetailsForm,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
              if (_invoice.products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: Column(
                    children: _invoice.products
                        .map(
                          (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(product.name),
                            ),
                            Expanded(
                              flex: 1,
                              child:
                              Text('${product.quantity.toString()} x'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                  '\$${product.price.toStringAsFixed(2)}'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '\$${(product.price * product.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              if (_invoice.products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '\$${_invoice.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 32),

              // Bank Details Section (Optional)
              Row(
                children: [
                  const Icon(Icons.account_balance, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Bank Details (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showBankDetailsForm,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
              if (_invoice.bankDetails.accountName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoice.bankDetails.bankName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('A/C: ${_invoice.bankDetails.accountNumber}'),
                      Text('IFSC: ${_invoice.bankDetails.ifscCode}'),
                      Text('A/C Name: ${_invoice.bankDetails.accountName}'),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Signature Section
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _invoice.signature.isEmpty
                      ? const Text('Tap to add Signature',
                      style: TextStyle(color: Colors.grey))
                      : Image.memory(
                    // Convert base64 to Uint8List for signature display
                    Uri.parse(_invoice.signature).data!.contentAsBytes(),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Bottom Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Invoice?'),
                            content: const Text(
                                'Are you sure you want to delete this invoice?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Go back to home
                                },
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
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