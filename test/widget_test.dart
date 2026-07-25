// 宅トレカレンダーアプリの基本ウィジェットテスト
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workout_calendar/main.dart';
import 'package:workout_calendar/models/workout_record.dart';
import 'package:workout_calendar/providers/workout_provider.dart';

void main() {
  testWidgets('カレンダー画面が表示される', (WidgetTester tester) async {
    // テスト用の一時Hiveディレクトリを初期化
    Hive.init('./test/hive_test_data');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WorkoutRecordAdapter());
    }

    final workoutProvider = WorkoutProvider();
    await workoutProvider.init();

    await tester.pumpWidget(MyApp(workoutProvider: workoutProvider));
    await tester.pumpAndSettle();

    expect(find.text('宅トレカレンダー'), findsOneWidget);
  });
}
