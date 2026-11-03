import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  // ไม่ใช้ AppTheme ใน test เพราะ google_fonts จะพยายามโหลดฟอนต์จากเน็ต
  testWidgets('DemoShell มีแถบเมนูใบเสร็จ/แลกรางวัล', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DemoShell()));
    // รอ ReceiptController.load() (จำลองโหลด 300ms) ให้เสร็จ ไม่ให้มี timer ค้าง
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ใบเสร็จ'), findsOneWidget);
    expect(find.text('แลกรางวัล'), findsOneWidget);
    expect(find.text('เติมเงินสำเร็จ!'), findsOneWidget);
  });
}
