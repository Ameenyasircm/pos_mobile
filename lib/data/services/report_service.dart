import '../models/bill_model.dart';
import 'bill_service.dart';

class ReportSummary {
  final double totalRevenue;
  final int totalBilledOrders;
  final double averageOrderValue;
  final int totalItemsSold;
  final List<BillModel> billedBills;
  final List<Map<String, dynamic>> topSellingItems;
  final Map<String, double> tableSales;
  final Map<String, double> staffSales;

  ReportSummary({
    required this.totalRevenue,
    required this.totalBilledOrders,
    required this.averageOrderValue,
    required this.totalItemsSold,
    required this.billedBills,
    required this.topSellingItems,
    required this.tableSales,
    required this.staffSales,
  });
}

class ReportService {
  final BillService _billService = BillService();

  /// Stream of official bills from `bills` collection between startDate and endDate
  Stream<List<BillModel>> getBilledBillsStream(DateTime startDate, DateTime endDate) {
    return _billService.getBillsStream(startDate, endDate);
  }

  /// Calculates aggregated sales report summary directly from official bill documents
  ReportSummary generateReportSummaryFromBills(List<BillModel> bills) {
    double totalRevenue = 0.0;
    int totalItemsSold = 0;
    final Map<String, Map<String, dynamic>> itemStats = {};
    final Map<String, double> tableSales = {};
    final Map<String, double> staffSales = {};

    for (final bill in bills) {
      totalRevenue += bill.totalAmount;

      // Table performance
      final tbl = bill.tableName;
      tableSales[tbl] = (tableSales[tbl] ?? 0.0) + bill.totalAmount;

      // Admin / Staff billing performance
      final billedBy = bill.billedBy;
      staffSales[billedBy] = (staffSales[billedBy] ?? 0.0) + bill.totalAmount;

      // Items analytics from bill.items
      for (final item in bill.items) {
        totalItemsSold += item.quantity;
        final name = item.name;

        if (!itemStats.containsKey(name)) {
          itemStats[name] = {'name': name, 'quantity': 0, 'revenue': 0.0};
        }
        itemStats[name]!['quantity'] = (itemStats[name]!['quantity'] as int) + item.quantity;
        itemStats[name]!['revenue'] = (itemStats[name]!['revenue'] as double) + item.totalPrice;
      }
    }

    final topSellingItems = itemStats.values.toList();
    topSellingItems.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    final totalBilledOrders = bills.length;
    final avgOrderVal = totalBilledOrders > 0 ? (totalRevenue / totalBilledOrders) : 0.0;

    return ReportSummary(
      totalRevenue: totalRevenue,
      totalBilledOrders: totalBilledOrders,
      averageOrderValue: avgOrderVal,
      totalItemsSold: totalItemsSold,
      billedBills: bills,
      topSellingItems: topSellingItems,
      tableSales: tableSales,
      staffSales: staffSales,
    );
  }
}
