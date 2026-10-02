/// Courier partners a creator can pick when dispatching an order, and the
/// public tracking page buyers are sent to for each.
const kCourierOptions = <String>[
  'India Post (Speed Post)',
  'XpressBees',
  'Blue Dart',
  'Delhivery',
];

/// A tracking page for [consignmentNumber] with [carrierName], or null when
/// the carrier is unknown.
Uri? courierTrackingUri(String? carrierName, String? consignmentNumber) {
  final number = consignmentNumber?.trim() ?? '';
  if (number.isEmpty) return null;
  final carrier = (carrierName ?? '').toLowerCase();
  if (carrier.contains('india post') || carrier.contains('speed post')) {
    return Uri.https('www.indiapost.gov.in', '/_layouts/15/dop.portal.tracking/trackconsignment.aspx');
  }
  if (carrier.contains('xpressbees')) {
    return Uri.https('www.xpressbees.com', '/shipment/tracking', {'awbNo': number});
  }
  if (carrier.contains('blue dart')) {
    return Uri.https('www.bluedart.com', '/web/guest/trackdartresultthirdparty', {
      'trackFor': '0',
      'trackNo': number,
    });
  }
  if (carrier.contains('delhivery')) {
    return Uri.https('www.delhivery.com', '/track-v2/package/$number');
  }
  return null;
}
