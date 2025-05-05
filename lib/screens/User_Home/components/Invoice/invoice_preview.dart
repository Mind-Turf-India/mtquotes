import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'invoice_model.dart';
import 'invoice_pdf.dart';

class PdfPreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const PdfPreviewScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invoice Preview',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () => _shareInvoice(context),
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.black),
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(),
        // actions: [
        //   PdfPreviewAction(
        //     icon: Icon(Icons.save),
        //     onPressed: (context, build, pageFormat) => _downloadPdf(context),
        //   ),
        // ],
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: "invoice_${invoice.invoiceNo}.pdf",
      ),
    );
  }

  Future<Uint8List> _generatePdf() async {
    return await InvoicePdfGenerator.generateInvoicePdf(invoice);
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_${invoice.invoiceNo}.pdf');
      await file.writeAsBytes(pdf);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_${invoice.invoiceNo}.pdf');
      await file.writeAsBytes(pdf);

      await Share.shareXFiles([XFile(file.path)], text: 'Invoice ${invoice.invoiceNo}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    }
  }
}