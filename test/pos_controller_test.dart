import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_poc/core/currency.dart';
import 'package:pos_poc/data/models/product.dart';
import 'package:pos_poc/data/models/sale.dart';
import 'package:pos_poc/data/repositories/product_repository.dart';
import 'package:pos_poc/data/services/sales_service.dart';
import 'package:pos_poc/modules/pos/pos_controller.dart';

void main() {
  late PosController pos;
  late SalesService sales;

  const coffee = Product(id: 'a', name: 'กาแฟ', category: 'ดื่ม', price: 55);
  const cake = Product(id: 'b', name: 'เค้ก', category: 'ขนม', price: 45);

  setUp(() {
    Get.testMode = true;
    sales = SalesService();
    pos = PosController(repo: ProductRepository(), sales: sales);
  });

  test('เพิ่มสินค้าซ้ำแล้วจำนวนเพิ่ม ไม่สร้างแถวใหม่', () {
    pos.addToCart(coffee);
    pos.addToCart(coffee);
    pos.addToCart(cake);
    expect(pos.cart.length, 2);
    expect(pos.itemCount, 3);
    expect(pos.subtotal, 155);
  });

  test('ลดจำนวนจนเหลือ 0 แล้วลบออกจากตะกร้า', () {
    pos.addToCart(coffee);
    pos.decrease(pos.cart.first);
    expect(pos.cart, isEmpty);
  });

  test('ส่วนลด 10%', () {
    pos.addToCart(coffee);
    pos.addToCart(cake);
    pos.setDiscount(10);
    expect(pos.discount, 10);
    expect(pos.total, 90);
  });

  test('checkout บันทึกการขาย คำนวณเงินทอน และล้างตะกร้า', () {
    pos.addToCart(coffee);
    final sale = pos.checkout(method: PaymentMethod.cash, received: 100);
    expect(sale.change, 45);
    expect(sales.sales.length, 1);
    expect(pos.cart, isEmpty);
  });

  test('ลบรายการขายออกจากประวัติ', () {
    pos.addToCart(coffee);
    final sale = pos.checkout(method: PaymentMethod.cash, received: 100);

    sales.remove(sale.id);

    expect(sales.sales, isEmpty);
    expect(sales.todayTotal, 0);
  });

  test('รับเงินไม่พอ checkout ไม่ได้', () {
    pos.addToCart(coffee);
    expect(() => pos.checkout(method: PaymentMethod.cash, received: 50),
        throwsStateError);
  });

  test('จัดรูปแบบเงินบาท', () {
    expect(baht(1234.5), '฿1,234.50');
    expect(baht(0), '฿0.00');
  });
}
