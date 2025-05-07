import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'invoice_create.dart';
import 'invoice_model.dart';
import 'invoice_pdf.dart';
import 'invoice_preview.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoices = await _firebaseService.getInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading invoices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    try {
      await _firebaseService.deleteInvoice(invoiceId);
      setState(() {
        _invoices.removeWhere((invoice) => invoice.id == invoiceId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting invoice: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No invoices found',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create your first invoice by clicking the button below',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          final buyerName = invoice.buyerDetails['customerName'] ?? 'Customer';
          final date = invoice.date;

          // Calculate total amount
          final totalAmount = invoice.products.fold(
            0.0,
                (sum, item) => sum + item.product.calculateTotalAmount(item.quantity),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                // Change this navigation to InvoiceCreateScreen with the invoice data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceCreateScreen(
                      // Pass the existing invoice for editing
                      existingInvoice: invoice,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}.${buyerName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, size: 20),
                              onPressed: () async {
                                try {
                                  final pdfData = await InvoicePdfGenerator.generateInvoicePdf(invoice);
                                  final tempDir = await getTemporaryDirectory();
                                  final file = File('${tempDir.path}/invoice_${invoice.invoiceNo}.pdf');
                                  await file.writeAsBytes(pdfData);
                                  await Share.shareXFiles([XFile(file.path)]);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error sharing invoice: $e')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Invoice', style: TextStyle(color: isDarkMode ? AppColors.darkText : AppColors.lightText)),
                                    content: Text('Are you sure you want to delete this invoice?', style: TextStyle(color: isDarkMode ? AppColors.darkText : AppColors.lightText)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteInvoice(invoice.id);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/create_invoice');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'New Invoice',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}