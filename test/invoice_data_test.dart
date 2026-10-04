import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/core/services/invoice_pdf_service.dart';

InvoiceData _seller({
  required int subtotal,
  required int flatFee,
  required double rate,
  required int commission,
}) => InvoiceData.sellerCopy(
  orderId: 'order9afrxm',
  invoiceDate: DateTime(2026, 10, 5),
  billToName: 'Buyer',
  billToAddressLines: const ['Bhubaneswar'],
  items: const [InvoiceLineItem(name: 'Mug', quantity: 1, unitPrice: 3)],
  subtotal: subtotal,
  flatFee: flatFee,
  commissionRate: rate,
  commissionAmount: commission,
);

void main() {
  test('flat platform fee is paid by the buyer, not deducted from the payout', () {
    final data = _seller(subtotal: 3, flatFee: 5, rate: 0, commission: 0);
    expect(data.totalDeductions, 0);
    expect(data.creatorPayout, 3);
  });

  test('only the commission comes off the subtotal', () {
    final data = _seller(subtotal: 2000, flatFee: 50, rate: 5, commission: 100);
    expect(data.totalDeductions, 100);
    expect(data.creatorPayout, 1900);
  });

  test('invoice and order numbers share the order id suffix', () {
    final data = _seller(subtotal: 3, flatFee: 5, rate: 0, commission: 0);
    expect(data.invoiceNumber, 'MBH-9AFRXM');
    expect(data.orderNumber, 'ORD-9AFRXM');
  });
}
