import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'models/workout_record.dart';
import 'providers/workout_provider.dart';
import 'theme/app_theme.dart';
import 'screens/calendar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(WorkoutRecordAdapter());
  await initializeDateFormatting('ja_JP');

  final workoutProvider = WorkoutProvider();
  await workoutProvider.init();

  runApp(MyApp(workoutProvider: workoutProvider));
}

class MyApp extends StatelessWidget {
  final WorkoutProvider workoutProvider;

  const MyApp({super.key, required this.workoutProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: workoutProvider,
      child: MaterialApp(
        title: '宅トレカレンダー',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ja', 'JP'),
        supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const CalendarScreen(),
      ),
    );
  }
}
