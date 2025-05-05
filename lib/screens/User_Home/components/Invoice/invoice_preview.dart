import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get theme-specific colors
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);
    final iconColor = AppColors.getIconColor(isDarkMode);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invoice Preview',
          style: TextStyle(color: textColor),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(),
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: "invoice_${invoice.invoiceNo}.pdf",
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              context,
              'Print',
              Icons.print,
                  () => _printPdf(context),
              isDarkMode,
            ),
            _buildNavButton(
              context,
              'Share',
              Icons.share,
                  () => _shareInvoice(context),
              isDarkMode,
            ),
            _buildNavButton(
              context,
              'Download',
              Icons.download,
                  () => _downloadPdf(context),
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String label, IconData icon,
      VoidCallback onPressed, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: AppColors.primaryBlue,
          tooltip: label,
        ),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            fontSize: 12,
          ),
        ),
      ],
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

  Future<void> _printPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await _generatePdf(),
        name: 'Invoice ${invoice.invoiceNo}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing invoice: $e')),
        );
      }
    }
  }
}