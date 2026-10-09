import 'package:get/get.dart';

import '../models/sale.dart';

/// เก็บประวัติการขาย (in-memory) แชร์ระหว่างหน้าขายและหน้าประวัติ
class SalesService extends GetxService {
  final sales = <Sale>[].obs;

  void add(Sale sale) => sales.insert(0, sale);

  void remove(String saleId) => sales.removeWhere((sale) => sale.id == saleId);

  List<Sale> get todaySales {
    final now = DateTime.now();
    return sales
        .where((s) =>
            s.time.year == now.year &&
            s.time.month == now.month &&
            s.time.day == now.day)
        .toList();
  }

  double get todayTotal => todaySales.fold(0, (sum, s) => sum + s.total);

  String nextId() =>
      'R${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
}
