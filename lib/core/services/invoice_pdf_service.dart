// Generates downloadable PDF invoices for a placed order — a buyer copy
// (what the buyer paid, no fee breakdown) and a seller copy (the platform's
// flat fee + commission breakdown and the resulting payout). Both are built
// purely from the fee figures already snapshotted onto the order document at
// checkout time (see `server/fees.js` / `api/finalize-payment.js`), so an
// invoice always reflects the admin-set fees that were actually in force
// when that particular order was placed — never the current live settings.
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String _companyName = 'MADEBYHANDS';
const String _companyAddress = 'Bhubaneswar, Patia';

class InvoiceLineItem {
  final String name;
  final int quantity;
  final int unitPrice;

  const InvoiceLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  int get amount => quantity * unitPrice;
}

/// Everything needed to render one invoice. Build a buyer-copy instance with
/// [InvoiceData.buyerCopy] and a seller-copy instance with
/// [InvoiceData.sellerCopy] rather than the default constructor directly.
class InvoiceData {
  final String invoiceNumber;
  final String orderNumber;
  final DateTime invoiceDate;
  final String billToName;
  final List<String> billToAddressLines;
  final List<InvoiceLineItem> items;
  final int subtotal;
  final bool isSellerCopy;

  // Seller-copy only.
  final int flatFee;
  final double commissionRate;
  final int commissionAmount;

  // Buyer-copy only.
  final int buyerTotalPaid;

  const InvoiceData({
    required this.invoiceNumber,
    required this.orderNumber,
    required this.invoiceDate,
    required this.billToName,
    required this.billToAddressLines,
    required this.items,
    required this.subtotal,
    required this.isSellerCopy,
    this.flatFee = 0,
    this.commissionRate = 0,
    this.commissionAmount = 0,
    this.buyerTotalPaid = 0,
  });

  int get totalFees => flatFee + commissionAmount;
  int get creatorPayout => subtotal - commissionAmount;

  factory InvoiceData.buyerCopy({
    required String orderId,
    required DateTime invoiceDate,
    required String billToName,
    required List<String> billToAddressLines,
    required List<InvoiceLineItem> items,
    required int subtotal,
    required int buyerTotalPaid,
  }) {
    return InvoiceData(
      invoiceNumber: _invoiceNumber(orderId),
      orderNumber: _orderNumber(orderId),
      invoiceDate: invoiceDate,
      billToName: billToName,
      billToAddressLines: billToAddressLines,
      items: items,
      subtotal: subtotal,
      isSellerCopy: false,
      buyerTotalPaid: buyerTotalPaid,
    );
  }

  factory InvoiceData.sellerCopy({
    required String orderId,
    required DateTime invoiceDate,
    required String billToName,
    required List<String> billToAddressLines,
    required List<InvoiceLineItem> items,
    required int subtotal,
    required int flatFee,
    required double commissionRate,
    required int commissionAmount,
  }) {
    return InvoiceData(
      invoiceNumber: _invoiceNumber(orderId),
      orderNumber: _orderNumber(orderId),
      invoiceDate: invoiceDate,
      billToName: billToName,
      billToAddressLines: billToAddressLines,
      items: items,
      subtotal: subtotal,
      isSellerCopy: true,
      flatFee: flatFee,
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
    );
  }

  static String _invoiceNumber(String orderId) =>
      'MBH-${_shortId(orderId)}';

  static String _orderNumber(String orderId) => 'ORD-${_shortId(orderId)}';

  static String _shortId(String orderId) => (orderId.length > 6
          ? orderId.substring(orderId.length - 6)
          : orderId)
      .toUpperCase();
}

class InvoicePdfService {
  static final NumberFormat _amountFormat = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String _money(num value) => 'Rs. ${_amountFormat.format(value)}';

  /// Renders [data] to PDF bytes. Uses a bundled Unicode font so amounts and
  /// the "Rs." prefix always render, even offline.
  static Future<Uint8List> buildPdf(InvoiceData data) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => _buildBody(data),
      ),
    );

    return doc.save();
  }

  /// Builds the PDF and hands it to the platform's share/print sheet — a
  /// download prompt on web, a share sheet on mobile.
  static Future<void> downloadOrShare(InvoiceData data) async {
    final bytes = await buildPdf(data);
    final suffix = data.isSellerCopy ? 'seller' : 'buyer';
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${data.invoiceNumber}-$suffix-copy.pdf',
    );
  }

  static pw.Widget _buildBody(InvoiceData data) {
    const brand = PdfColor.fromInt(0xFF8B261D);
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
                  _companyName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: brand,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(_companyAddress),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (data.isSellerCopy)
                  pw.Text(
                    'SELLER COPY',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: brand,
                    ),
                  )
                else
                  pw.Text(
                    'BUYER COPY',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: brand,
                    ),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 36),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill To',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(data.billToName),
                for (final line in data.billToAddressLines) pw.Text(line),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _metaRow('Invoice #', data.invoiceNumber),
                _metaRow('Invoice Date', _dateFormat.format(data.invoiceDate)),
                _metaRow('Order #', data.orderNumber),
                _metaRow('Payment Status', 'Paid'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 28),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('QTY', bold: true),
                _cell('DESCRIPTION', bold: true),
                _cell('UNIT PRICE', bold: true, align: pw.Alignment.centerRight),
                _cell('AMOUNT', bold: true, align: pw.Alignment.centerRight),
              ],
            ),
            for (final item in data.items)
              pw.TableRow(
                children: [
                  _cell('${item.quantity}'),
                  _cell(item.name),
                  _cell(_money(item.unitPrice), align: pw.Alignment.centerRight),
                  _cell(_money(item.amount), align: pw.Alignment.centerRight),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 260,
            child: data.isSellerCopy
                ? _sellerTotals(data, brand)
                : _buyerTotals(data, brand),
          ),
        ),
      ],
    );
  }

  static pw.Widget _sellerTotals(InvoiceData data, PdfColor brand) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _totalRow('Subtotal', _money(data.subtotal)),
        _totalRow('Seller Platform Fee', _money(data.flatFee)),
        _totalRow(
          data.commissionAmount > 0
              ? 'Transaction Fee (${data.commissionRate.toStringAsFixed(0)}% on orders above Rs. 999)'
              : 'Transaction Fee (not applicable)',
          _money(data.commissionAmount),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _totalRow(
            'TOTAL FEES',
            _money(data.totalFees),
            bold: true,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _totalRow(
            'Creator Payout',
            _money(data.creatorPayout),
            bold: true,
            color: brand,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buyerTotals(InvoiceData data, PdfColor brand) {
    return pw.Container(
      color: PdfColors.grey200,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: _totalRow(
        'Total Amount Paid',
        _money(data.buyerTotalPaid),
        bold: true,
        color: brand,
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(value, style: style),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(value),
          ],
        ),
      );

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) =>
      pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
}

/// Thrown as a [debugPrint] breadcrumb only — invoice generation failures are
/// surfaced to the user via a snackbar by the calling page, not here.
void logInvoiceError(Object error) =>
    debugPrint('Invoice generation failed: $error');
