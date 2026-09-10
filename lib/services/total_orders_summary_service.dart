import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'order_service.dart';

/// Represents aggregated summary data for a specific product variant and pack size
class ProductVariantSummary {
  final String brandName;
  final String productName;
  final String variantName;
  final String packSize;
  final String unit;
  final double unitPrice;
  int totalQuantity;
  double totalRupees;
  int orderCount;

  ProductVariantSummary({
    required this.brandName,
    required this.productName,
    required this.variantName,
    required this.packSize,
    required this.unit,
    required this.unitPrice,
    this.totalQuantity = 0,
    this.totalRupees = 0.0,
    this.orderCount = 0,
  });
}

/// Represents aggregated summary for a brand
class BrandSummary {
  final String brandName;
  final Map<String, ProductVariantSummary> variants;

  int totalQuantity;
  double totalRupees;
  int orderCount;

  BrandSummary({
    required this.brandName,
    Map<String, ProductVariantSummary>? variants,
    this.totalQuantity = 0,
    this.totalRupees = 0.0,
    this.orderCount = 0,
  }) : variants = variants ?? {};

  List<ProductVariantSummary> get variantList {
    final list = variants.values.toList();

    // Sort by quantity descending
    list.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    return list;
  }
}

/// Represents individual customer/shop order item for the checklist & report
class CustomerOrderItemSummary {
  final String productName;
  final String packSize;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;

  CustomerOrderItemSummary({
    required this.productName,
    required this.packSize,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
  });
}

/// Represents individual customer/shop order in today's delivery checklist
class CustomerOrderSummary {
  final String orderId;
  final String orderNumber;
  final String shopId;
  final String shopName;
  final String shopOwner;
  final String shopMobile;
  final String deliveryAddress;
  final String deliveryTime;
  final List<CustomerOrderItemSummary> items;
  final int totalQuantity;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? createdAt;
  bool isChecked;

  CustomerOrderSummary({
    required this.orderId,
    required this.orderNumber,
    required this.shopId,
    required this.shopName,
    required this.shopOwner,
    required this.shopMobile,
    required this.deliveryAddress,
    required this.deliveryTime,
    required this.items,
    required this.totalQuantity,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.createdAt,
    this.isChecked = false,
  });

  String get itemsSummaryText {
    if (items.isEmpty) return 'No items';
    return items.map((i) => '${i.productName} (${i.packSize}) × ${i.quantity}').join(', ');
  }
}

/// Complete report summary containing all brands, customer checklist and overall totals
class TotalOrdersReportData {
  final List<OrderModel> orders;
  final List<BrandSummary> brandSummaries;
  final List<CustomerOrderSummary> customerSummaries;
  final int totalOrdersCount;
  final int grandTotalQuantity;
  final double grandTotalRupees;
  final String dateFilterName;
  final String statusFilter;
  final DateTime generatedAt;

