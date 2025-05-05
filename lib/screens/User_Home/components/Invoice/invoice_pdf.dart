import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'invoice_model.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return _buildInvoiceContent(invoice);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInvoiceContent(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Header with full details
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  invoice.myDetails['companyName'] ?? 'My Company',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (invoice.myDetails['address'] != null)
                pw.Center(
                  child: pw.Text(invoice.myDetails['address']),
                ),
              if (invoice.myDetails['city'] != null ||
                  invoice.myDetails['state'] != null ||
                  invoice.myDetails['pincode'] != null)
                pw.Center(
                  child: pw.Text(
                    '${invoice.myDetails['city'] ?? ''}, ${invoice.myDetails['state'] ?? ''} ${invoice.myDetails['pincode'] ?? ''}'
                        .trim(),
                  ),
                ),
              if (invoice.myDetails['gstNumber'] != null)
                pw.Center(
                  child: pw.Text('GSTIN: ${invoice.myDetails['gstNumber']}'),
                ),
              if (invoice.myDetails['mobileNumber'] != null)
                pw.Center(
                  child:
                      pw.Text('Mobile: ${invoice.myDetails['mobileNumber']}'),
                ),
              if (invoice.myDetails['email'] != null)
                pw.Center(
                  child: pw.Text('Email: ${invoice.myDetails['email']}'),
                ),
            ],
          ),
        ),

        // Tax Invoice Title
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Stack(
            children: [
              pw.Center(
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Invoice Details
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Invoice Number', invoice.invoiceNo),
                    _buildDetailRow('Invoice Date', invoice.date),
                    _buildDetailRow('Reverse Charge', 'NO'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Date Of Supply', invoice.date),
                    _buildDetailRow('Vehicle Number', invoice.date),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Billed To and Shipped To
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  decoration: const pw.BoxDecoration(
                    border:
                        pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        color: PdfColors.blue100,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Details of Receiver | Billed to',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                'Name: ${invoice.buyerDetails['customerName'] ?? ''}'),
                            pw.Text(
                                'Address: ${invoice.buyerDetails['address'] ?? ''}'),
                            pw.Text(
                                '${invoice.buyerDetails['city'] ?? ''}, ${invoice.buyerDetails['state'] ?? ''}, ${invoice.buyerDetails['pincode'] ?? ''}'),
                            pw.Text(
                                'GSTIN: ${invoice.buyerDetails['gstNumber'] ?? ''}'),
                            pw.Text(
                                'State: ${invoice.buyerDetails['state'] ?? ''}'),
                            pw.Text(
                                'State Code : ${_getStateCode(invoice.buyerDetails['state'] ?? '')}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        color: PdfColors.blue100,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Details of Consignee | Shipped to',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                'Name: ${invoice.buyerDetails['customerName'] ?? ''}'),
                            pw.Text(
                                'Address: ${invoice.buyerDetails['address'] ?? ''}'),
                            pw.Text(
                                '${invoice.buyerDetails['city'] ?? ''}, ${invoice.buyerDetails['state'] ?? ''}, ${invoice.buyerDetails['pincode'] ?? ''}'),
                            pw.Text(
                                'GSTIN: ${invoice.buyerDetails['gstNumber'] ?? ''}'),
                            pw.Text(
                                'State: ${invoice.buyerDetails['state'] ?? ''}'),
                            pw.Text(
                                'State Code : ${_getStateCode(invoice.buyerDetails['state'] ?? '')}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        // Products Table - Simplified structure
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: {
            0: const pw.FixedColumnWidth(30), // Sr. No.
            1: const pw.FixedColumnWidth(120), // Name of Product
            2: const pw.FixedColumnWidth(30), // QTY
            3: const pw.FixedColumnWidth(40), // Unit
            4: const pw.FixedColumnWidth(50), // Rate
            5: const pw.FixedColumnWidth(70), // Taxable Value
            6: const pw.FixedColumnWidth(70), // CGST
            7: const pw.FixedColumnWidth(70), // SGST
            8: const pw.FixedColumnWidth(60), // Total
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                _buildTableHeaderCell('Sr. No.'),
                _buildTableHeaderCell('Name of Product'),
                _buildTableHeaderCell('QTY'),
                _buildTableHeaderCell('Unit'),
                _buildTableHeaderCell('Rate'),
                _buildTableHeaderCell('Taxable Value'),
                _buildTableHeaderCell('CGST\nRate  |   Amt'),
                _buildTableHeaderCell('SGST\nRate  |   Amt'),
                _buildTableHeaderCell('Total'),
              ],
            ),
            // Product rows
            ...invoice.products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildProductRow(index + 1, product);
            }).toList(),
            // Add empty rows to fill up space if needed
            ...List.generate(
              5 - invoice.products.length > 0 ? 5 - invoice.products.length : 0,
              (index) => _buildEmptyProductRow(),
            ),
          ],
        ),

        // Totals row
        pw.SizedBox(height: 2),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: {
            0: const pw.FlexColumnWidth(1), // Sr. No.
            1: const pw.FlexColumnWidth(3), // Name of Product
            2: const pw.FlexColumnWidth(1), // QTY
            3: const pw.FlexColumnWidth(1), // Unit
            4: const pw.FlexColumnWidth(1), // Rate
            5: const pw.FlexColumnWidth(2), // Taxable Value
            6: const pw.FlexColumnWidth(2), // CGST
            7: const pw.FlexColumnWidth(2), // SGST
            8: const pw.FlexColumnWidth(2), // Total
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                pw.Container(), // Empty cell
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Total Quantity'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _getTotalQuantity(invoice).toString(),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(), // Empty cell
                pw.Container(), // Empty cell
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Rs. ${_getTotalTaxableValue(invoice).toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Rs. ${_getTotalCGST(invoice).toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Rs. ${_getTotalSGST(invoice).toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Rs. ${_getTotalAmount(invoice).toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Total in words section
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Total Invoice Amount in words',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(_convertNumberToWords(_getTotalAmount(invoice))),
            ],
          ),
        ),

        // Amount summary table
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Total Amount Before Tax'),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                        'Rs. ${_getTotalTaxableValue(invoice).toStringAsFixed(2)}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Add : CGST'),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                        'Rs. ${_getTotalCGST(invoice).toStringAsFixed(2)}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Add : SGST'),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                        'Rs. ${_getTotalSGST(invoice).toStringAsFixed(2)}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Tax Amount: GST'),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                        'Rs. ${(_getTotalCGST(invoice) + _getTotalSGST(invoice)).toStringAsFixed(2)}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('TOTAL Amount With Tax',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Rs. ${_getTotalAmount(invoice).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              // pw.TableRow(
              //   children: [
              //     pw.Container(
              //       padding: const pw.EdgeInsets.all(5),
              //       child: pw.Text('Final Invoice Amount'),
              //     ),
              //     pw.Container(
              //       padding: const pw.EdgeInsets.all(5),
              //       alignment: pw.Alignment.centerRight,
              //       child: pw.Text('₹ ${_getTotalAmount(invoice).toStringAsFixed(2)}'),
              //     ),
              //   ],
              // ),
              // pw.TableRow(
              //   children: [
              //     pw.Container(
              //       padding: const pw.EdgeInsets.all(5),
              //       child: pw.Text('Balance Due'),
              //     ),
              //     pw.Container(
              //       padding: const pw.EdgeInsets.all(5),
              //       alignment: pw.Alignment.centerRight,
              //       child: pw.Text('₹ ${_getTotalAmount(invoice).toStringAsFixed(2)}'),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),

        // Footer section with terms and signature
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Terms and Conditions
            pw.Expanded(
              child: pw.Container(
                height: 100,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Terms And Conditions',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                        '1. This is an electronically generated document.\n2. All disputes are subject to seller city jurisdiction.'),
                  ],
                ),
              ),
            ),
            // Signature section
            pw.Expanded(
              child: pw.Container(
                height: 100,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Certified that the particulars given above are true and correct',
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'For, ${invoice.myDetails['companyName'] ?? 'My Company'}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      'Authorised Signatory',
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Footer additional info
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'Thanks for your business',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTaxHeaderCell(String title) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                  ),
                  child: pw.Text(
                    'Rate',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    'Amount',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildProductRow(int index, InvoiceProductItem item) {
    final product = item.product;
    final quantity = item.quantity;

    print(
        'Debug: Product ${product.name}, Quantity: $quantity'); // Add debug logging

    // Calculate based on actual quantity
    final taxableValue = product.priceExcludingGst * quantity;
    final cgstAmount = product.calculateCgstAmount(quantity);
    final sgstAmount = product.calculateSgstAmount(quantity);
    final totalAmount = product.calculateTotalAmount(quantity);

    final cgstRate = product.gstRate / 2;
    final sgstRate = product.gstRate / 2;

    return pw.TableRow(
      children: [
        _buildTableCell(index.toString()),
        _buildTableCell(product.name),
        _buildTableCell(quantity.toString()),
        _buildTableCell(product.unit.isEmpty ? 'NOS' : product.unit),
        _buildTableCell('Rs. ${product.salePrice.toStringAsFixed(2)}'),
        _buildTableCell('Rs. ${taxableValue.toStringAsFixed(2)}'),
        _buildTableCell(
            '${cgstRate.toStringAsFixed(1)}%\nRs. ${cgstAmount.toStringAsFixed(2)}'),
        _buildTableCell(
            '${sgstRate.toStringAsFixed(1)}%\nRs. ${sgstAmount.toStringAsFixed(2)}'),
        _buildTableCell('Rs. ${totalAmount.toStringAsFixed(2)}'),
      ],
    );
  }

// Update total calculations to use actual quantities
  static double _getTotalQuantity(InvoiceModel invoice) {
    return invoice.products.fold(0.0, (sum, item) => sum + item.quantity);
  }

  static double _getTotalTaxableValue(InvoiceModel invoice) {
    return invoice.products.fold(0.0,
        (sum, item) => sum + (item.product.priceExcludingGst * item.quantity));
  }

  static double _getTotalCGST(InvoiceModel invoice) {
    return invoice.products.fold(0.0,
        (sum, item) => sum + item.product.calculateCgstAmount(item.quantity));
  }

  static double _getTotalSGST(InvoiceModel invoice) {
    return invoice.products.fold(0.0,
        (sum, item) => sum + item.product.calculateSgstAmount(item.quantity));
  }

  static double _getTotalAmount(InvoiceModel invoice) {
    return invoice.products.fold(0.0,
        (sum, item) => sum + item.product.calculateTotalAmount(item.quantity));
  }

  static pw.TableRow _buildEmptyProductRow() {
    return pw.TableRow(
      children: List.generate(9, (index) => _buildTableCell('')),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static String _convertNumberToWords(double number) {
    return NumberToWords.convertToIndianWords(number);
  }

  static String _getStateCode(String state) {
    final stateCodes = {
      'Delhi': '07',
      'Maharashtra': '27',
      'Karnataka': '29',
      'Tamil Nadu': '33',
      'Gujarat': '24',
      'Rajasthan': '08',
      'Uttar Pradesh': '09',
      'West Bengal': '19',
      'Telangana': '36',
      'Andhra Pradesh': '37',
      'Chhattisgarh': '22',
      // Add more states as needed
    };
    return stateCodes[state] ?? '00';
  }

  // Helper methods for saving and sharing PDF
  static Future<void> savePdfToFile(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoice_${invoice.invoiceNo}.pdf');
    await file.writeAsBytes(pdf);
  }

  static Future<void> printPdf(InvoiceModel invoice) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async =>
          await generateInvoicePdf(invoice),
    );
  }
}

class NumberToWords {
  static final List<String> units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static final List<String> tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String convertToIndianWords(double amount) {
    if (amount == 0) return 'Zero Rupees Only';

    String result = '';
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    // Convert rupees
    if (rupees > 0) {
      result = _convertToWords(rupees) + ' Rupees';
    }

    // Convert paise
    if (paise > 0) {
      if (result.isNotEmpty) result += ' and ';
      result += _convertToWords(paise) + ' Paise';
    }

    return result + ' Only';
  }

  static String _convertToWords(int number) {
    if (number == 0) return '';

    if (number < 20) return units[number];

    if (number < 100) {
      return tens[number ~/ 10] +
          (number % 10 != 0 ? ' ' + units[number % 10] : '');
    }

    if (number < 1000) {
      return units[number ~/ 100] +
          ' Hundred' +
          (number % 100 != 0 ? ' and ' + _convertToWords(number % 100) : '');
    }

    if (number < 100000) {
      // Less than 1 lakh
      return _convertToWords(number ~/ 1000) +
          ' Thousand' +
          (number % 1000 != 0 ? ' ' + _convertToWords(number % 1000) : '');
    }

    if (number < 10000000) {
      // Less than 1 crore
      return _convertToWords(number ~/ 100000) +
          ' Lakh' +
          (number % 100000 != 0 ? ' ' + _convertToWords(number % 100000) : '');
    }

    return _convertToWords(number ~/ 10000000) +
        ' Crore' +
        (number % 10000000 != 0
            ? ' ' + _convertToWords(number % 10000000)
            : '');
  }
}
