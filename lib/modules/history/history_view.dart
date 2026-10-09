import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/currency.dart';
import '../../data/models/sale.dart';
import '../pos/widgets/receipt_dialog.dart';
import 'history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null) controller.selectDate(date);
  }

  Future<void> _confirmDelete(BuildContext context, Sale sale) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('ลบรายการขาย?'),
        content: Text('รายการ ${sale.id} จะถูกลบออกจากประวัติ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      controller.remove(sale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการขาย'),
        actions: [
          IconButton(
            tooltip: 'กลับช่วงปัจจุบัน',
            onPressed: controller.showCurrentPeriod,
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: Obx(() {
        // อ่าน list ก่อนเพื่อให้ Obx ติดตามการเปลี่ยนแปลง
        final sales = controller.list.toList();
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SegmentedButton<HistoryPeriod>(
                showSelectedIcon: false,
                segments: HistoryPeriod.values
                    .map(
                      (period) => ButtonSegment(
                        value: period,
                        label: Text(period.label),
                      ),
                    )
                    .toList(),
                selected: {controller.period.value},
                onSelectionChanged: (selection) =>
                    controller.selectPeriod(selection.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'ช่วงก่อนหน้า',
                    onPressed: () => controller.movePeriod(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        controller.periodLabel,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ช่วงถัดไป',
                    onPressed: () => controller.movePeriod(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยอดขายราย${controller.period.value.label}'),
                  Text(baht(controller.total),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${controller.count} บิล'),
                ],
              ),
            ),
            Expanded(
              child: sales.isEmpty
                  ? const Center(child: Text('ไม่มีรายการขายในช่วงนี้'))
                  : ListView.separated(
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = sales[i];
                        final t = s.time;
                        final hm =
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text('${s.id} · ${s.itemCount} ชิ้น'),
                          subtitle: Text('$hm · ${s.method.label}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                baht(s.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                tooltip: 'ลบรายการ',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: scheme.error,
                                ),
                                onPressed: () => _confirmDelete(context, s),
                              ),
                            ],
                          ),
                          onTap: () => Get.dialog(ReceiptDialog(sale: s)),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
