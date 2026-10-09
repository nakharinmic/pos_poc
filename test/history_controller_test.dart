import 'package:flutter_test/flutter_test.dart';
import 'package:pos_poc/data/models/sale.dart';
import 'package:pos_poc/data/services/sales_service.dart';
import 'package:pos_poc/modules/history/history_controller.dart';

void main() {
  late SalesService sales;
  late HistoryController history;

  Sale sale(String id, DateTime time, double total) => Sale(
        id: id,
        time: time,
        items: const [],
        subtotal: total,
        discount: 0,
        total: total,
        method: PaymentMethod.cash,
        received: total,
      );

  setUp(() {
    sales = SalesService();
    history = HistoryController(sales: sales);
    sales.add(sale('jan-1', DateTime(2026, 1, 1, 10), 100));
    sales.add(sale('jan-5', DateTime(2026, 1, 5, 10), 200));
    sales.add(sale('jan-11', DateTime(2026, 1, 11, 10), 300));
    sales.add(sale('feb-1', DateTime(2026, 2, 1, 10), 400));
    sales.add(sale('next-year', DateTime(2027, 1, 1, 10), 500));
  });

  test('กรองประวัติรายวัน', () {
    history.selectDate(DateTime(2026, 1, 5));

    expect(history.list.map((sale) => sale.id), ['jan-5']);
    expect(history.total, 200);
    expect(history.count, 1);
  });

  test('กรองประวัติรายสัปดาห์โดยเริ่มวันจันทร์', () {
    history.selectPeriod(HistoryPeriod.week);
    history.selectDate(DateTime(2026, 1, 7));

    expect(history.rangeStart, DateTime(2026, 1, 5));
    expect(history.list.map((sale) => sale.id), ['jan-11', 'jan-5']);
    expect(history.total, 500);
  });

  test('กรองประวัติรายเดือนและเลื่อนไปเดือนถัดไป', () {
    history.selectPeriod(HistoryPeriod.month);
    history.selectDate(DateTime(2026, 1, 20));

    expect(history.count, 3);
    expect(history.total, 600);

    history.movePeriod(1);
    expect(history.periodLabel, 'กุมภาพันธ์ 2026');
    expect(history.list.map((sale) => sale.id), ['feb-1']);
  });

  test('กรองประวัติรายปี', () {
    history.selectPeriod(HistoryPeriod.year);
    history.selectDate(DateTime(2026, 6, 1));

    expect(history.count, 4);
    expect(history.total, 1000);
  });
}
