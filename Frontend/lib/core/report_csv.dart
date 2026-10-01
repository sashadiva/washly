import '../models/partner_profile.dart';

/// Turn a [PartnerReport] into CSV text: a summary block, a per-product
/// breakdown, and an order-by-order list.
String buildReportCsv(PartnerReport r) {
  String esc(Object? v) {
    final s = '$v';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String rupiah(double v) => 'Rp ${v.toStringAsFixed(0)}';

  final b = StringBuffer();

  // Header.
  b.writeln('Washly Sales Report');
  b.writeln('Shop,${esc(r.shopName)}');
  b.writeln('Generated,${esc(r.generatedAt.toLocal())}');
  b.writeln('');

  // Summary.
  b.writeln('Summary');
  b.writeln('Metric,Value');
  b.writeln('Revenue (paid),${esc(rupiah(r.revenue))}');
  b.writeln('Total orders,${r.totalOrders}');
  b.writeln('Paid orders,${r.paidOrders}');
  b.writeln('Completed orders,${r.completedOrders}');
  b.writeln('Cancelled orders,${r.cancelledOrders}');
  b.writeln('Average order value,${esc(rupiah(r.averageOrderValue))}');
  b.writeln('');

  // Per-product breakdown.
  b.writeln('Sales by product');
  b.writeln('Service,Unit,Times ordered,Quantity sold,Revenue');
  for (final s in r.perService) {
    b.writeln(
      '${esc(s.serviceName)},${s.unit},${s.orders},'
      '${s.quantity.toStringAsFixed(s.unit == 'PER_KG' ? 1 : 0)},'
      '${esc(rupiah(s.revenue))}',
    );
  }
  b.writeln('');

  // Order list.
  b.writeln('Orders');
  b.writeln('Order ID,Date,Status,Total');
  for (final o in r.orders) {
    b.writeln(
      '${o.id},${esc(o.date.toLocal())},${o.status},${esc(rupiah(o.total))}',
    );
  }

  return b.toString();
}
