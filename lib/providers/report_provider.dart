import 'package:flutter/foundation.dart';
import '../data/models/bill_model.dart';
import '../data/services/report_service.dart';

enum ReportFilter { today, yesterday, thisWeek, thisMonth, custom }

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  ReportFilter _filter = ReportFilter.today;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  ReportSummary? _summary;
  final bool _isLoading = false;
  String? _errorMessage;

  ReportFilter get filter => _filter;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  ReportSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReportProvider() {
    _updateDateRangeForFilter(ReportFilter.today);
  }

  void setFilter(ReportFilter newFilter, {DateTime? customStart, DateTime? customEnd}) {
    _filter = newFilter;
    if (newFilter == ReportFilter.custom && customStart != null && customEnd != null) {
      _startDate = customStart;
      _endDate = customEnd;
    } else {
      _updateDateRangeForFilter(newFilter);
    }
    notifyListeners();
  }

  void _updateDateRangeForFilter(ReportFilter f) {
    final now = DateTime.now();
    switch (f) {
      case ReportFilter.today:
        _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        _startDate = DateTime(y.year, y.month, y.day, 0, 0, 0);
        _endDate = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;
      case ReportFilter.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportFilter.thisMonth:
        _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportFilter.custom:
        break;
    }
  }

  Stream<List<BillModel>> getBilledBillsStream() {
    return _service.getBilledBillsStream(_startDate, _endDate);
  }

  void calculateSummaryFromBills(List<BillModel> bills) {
    try {
      _summary = _service.generateReportSummaryFromBills(bills);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
