import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:out_schedule_to_pdf/main.dart';

void main() {
  testWidgets('App renders input form', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());

    // Verify header and section titles
    expect(find.text('学习计划'), findsOneWidget);
    expect(find.text('日期设置'), findsOneWidget);
    expect(find.text('学习内容'), findsOneWidget);

    // Verify date picker fields are present
    expect(find.text('考试日期'), findsOneWidget);
    expect(find.text('计划日期'), findsOneWidget);

    // Verify multi-line text fields are present
    expect(find.text('言语'), findsOneWidget);
    expect(find.text('判断推理'), findsOneWidget);

    // Verify generate button
    expect(find.text('生成预览'), findsOneWidget);
  });
}