  TotalOrdersReportData({
    required this.orders,
    required this.brandSummaries,
    required this.customerSummaries,
    required this.totalOrdersCount,
    required this.grandTotalQuantity,
    required this.grandTotalRupees,
    required this.dateFilterName,
    required this.statusFilter,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

/// Helper for extracting brand, variant, and pack size from product strings
class BrandParser {
  static const List<String> knownBrands = [
    'Amul',
    'Gokul',
    'Bhargavi',
    'Mother Dairy',
    'Nandini',
    'Warana',
    'Heritage',
    'Verka',
    'Milma',
    'Gowardhan',
    'Aavin',
    'Vijaya',
    'Saras',
    'Mahananda',
    'Dynamix',
    'Britannia',
    'Nestle',
    'Prabhat',
    'Katraj',
    'Chitale',
    'Govind',
    'Rajhans',
    'Shreeja',
    'Sudha',
  ];

  /// Parses product name, packSize and category
  /// into (Brand, Variant/Item, PackSize)
  static (String brand, String variant, String size) parse(
    String rawName,
    String defaultPackSize,
    String category,
  ) {
    var name = rawName.trim();

    if (name.isEmpty) {
      return (
        'Other',
        'Product',
        defaultPackSize.isNotEmpty ? defaultPackSize : '500ml',
      );
    }

    // Extract size from name
    final sizeRegex = RegExp(
      r'(\d+(?:\.\d+)?\s*(?:ml|l|ltr|g|kg|gm|pcs|pkt|packet|pouch))\b',
      caseSensitive: false,
    );

    final sizeMatch = sizeRegex.firstMatch(name);

    String detectedSize = defaultPackSize.trim();

    if (sizeMatch != null) {
      detectedSize = sizeMatch.group(1)!.trim();
    }

    if (detectedSize.isEmpty) {
      detectedSize = '500ml';
    }

    // ---------------------------------------------------------
    // 1. Check known brand prefix
    // ---------------------------------------------------------

    for (final b in knownBrands) {
      if (name.toLowerCase().startsWith(b.toLowerCase())) {
        String variant = name.substring(b.length).trim();

        if (sizeMatch != null) {
          variant = variant.replaceAll(sizeMatch.group(0)!, '').trim();
        }

        variant = variant.replaceAll(RegExp(r'^[-–—\s]+|[-–—\s]+$'), '').trim();

        if (variant.isEmpty) {
          variant = category.isNotEmpty ? category : 'Milk';
        }

        return (b, variant, detectedSize);
      }
    }

    // ---------------------------------------------------------
    // 2. Check if brand exists inside the name
    // ---------------------------------------------------------

    for (final b in knownBrands) {
      final wordRegex = RegExp(
        '\\b${RegExp.escape(b)}\\b',
        caseSensitive: false,
      );

      if (wordRegex.hasMatch(name)) {
        String variant = name.replaceAll(wordRegex, '').trim();

        if (sizeMatch != null) {
          variant = variant.replaceAll(sizeMatch.group(0)!, '').trim();
        }

        variant = variant.replaceAll(RegExp(r'^[-–—\s]+|[-–—\s]+$'), '').trim();

        if (variant.isEmpty) {
          variant = category.isNotEmpty ? category : 'Dairy';
        }

        return (b, variant, detectedSize);
      }
    }

    // ---------------------------------------------------------
    // 3. Fallback based on first word
    // ---------------------------------------------------------

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      final first = parts.first;

      const genericWords = {
        'fresh',
        'pure',
        'cow',
        'buffalo',
        'toned',
        'double',
        'full',
        'cream',
        'pasteurized',
        'organic',
        'standard',
      };

      if (!genericWords.contains(first.toLowerCase())) {
        final brand = first[0].toUpperCase() + first.substring(1);

        var variant = parts.sublist(1).join(' ').trim();

        if (sizeMatch != null) {
          variant = variant.replaceAll(sizeMatch.group(0)!, '').trim();
        }

        return (brand, variant.isEmpty ? name : variant, detectedSize);
      }
    }

    // ---------------------------------------------------------
    // 4. Final fallback
    // ---------------------------------------------------------

    final fallbackBrand = category.isNotEmpty ? category : 'General Dairy';

    var variant = name;

    if (sizeMatch != null) {
      variant = variant.replaceAll(sizeMatch.group(0)!, '').trim();
    }

    return (fallbackBrand, variant.isEmpty ? name : variant, detectedSize);
  }
}

/// Service to calculate summary and generate PDF report
class TotalOrdersSummaryService {
  // ===========================================================
  // PROCESS ORDERS
  // ===========================================================

  static TotalOrdersReportData processOrders({
    required List<OrderModel> orders,
    required String dateFilterName,
    required String statusFilter,
  }) {
    final Map<String, BrandSummary> brandMap = {};

    int grandTotalQty = 0;
    double grandTotalRupees = 0.0;

    for (final order in orders) {
      // -------------------------------------------------------
      // Modern item-based orders
      // -------------------------------------------------------

      if (order.items.isNotEmpty) {
        for (final item in order.items) {
          final parsed = BrandParser.parse(
            item.productName,
            item.packSize,
            item.category,
          );

          final brandName = parsed.$1;
          final variantName = parsed.$2;
          final packSize = parsed.$3;

          final brand = brandMap.putIfAbsent(
            brandName,
            () => BrandSummary(brandName: brandName),
          );

          final itemKey =
              '${item.productName.trim().toLowerCase()}_${packSize.toLowerCase()}';

          final variant = brand.variants.putIfAbsent(
            itemKey,
            () => ProductVariantSummary(
              brandName: brandName,
              productName: item.productName.trim(),
              variantName: variantName,
              packSize: packSize,
              unit: item.unit.isNotEmpty ? item.unit : 'Pkt',
              unitPrice: item.price,
            ),
          );

          variant.totalQuantity += item.quantity;
          variant.totalRupees += item.subtotal;
          variant.orderCount += 1;

          brand.totalQuantity += item.quantity;
          brand.totalRupees += item.subtotal;
          brand.orderCount += 1;

          grandTotalQty += item.quantity;
          grandTotalRupees += item.subtotal;
        }
      }
      // -------------------------------------------------------
      // Legacy string-based products
      // -------------------------------------------------------
      else if (order.products.isNotEmpty) {
        for (final prodStr in order.products) {
          final parsed = _parseLegacyProductString(prodStr);

          final brandName = parsed.brand;
          final prodName = parsed.name;
          final packSize = parsed.size;
          final qty = parsed.quantity;

          final price = order.totalAmount > 0 && order.totalQuantity > 0
              ? (order.totalAmount / order.totalQuantity)
              : 30.0;

          final subtotal = price * qty;

          final brand = brandMap.putIfAbsent(
            brandName,
            () => BrandSummary(brandName: brandName),
          );

          final itemKey =
              '${prodName.trim().toLowerCase()}_${packSize.toLowerCase()}';

          final variant = brand.variants.putIfAbsent(
            itemKey,
            () => ProductVariantSummary(
              brandName: brandName,
              productName: prodName,
              variantName: prodName,
              packSize: packSize,
              unit: 'Pkt',
              unitPrice: price,
            ),
          );

          variant.totalQuantity += qty;
          variant.totalRupees += subtotal;
          variant.orderCount += 1;

          brand.totalQuantity += qty;
          brand.totalRupees += subtotal;
          brand.orderCount += 1;

          grandTotalQty += qty;
          grandTotalRupees += subtotal;
        }
      }
    }

    // ---------------------------------------------------------
    // Build Customer-Wise Summaries
    // ---------------------------------------------------------
    final List<CustomerOrderSummary> customerList = [];

    for (final order in orders) {
      final List<CustomerOrderItemSummary> customerItems = [];

      if (order.items.isNotEmpty) {
        for (final item in order.items) {
          customerItems.add(
            CustomerOrderItemSummary(
              productName: item.productName,
              packSize: item.packSize.isNotEmpty ? item.packSize : '500ml',
              quantity: item.quantity,
              unit: item.unit.isNotEmpty ? item.unit : 'Pkt',
              unitPrice: item.price,
              subtotal: item.subtotal,
            ),
          );
        }
      } else if (order.products.isNotEmpty) {
        for (final prodStr in order.products) {
          final parsed = _parseLegacyProductString(prodStr);
          final price = order.totalAmount > 0 && order.totalQuantity > 0
              ? (order.totalAmount / order.totalQuantity)
              : 30.0;
          customerItems.add(
            CustomerOrderItemSummary(
              productName: parsed.name,
              packSize: parsed.size,
              quantity: parsed.quantity,
              unit: 'Pkt',
              unitPrice: price,
              subtotal: price * parsed.quantity,
            ),
          );
        }
      }

      final int totalQty = order.totalQuantity > 0
          ? order.totalQuantity
          : customerItems.fold(0, (sum, i) => sum + i.quantity);

      customerList.add(
        CustomerOrderSummary(
          orderId: order.id,
          orderNumber: order.orderNumber,
          shopId: order.shopId,
          shopName: order.shopName.isNotEmpty
              ? order.shopName
              : (order.shopOwner.isNotEmpty
                  ? order.shopOwner
                  : 'Customer #${order.orderNumber}'),
          shopOwner: order.shopOwner,
          shopMobile: order.shopMobile,
          deliveryAddress: order.deliveryAddress,
          deliveryTime: order.deliveryTime,
          items: customerItems,
          totalQuantity: totalQty,
          totalAmount: order.totalAmount,
          status: order.status,
          paymentStatus: order.paymentStatus,
          paymentMethod: order.paymentMethod,
          createdAt: order.createdAt,
          isChecked: order.status == 'delivered' || order.status == 'completed',
        ),
      );
    }

    // Sort brands by revenue descending
    final brandList = brandMap.values.toList();

    brandList.sort((a, b) => b.totalRupees.compareTo(a.totalRupees));

    return TotalOrdersReportData(
      orders: orders,
      brandSummaries: brandList,
      customerSummaries: customerList,
      totalOrdersCount: orders.length,
      grandTotalQuantity: grandTotalQty,
      grandTotalRupees: grandTotalRupees,
      dateFilterName: dateFilterName,
      statusFilter: statusFilter,
    );
  }

  // ===========================================================
  // LEGACY PRODUCT PARSER
  // ===========================================================

  static ({String brand, String name, String size, int quantity})
  _parseLegacyProductString(String prodStr) {
    // Examples:
    // Amul Taaza (500ml) × 10
    // Gokul Cow Milk 1L x 5
    // Cow Milk × 2

    var clean = prodStr.trim();

    int qty = 1;

    final qtyMatch = RegExp(r'[×xX*]\s*(\d+)').firstMatch(clean);

    if (qtyMatch != null) {
      qty = int.tryParse(qtyMatch.group(1)!) ?? 1;

      clean = clean.substring(0, qtyMatch.start).trim();
    }

    final parsed = BrandParser.parse(clean, '500ml', 'Milk');

    return (brand: parsed.$1, name: clean, size: parsed.$3, quantity: qty);
  }

  // ===========================================================
  // LOAD PDF FONTS
  // ===========================================================

  static Future<
    ({
      pw.Font? regular,
      pw.Font? bold,
      pw.Font? devanagariRegular,
      pw.Font? devanagariBold,
    })
  >
  _loadFonts() async {
    pw.Font? notoRegular;
    pw.Font? notoBold;

    pw.Font? devanagariRegular;
    pw.Font? devanagariBold;

    // ---------------------------------------------------------
    // Load normal Noto Sans
    // ---------------------------------------------------------

    try {
      final regularData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );

      notoRegular = pw.Font.ttf(regularData);

      debugPrint('PDF: NotoSans-Regular loaded successfully');
    } catch (e) {
      debugPrint('PDF: NotoSans-Regular not found: $e');
    }

    try {
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

      notoBold = pw.Font.ttf(boldData);

      debugPrint('PDF: NotoSans-Bold loaded successfully');
    } catch (e) {
      debugPrint('PDF: NotoSans-Bold not found: $e');
    }

    // ---------------------------------------------------------
    // Load Devanagari fonts
    // ---------------------------------------------------------

    try {
      final regularData = await rootBundle.load(
        'assets/fonts/NotoSansDevanagari-Regular.ttf',
      );

      devanagariRegular = pw.Font.ttf(regularData);

      debugPrint('PDF: NotoSansDevanagari-Regular loaded successfully');
    } catch (e) {
      debugPrint('PDF: NotoSansDevanagari-Regular not found: $e');
    }

    try {
      final boldData = await rootBundle.load(
        'assets/fonts/NotoSansDevanagari-Bold.ttf',
      );

      devanagariBold = pw.Font.ttf(boldData);

      debugPrint('PDF: NotoSansDevanagari-Bold loaded successfully');
    } catch (e) {
      debugPrint('PDF: NotoSansDevanagari-Bold not found: $e');
    }

    return (
      regular: notoRegular,
      bold: notoBold,
      devanagariRegular: devanagariRegular,
      devanagariBold: devanagariBold,
    );
  }

  // ===========================================================
  // GENERATE PDF
  // ===========================================================

  static Future<Uint8List> generatePdfBytes({
    required TotalOrdersReportData report,
    required String distributorCompanyName,
    String distributorOwnerName = '',
    String distributorMobile = '',
    String distributorAddress = '',
  }) async {
    final pdf = pw.Document(
      title: 'Today Orders & Delivery Checklist Summary',
      author: 'MilkRoute Distribution System',
    );

    final numberFormat = NumberFormat('#,##,##0.00', 'en_IN');

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // =========================================================
    // COLORS
    // =========================================================

    final primaryColor = PdfColor.fromHex('1660A6');

    final secondaryColor = PdfColor.fromHex('0F3D66');

    final accentGreen = PdfColor.fromHex('1F8A4C');

    final lightBg = PdfColor.fromHex('F3F9FE');

    final darkText = PdfColor.fromHex('152439');

    final mutedText = PdfColor.fromHex('6B7A8F');

    final tableBorderColor = PdfColor.fromHex('E4EBF3');

    // =========================================================
    // LOAD FONTS
    // =========================================================

    final fonts = await _loadFonts();

    pw.Font? regularFont = fonts.regular;
    pw.Font? boldFont = fonts.bold;

    final devanagariRegular = fonts.devanagariRegular;

    final devanagariBold = fonts.devanagariBold;

    // ---------------------------------------------------------
    // If normal NotoSans is missing, use Devanagari font
    // as the main font.
    // ---------------------------------------------------------

    regularFont ??= devanagariRegular;
    boldFont ??= devanagariBold ?? regularFont;

    // ---------------------------------------------------------
    // Create PDF theme with font fallback for Devanagari
    // ---------------------------------------------------------

    pw.ThemeData pdfTheme;

    if (regularFont != null) {
      pdfTheme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont ?? regularFont,
        fontFallback: [
          ?devanagariRegular,
          ?devanagariBold,
        ],
      );
    } else {
      pdfTheme = pw.ThemeData.base();

      debugPrint('PDF WARNING: No custom fonts were loaded.');
    }

    // =========================================================
    // ADD PDF PAGE
    // =========================================================

    pdf.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 24),

