import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'order_service.dart';

class PdfReceiptService {
  /// Generates a PDF invoice/receipt bytes for the given [OrderModel]
  static Future<Uint8List> generateReceiptPdf({
    required OrderModel order,
    Map<String, String>? distributorInfo,
    String? transactionId,
  }) async {
    final pdf = pw.Document();

    final companyName = distributorInfo?['companyName']?.isNotEmpty == true
        ? distributorInfo!['companyName']!
        : 'Bhargavi Milk Distributors';
    final distributorOwner = distributorInfo?['distributorName'] ?? '';
    final distributorPhone = distributorInfo?['mobile']?.isNotEmpty == true
        ? distributorInfo!['mobile']!
        : '9876543210';
    final distributorAddress = distributorInfo?['address']?.isNotEmpty == true
        ? distributorInfo!['address']!
        : '123, Dairy Road, Pune, Maharashtra';

    final orderDateStr = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)
        : DateFormat('dd MMM yyyy').format(DateTime.now());

    final invoiceNum = 'INV-${order.orderNumber.replaceAll('#', '')}';
    final isPaid = order.paymentStatus.toLowerCase() == 'paid';
    final txn = transactionId ??
        'TXN${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (distributorOwner.isNotEmpty)
                        pw.Text(
                          'Prop: $distributorOwner',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      pw.Text(
                        distributorAddress,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Phone: $distributorPhone',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'GSTIN: 27AABCB1234F1Z5',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: isPaid ? PdfColors.green50 : PdfColors.amber50,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(
                            color: isPaid ? PdfColors.green700 : PdfColors.amber700,
                            width: 1,
                          ),
                        ),
                        child: pw.Text(
                          isPaid ? 'TAX INVOICE / RECEIPT' : 'PENDING INVOICE',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: isPaid ? PdfColors.green800 : PdfColors.amber800,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Invoice No: $invoiceNum',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Order No: ${order.orderNumber}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Date: $orderDateStr',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.blue800, thickness: 1.5),
              pw.SizedBox(height: 12),

              // ── Bill To & Delivery ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO (SHOP):',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          order.shopName.isNotEmpty ? order.shopName : 'Customer Shop',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        if (order.shopOwner.isNotEmpty)
                          pw.Text(
                            'Owner: ${order.shopOwner}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                        if (order.shopMobile.isNotEmpty)
                          pw.Text(
                            'Mobile: ${order.shopMobile}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                        if (order.deliveryAddress.isNotEmpty)
                          pw.Text(
                            'Address: ${order.deliveryAddress}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DELIVERY DETAILS:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Slot: ${order.deliveryDate} (${order.deliveryTime})',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          'Payment Method: ${order.paymentMethod.toUpperCase()}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          'Payment Status: ${order.paymentStatus.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: isPaid ? PdfColors.green700 : PdfColors.red700,
                          ),
                        ),
                        if (isPaid)
                          pw.Text(
                            'Transaction Ref: $txn',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 18),

              // ── Items Table ──
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4), // Item
                  1: const pw.FlexColumnWidth(2), // Pack
                  2: const pw.FlexColumnWidth(1.5), // Qty
                  3: const pw.FlexColumnWidth(2), // Rate
                  4: const pw.FlexColumnWidth(2.5), // Amount
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _th('Item Description'),
                      _th('Pack / Unit', align: pw.TextAlign.center),
                      _th('Qty', align: pw.TextAlign.center),
                      _th('Rate (Rs)', align: pw.TextAlign.right),
                      _th('Amount (Rs)', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  if (order.items.isNotEmpty)
                    ...order.items.map((item) {
                      return pw.TableRow(
                        children: [
                          _td(item.productName),
                          _td('${item.packSize} ${item.unit}'.trim(), align: pw.TextAlign.center),
                          _td('${item.quantity}', align: pw.TextAlign.center),
                          _td(item.price.toStringAsFixed(2), align: pw.TextAlign.right),
                          _td((item.quantity * item.price).toStringAsFixed(2),
                              align: pw.TextAlign.right),
                        ],
                      );
                    })
                  else
                    ...order.products.map((p) {
                      return pw.TableRow(
                        children: [
                          _td(p),
                          _td('-', align: pw.TextAlign.center),
                          _td('1', align: pw.TextAlign.center),
                          _td(order.totalAmount.toStringAsFixed(2), align: pw.TextAlign.right),
                          _td(order.totalAmount.toStringAsFixed(2), align: pw.TextAlign.right),
                        ],
                      );
                    }),
                ],
              ),

