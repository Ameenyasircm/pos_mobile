import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/bill_model.dart';
import '../../providers/report_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  Future<void> _selectCustomDateRange(BuildContext context, ReportProvider reportProvider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: reportProvider.startDate,
        end: reportProvider.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      reportProvider.setFilter(
        ReportFilter.custom,
        customStart: DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
        customEnd: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Sales & Revenue Reports'),
      ),
      body: Column(
        children: [
          // Filter Chips & Date Range Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(reportProvider, ReportFilter.today, 'Today'),
                      const SizedBox(width: 8),
                      _buildFilterChip(reportProvider, ReportFilter.yesterday, 'Yesterday'),
                      const SizedBox(width: 8),
                      _buildFilterChip(reportProvider, ReportFilter.thisWeek, 'This Week'),
                      const SizedBox(width: 8),
                      _buildFilterChip(reportProvider, ReportFilter.thisMonth, 'This Month'),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Custom'),
                          ],
                        ),
                        selected: reportProvider.filter == ReportFilter.custom,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: reportProvider.filter == ReportFilter.custom ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _selectCustomDateRange(context, reportProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Report Period: ${DateFormatter.formatTimestamp(reportProvider.startDate)} - ${DateFormatter.formatTimestamp(reportProvider.endDate)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Reports Content Stream from `bills` Collection
          Expanded(
            child: StreamBuilder<List<BillModel>>(
              stream: reportProvider.getBilledBillsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final bills = snapshot.data ?? [];

                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No official bills found in `bills` collection for this period.',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                reportProvider.calculateSummaryFromBills(bills);
                final summary = reportProvider.summary;

                if (summary == null) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Executive KPI Metrics Grid (2x2)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _buildKpiCard(
                            title: 'Total Sales Revenue',
                            value: '₹${summary.totalRevenue.toStringAsFixed(2)}',
                            icon: Icons.attach_money_rounded,
                            color: const Color(0xFF2E7D32),
                          ),
                          _buildKpiCard(
                            title: 'Billed Orders (Bills)',
                            value: '${summary.totalBilledOrders}',
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF0288D1),
                          ),
                          _buildKpiCard(
                            title: 'Avg Order Value',
                            value: '₹${summary.averageOrderValue.toStringAsFixed(2)}',
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFFE65100),
                          ),
                          _buildKpiCard(
                            title: 'Items Sold',
                            value: '${summary.totalItemsSold}',
                            icon: Icons.restaurant_rounded,
                            color: const Color(0xFF6A1B9A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Top Selling Food & Drink Items Card
                      if (summary.topSellingItems.isNotEmpty) ...[
                        const Text(
                          'Top Selling Items',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: summary.topSellingItems.take(5).map((item) {
                                final double maxRev = (summary.topSellingItems.first['revenue'] as double);
                                final double percent = maxRev > 0 ? (item['revenue'] as double) / maxRev : 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            '${item['quantity']} Sold • ₹${(item['revenue'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: percent,
                                          minHeight: 8,
                                          backgroundColor: Colors.grey.shade200,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Table Performance Breakdown
                      if (summary.tableSales.isNotEmpty) ...[
                        const Text(
                          'Sales by Dining Table',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: summary.tableSales.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.table_bar_rounded, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        ],
                                      ),
                                      Text(
                                        '₹${entry.value.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Staff Performance Breakdown
                      if (summary.staffSales.isNotEmpty) ...[
                        const Text(
                          'Sales by Admin / Authorizer',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: summary.staffSales.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        ],
                                      ),
                                      Text(
                                        '₹${entry.value.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Official Bills Collection Audit Log
                      const Text(
                        'Official Bills Collection Log',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bills.length,
                        itemBuilder: (context, index) {
                          final bill = bills[index];
                          return _buildBilledCard(context, bill);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ReportProvider provider, ReportFilter f, String label) {
    final isSelected = provider.filter == f;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (selected) {
        if (selected) {
          provider.setFilter(f);
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilledCard(BuildContext context, BillModel bill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              bill.billNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                bill.tableName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Billed by: ${bill.billedBy} • ₹${bill.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          DateFormatter.formatTimestamp(bill.createdAt),
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: bill.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