        // =====================================================
        // HEADER
        // =====================================================
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        distributorCompanyName.isNotEmpty
                            ? distributorCompanyName.toUpperCase()
                            : 'MILKROUTE DISTRIBUTION',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),

                      if (distributorOwnerName.isNotEmpty ||
                          distributorMobile.isNotEmpty) ...[
                        pw.SizedBox(height: 2),

                        pw.Text(
                          [
                            if (distributorOwnerName.isNotEmpty)
                              'Prop: $distributorOwnerName',

                            if (distributorMobile.isNotEmpty)
                              'Ph: $distributorMobile',
                          ].join(' | '),
                          style: pw.TextStyle(fontSize: 8.5, color: mutedText),
                        ),
                      ],

                      if (distributorAddress.isNotEmpty) ...[
                        pw.SizedBox(height: 1),

                        pw.Text(
                          distributorAddress,
                          style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                        ),
                      ],
                    ],
                  ),

                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'DAILY DELIVERY CHECKLIST',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: tableBorderColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Period: ${report.dateFilterName}',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),

                    pw.Text(
                      'Status: ${report.statusFilter}',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),

                    pw.Text(
                      'Generated: ${dateFormat.format(report.generatedAt)}',
                      style: pw.TextStyle(fontSize: 8, color: mutedText),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
            ],
          );
        },

        // =====================================================
        // FOOTER
        // =====================================================
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: tableBorderColor, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MilkRoute Distribution & Shop Management System',
                  style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                ),

                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          );
        },

        // =====================================================
        // PAGE CONTENT
        // =====================================================
        build: (pw.Context context) {
          return [
            // =================================================
            // KPI CARDS
            // =================================================
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                children: [
                  _pdfKpiCard(
                    title: 'TOTAL CUSTOMERS',
                    value: '${report.customerSummaries.length}',
                    color: primaryColor,
                  ),

                  pw.SizedBox(width: 6),

                  _pdfKpiCard(
                    title: 'TOTAL QUANTITY',
                    value: '${report.grandTotalQuantity} Units',
                    color: accentGreen,
                  ),

                  pw.SizedBox(width: 6),

                  _pdfKpiCard(
                    title: 'TOTAL AMOUNT',
                    value: 'Rs. ${numberFormat.format(report.grandTotalRupees)}',
                    color: secondaryColor,
                  ),

                  pw.SizedBox(width: 6),

                  _pdfKpiCard(
                    title: 'TOTAL BRANDS',
                    value: '${report.brandSummaries.length}',
                    color: PdfColor.fromHex('B4740A'),
                  ),
                ],
              ),
            ),

            if (report.customerSummaries.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(30),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'No orders found for the selected date filter.',
                  style: pw.TextStyle(fontSize: 11, color: mutedText),
                ),
              )
            else ...[
              // =================================================
              // 1. CUSTOMER-WISE DELIVERY CHECKLIST TABLE
              // =================================================
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 14),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: tableBorderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: tableBorderColor,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '1. CUSTOMER-WISE DELIVERY CHECKLIST (ग्राहक वितरण यादी)',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          pw.Text(
                            '${report.customerSummaries.length} Customer Orders',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Customer Checklist Table
                    pw.TableHelper.fromTextArray(
                      border: pw.TableBorder(
                        horizontalInside: pw.BorderSide(
                          color: tableBorderColor,
                          width: 0.5,
                        ),
                      ),
                      headerStyle: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                      ),
                      cellStyle: pw.TextStyle(fontSize: 8, color: darkText),
                      cellPadding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      headers: <String>[
                        '#',
                        'Customer / Shop Name',
                        'Address / Route',
                        'Products & Quantities',
                        'Qty',
                        'Amount (Rs.)',
                        'Pay Status',
                        'Check [  ]',
                      ],
                      data: report.customerSummaries.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final c = entry.value;

                        final contactLine = [
                          c.shopName,
                          if (c.shopOwner.isNotEmpty && c.shopOwner != c.shopName)
                            '(${c.shopOwner})',
                          if (c.shopMobile.isNotEmpty) 'Ph: ${c.shopMobile}',
                        ].join(' ');

                        final addrLine = c.deliveryAddress.isNotEmpty
                            ? c.deliveryAddress
                            : (c.deliveryTime.isNotEmpty
                                ? 'Slot: ${c.deliveryTime}'
                                : '-');

                        final productsLine = c.items.isNotEmpty
                            ? c.items
                                .map((i) => '${i.productName} (${i.packSize}) x${i.quantity}')
                                .join(', ')
                            : 'Order #${c.orderNumber}';

                        final checkMark = c.isChecked ? '[ ✓ ]' : '[   ]';

                        return [
                          '$idx',
                          contactLine,
                          addrLine,
                          productsLine,
                          '${c.totalQuantity}',
                          'Rs. ${numberFormat.format(c.totalAmount)}',
                          c.paymentStatus.toUpperCase(),
                          checkMark,
                        ];
                      }).toList(),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(18),
                        1: const pw.FlexColumnWidth(3.0),
                        2: const pw.FlexColumnWidth(2.0),
                        3: const pw.FlexColumnWidth(3.8),
                        4: const pw.FlexColumnWidth(1.1),
                        5: const pw.FlexColumnWidth(1.8),
                        6: const pw.FlexColumnWidth(1.4),
                        7: const pw.FlexColumnWidth(1.4),
                      },
                      cellAlignments: {
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.centerLeft,
                        4: pw.Alignment.centerRight,
                        5: pw.Alignment.centerRight,
                        6: pw.Alignment.center,
                        7: pw.Alignment.center,
                      },
                    ),
                  ],
                ),
              ),

              // =================================================
              // 2. BRAND-WISE LOADING SUMMARY
              // =================================================
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: tableBorderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Brand Header Bar
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: tableBorderColor,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '2. BRAND-WISE LOADING SUMMARY (एकूण माल लोडिंग बेरीज)',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          pw.Text(
                            'Total Loading: ${report.grandTotalQuantity} Pkts/Units',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ...report.brandSummaries.map((brand) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              color: PdfColors.grey100,
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    brand.brandName.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  pw.Text(
                                    'Subtotal: ${brand.totalQuantity} Units | Rs. ${numberFormat.format(brand.totalRupees)}',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.TableHelper.fromTextArray(
                              border: pw.TableBorder(
                                horizontalInside: pw.BorderSide(
                                  color: tableBorderColor,
                                  width: 0.5,
                                ),
                              ),
                              headerStyle: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: secondaryColor,
                              ),
                              headerDecoration: const pw.BoxDecoration(
                                color: PdfColors.white,
                              ),
                              cellStyle: pw.TextStyle(fontSize: 7.5, color: darkText),
                              cellPadding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3.5,
                              ),
                              headers: <String>[
                                '#',
                                'Product / Variant Name',
                                'Pack Size',
                                'Rate (Rs.)',
                                'Total Quantity',
                                'Total Rupees (Rs.)',
                              ],
                              data: brand.variantList.asMap().entries.map((entry) {
                                final idx = entry.key + 1;
                                final v = entry.value;
                                return [
                                  '$idx',
                                  v.productName,
                                  v.packSize,
                                  'Rs. ${numberFormat.format(v.unitPrice)}',
                                  '${v.totalQuantity} ${v.unit}',
                                  'Rs. ${numberFormat.format(v.totalRupees)}',
                                ];
                              }).toList(),
                              columnWidths: {
                                0: const pw.FixedColumnWidth(18),
                                1: const pw.FlexColumnWidth(3.5),
                                2: const pw.FlexColumnWidth(1.6),
                                3: const pw.FlexColumnWidth(1.8),
                                4: const pw.FlexColumnWidth(2.0),
                                5: const pw.FlexColumnWidth(2.2),
                              },
                              cellAlignments: {
                                0: pw.Alignment.center,
                                1: pw.Alignment.centerLeft,
                                2: pw.Alignment.centerLeft,
                                3: pw.Alignment.centerRight,
                                4: pw.Alignment.centerRight,
                                5: pw.Alignment.centerRight,
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // =================================================
              // GRAND TOTAL
              // =================================================
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: primaryColor, width: 1.1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GRAND TOTAL (ALL ORDERS SUMMARY)',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Total Customers: ${report.customerSummaries.length} | Unique Brands: ${report.brandSummaries.length}',
                          style: pw.TextStyle(fontSize: 8, color: mutedText),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Total Quantity',
                              style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                            ),
                            pw.Text(
                              '${report.grandTotalQuantity} Units',
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 14),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Grand Total Amount',
                              style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                            ),
                            pw.Text(
                              'Rs. ${numberFormat.format(report.grandTotalRupees)}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ===========================================================
  // KPI CARD
  // ===========================================================

  static pw.Widget _pdfKpiCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),

        decoration: pw.BoxDecoration(
          color: PdfColors.white,

          borderRadius: pw.BorderRadius.circular(6),

          border: pw.Border.all(color: PdfColor.fromHex('E4EBF3'), width: 0.8),
        ),

        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('6B7A8F'),
              ),
            ),

            pw.SizedBox(height: 2),

            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // PRINT / SAVE PDF
  // ===========================================================

  static Future<void> downloadOrPrintPdf({
    required TotalOrdersReportData report,
    required String distributorCompanyName,
    String distributorOwnerName = '',
    String distributorMobile = '',
    String distributorAddress = '',
  }) async {
    final bytes = await generatePdfBytes(
      report: report,
      distributorCompanyName: distributorCompanyName,
      distributorOwnerName: distributorOwnerName,
      distributorMobile: distributorMobile,
      distributorAddress: distributorAddress,
    );

    final cleanName = distributorCompanyName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );

    final fileName =
        'Total_Orders_Brand_Summary_${cleanName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async {
        return bytes;
      },
    );
  }

  // ===========================================================
  // SHARE PDF
  // ===========================================================

  static Future<void> sharePdfReport({
    required TotalOrdersReportData report,
    required String distributorCompanyName,
    String distributorOwnerName = '',
    String distributorMobile = '',
    String distributorAddress = '',
  }) async {
    final bytes = await generatePdfBytes(
      report: report,
      distributorCompanyName: distributorCompanyName,
      distributorOwnerName: distributorOwnerName,
      distributorMobile: distributorMobile,
      distributorAddress: distributorAddress,
    );

    final cleanName = distributorCompanyName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );

    final fileName =
        'Total_Orders_Brand_Summary_${cleanName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
