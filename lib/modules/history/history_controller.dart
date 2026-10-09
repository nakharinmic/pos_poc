import 'package:get/get.dart';

import '../../data/models/sale.dart';
import '../../data/services/sales_service.dart';

enum HistoryPeriod {
  day('วัน'),
  week('สัปดาห์'),
  month('เดือน'),
  year('ปี');

  const HistoryPeriod(this.label);
  final String label;
}

class HistoryController extends GetxController {
  HistoryController({required this.sales});

  final SalesService sales;
  final period = HistoryPeriod.day.obs;
  final selectedDate = DateTime.now().obs;

  List<Sale> get list {
    final start = rangeStart;
    final end = rangeEnd;
    return sales.sales
        .where((sale) => !sale.time.isBefore(start) && sale.time.isBefore(end))
        .toList();
  }

  double get total => list.fold(0, (sum, sale) => sum + sale.total);
  int get count => list.length;

  DateTime get rangeStart {
    final date = selectedDate.value;
    switch (period.value) {
      case HistoryPeriod.day:
        return DateTime(date.year, date.month, date.day);
      case HistoryPeriod.week:
        final day = DateTime(date.year, date.month, date.day);
        return day.subtract(Duration(days: day.weekday - DateTime.monday));
      case HistoryPeriod.month:
        return DateTime(date.year, date.month);
      case HistoryPeriod.year:
        return DateTime(date.year);
    }
  }

  DateTime get rangeEnd {
    final start = rangeStart;
    switch (period.value) {
      case HistoryPeriod.day:
        return start.add(const Duration(days: 1));
      case HistoryPeriod.week:
        return start.add(const Duration(days: 7));
      case HistoryPeriod.month:
        return DateTime(start.year, start.month + 1);
      case HistoryPeriod.year:
        return DateTime(start.year + 1);
    }
  }

  String get periodLabel {
    String date(DateTime value) => '${value.day}/${value.month}/${value.year}';

    final start = rangeStart;
    switch (period.value) {
      case HistoryPeriod.day:
        return date(start);
      case HistoryPeriod.week:
        final lastDay = rangeEnd.subtract(const Duration(days: 1));
        return '${date(start)} – ${date(lastDay)}';
      case HistoryPeriod.month:
        const months = [
          'มกราคม',
          'กุมภาพันธ์',
          'มีนาคม',
          'เมษายน',
          'พฤษภาคม',
          'มิถุนายน',
          'กรกฎาคม',
          'สิงหาคม',
          'กันยายน',
          'ตุลาคม',
          'พฤศจิกายน',
          'ธันวาคม',
        ];
        return '${months[start.month - 1]} ${start.year}';
      case HistoryPeriod.year:
        return start.year.toString();
    }
  }

  void selectPeriod(HistoryPeriod value) => period.value = value;

  void selectDate(DateTime value) {
    selectedDate.value = DateTime(value.year, value.month, value.day);
  }

  void showCurrentPeriod() => selectDate(DateTime.now());

  void movePeriod(int amount) {
    final start = rangeStart;
    switch (period.value) {
      case HistoryPeriod.day:
        return selectDate(start.add(Duration(days: amount)));
      case HistoryPeriod.week:
        return selectDate(start.add(Duration(days: 7 * amount)));
      case HistoryPeriod.month:
        return selectDate(DateTime(start.year, start.month + amount));
      case HistoryPeriod.year:
        return selectDate(DateTime(start.year + amount));
    }
  }

  void remove(Sale sale) => sales.remove(sale.id);
}
