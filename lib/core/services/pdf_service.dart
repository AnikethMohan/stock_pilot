/// PDF generation service for sales documents.
library;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/core/utils/adaptive_layout.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';

class PdfService {
  PdfService._();

  /// Generates a PDF for any sales document type and returns the raw bytes.
  static Future<Uint8List> generateDocumentPdf(
    SalesDocument doc,
    NumberFormat currencyFormat,
  ) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final boldFont = pw.Font.ttf(boldData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );

    final dateStr = DateFormat(
      'MMM dd, yyyy',
    ).format(doc.createdAt ?? DateTime.now());

    // Document type header
    final docTitle = doc.docType.label.toUpperCase();
    final headerColor = switch (doc.docType) {
      DocType.quotation => PdfColors.orange900,
      DocType.deliveryNote => PdfColors.blue900,
      DocType.invoice => PdfColors.blue900,
    };

    final isDeliveryNote = doc.docType == DocType.deliveryNote;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      docTitle,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      doc.docNumber,
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Date: $dateStr',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    if (doc.sourceDocNumber != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Ref: ${doc.sourceDocNumber}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                    if (doc.deliveryDate != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Delivery Date: ${DateFormat('MMM dd, yyyy').format(doc.deliveryDate!)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Stock Pilot Inc.',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('123 Business Rd.'),
                    pw.Text('City, State 12345'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Customer
            if (doc.customer != null) ...[
              pw.Text(
                isDeliveryNote ? 'Deliver To:' : 'Bill To:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                doc.customer!.name,
                style: const pw.TextStyle(fontSize: 14),
              ),
              if (doc.customer!.phone.isNotEmpty) pw.Text(doc.customer!.phone),
              if (doc.customer!.email.isNotEmpty) pw.Text(doc.customer!.email),
              if (doc.customer!.address.isNotEmpty)
                pw.Text(doc.customer!.address),
            ],
            pw.SizedBox(height: 32),

            // Line Items Table
            _buildItemsTable(doc.items, currencyFormat, isDeliveryNote),
            pw.SizedBox(height: 24),

            // Summary Totals (skip for delivery notes)
            if (!isDeliveryNote)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Expanded(flex: 5, child: pw.SizedBox()),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryRow(
                          'Subtotal',
                          doc.subtotal,
                          currencyFormat,
                        ),
                        pw.SizedBox(height: 4),
                        if (doc.discountAmount > 0) ...[
                          _buildSummaryRow(
                            'Discount (${doc.discountPercent.toStringAsFixed(1)}%)',
                            -doc.discountAmount,
                            currencyFormat,
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        _buildSummaryRow('Tax', doc.taxAmount, currencyFormat),
                        pw.Divider(),
                        _buildSummaryRow(
                          'Grand Total',
                          doc.grandTotal,
                          currencyFormat,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            pw.SizedBox(height: 48),

            // Footer
            pw.Text(
              doc.notes.isNotEmpty ? doc.notes : 'Thank you for your business!',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildItemsTable(
    List<SalesDocItem> items,
    NumberFormat currencyFormat,
    bool isDeliveryNote,
  ) {
    if (isDeliveryNote) {
      return pw.TableHelper.fromTextArray(
        headers: ['Item', 'SKU', 'Qty'],
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        cellHeight: 30,
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerRight,
        },
        data: items.map((item) {
          return [
            item.productName,
            item.sku,
            item.quantity % 1 == 0
                ? item.quantity.toInt().toString()
                : item.quantity.toString(),
          ];
        }).toList(),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Item', 'Price', 'Qty', 'Disc %', 'Tax %', 'Total'],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      data: items.map((item) {
        return [
          item.productName,
          currencyFormat.format(item.unitPrice),
          item.quantity % 1 == 0
              ? item.quantity.toInt().toString()
              : item.quantity.toString(),
          item.discountPercent > 0
              ? '${item.discountPercent.toStringAsFixed(1)}%'
              : '-',
          item.taxPercent > 0 ? '${item.taxPercent.toStringAsFixed(1)}%' : '-',
          currencyFormat.format(item.lineTotal),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount,
    NumberFormat currencyFormat, {
    bool isBold = false,
  }) {
    final style = pw.TextStyle(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: isBold ? 14 : 12,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(currencyFormat.format(amount), style: style),
      ],
    );
  }

  /// Platform-aware save/share dialog for the PDF.
  static Future<void> saveOrSharePdf(
    SalesDocument doc,
    NumberFormat currencyFormat,
  ) async {
    try {
      final bytes = await generateDocumentPdf(doc, currencyFormat);
      final filename = '${doc.docNumber}.pdf';

      if (AdaptiveLayout.isDesktopOS) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save ${doc.docType.label} PDF',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (outputFile != null) {
          await File(outputFile).writeAsBytes(bytes);
        }
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (e) {
      throw CsvFailure('Failed to generate or save PDF: $e');
    }
  }
}