              pw.SizedBox(height: 12),

              // ── Summary Calculation ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Terms & Conditions:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '1. Goods once sold will not be returned unless damaged upon delivery.\n'
                            '2. Keep milk and milk products refrigerated at 4°C or below.\n'
                            '3. For inquiries or payment settlement, contact your distributor.',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      children: [
                        _summaryPdfRow('Subtotal:', 'Rs ${order.subtotal.toStringAsFixed(2)}'),
                        if (order.deliveryCharge > 0)
                          _summaryPdfRow(
                            'Delivery Charge:',
                            'Rs ${order.deliveryCharge.toStringAsFixed(2)}',
                          ),
                        if (order.discount > 0)
                          _summaryPdfRow(
                            'Discount:',
                            '- Rs ${order.discount.toStringAsFixed(2)}',
                          ),
                        pw.Divider(color: PdfColors.grey400),
                        _summaryPdfRow(
                          'Grand Total:',
                          'Rs ${order.total.toStringAsFixed(2)}',
                          bold: true,
                        ),
                        pw.SizedBox(height: 4),
                        _summaryPdfRow(
                          'Amount Paid:',
                          isPaid ? 'Rs ${order.total.toStringAsFixed(2)}' : 'Rs 0.00',
                          bold: isPaid,
                          color: isPaid ? PdfColors.green800 : PdfColors.grey800,
                        ),
                        _summaryPdfRow(
                          'Balance Due:',
                          isPaid ? 'Rs 0.00' : 'Rs ${order.total.toStringAsFixed(2)}',
                          bold: !isPaid,
                          color: isPaid ? PdfColors.green800 : PdfColors.red800,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ── Footer ──
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is a computer-generated tax invoice. No signature required.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'MilkRoute © ${DateTime.now().year} • Bhargavi Milk',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryPdfRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens an interactive PDF preview modal dialog or screen
  static Future<void> previewReceipt({
    required BuildContext context,
    required OrderModel order,
    Map<String, String>? distributorInfo,
    String? transactionId,
  }) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Invoice ${order.orderNumber}'),
            backgroundColor: const Color(0xFF0047FF),
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) => generateReceiptPdf(
              order: order,
              distributorInfo: distributorInfo,
              transactionId: transactionId,
            ),
            canChangePageFormat: false,
            canChangeOrientation: false,
            pdfFileName: 'Invoice_${order.orderNumber.replaceAll('#', '')}.pdf',
          ),
        ),
      ),
    );
  }

  /// Direct print receipt
  static Future<void> printReceipt({
    required OrderModel order,
    Map<String, String>? distributorInfo,
    String? transactionId,
  }) async {
    final pdfData = await generateReceiptPdf(
      order: order,
      distributorInfo: distributorInfo,
      transactionId: transactionId,
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdfData,
      name: 'Invoice_${order.orderNumber.replaceAll('#', '')}',
    );
  }

  /// Direct share receipt via OS share dialog
  static Future<void> shareReceipt({
    required OrderModel order,
    Map<String, String>? distributorInfo,
    String? transactionId,
  }) async {
    final pdfData = await generateReceiptPdf(
      order: order,
      distributorInfo: distributorInfo,
      transactionId: transactionId,
    );
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Invoice_${order.orderNumber.replaceAll('#', '')}.pdf',
    );
  }
}
