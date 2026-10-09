import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/currency.dart';
import '../../../data/models/sale.dart';
import '../pos_controller.dart';

/// ไดอะล็อกรับชำระเงิน — ปิดพร้อมคืนค่า Sale เมื่อชำระสำเร็จ
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final pos = Get.find<PosController>();
  final receivedCtrl = TextEditingController();
  PaymentMethod method = PaymentMethod.cash;

  double get total => pos.total;
  double get received => method == PaymentMethod.promptPay
      ? total
      : double.tryParse(receivedCtrl.text) ?? 0;
  bool get canConfirm => received >= total;

  @override
  void dispose() {
    receivedCtrl.dispose();
    super.dispose();
  }

  void _setReceived(double v) {
    receivedCtrl.text = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    setState(() {});
  }

  void _confirm() {
    final sale = pos.checkout(method: method, received: received);
    Get.back(result: sale);
  }

  void _selectMethod(PaymentMethod value) {
    if (value == PaymentMethod.promptPay) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() => method = value);
  }

  @override
  Widget build(BuildContext context) {
    final quick = <double>{total, 100, 500, 1000}.where((v) => v >= total);
    return AlertDialog(
      scrollable: true,
      title: const Text('ชำระเงิน'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ยอดที่ต้องชำระ',
                style: Theme.of(context).textTheme.bodyMedium),
            Text(baht(total),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SegmentedButton<PaymentMethod>(
              segments: PaymentMethod.values
                  .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                  .toList(),
              selected: {method},
              onSelectionChanged: (selection) => _selectMethod(selection.first),
            ),
            const SizedBox(height: 16),
            if (method == PaymentMethod.cash) ...[
              TextField(
                controller: receivedCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'รับเงินมา',
                  prefixText: '฿ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (canConfirm) _confirm();
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: quick
                    .map((v) => ActionChip(
                          label: Text(v == total ? 'พอดี' : baht(v)),
                          onPressed: () => _setReceived(v),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('เงินทอน'),
                  const Spacer(),
                  Text(
                    canConfirm ? baht(received - total) : '-',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ] else
              Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2, size: 96),
                    Text('QR พร้อมเพย์ (จำลอง)'),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: canConfirm ? _confirm : null,
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}
