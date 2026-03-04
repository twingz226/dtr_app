import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/records_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

/// Global notifier so any screen can read/toggle the current theme mode.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Load persisted theme preference
  final settingsBox = await Hive.openBox('settings');
  final savedTheme = settingsBox.get('themeMode', defaultValue: 'dark') as String;
  themeNotifier.value = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DTRApp());
}

class DTRApp extends StatefulWidget {
  const DTRApp({super.key});
  @override
  State<DTRApp> createState() => _DTRAppState();
}

class _DTRAppState extends State<DTRApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    return MaterialApp(
      title: 'OJT Daily Time Record',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.value,
      home: const MainNavigation(),
    );
  }
}

/// Toggles theme and persists the choice to Hive.
Future<void> toggleTheme() async {
  themeNotifier.value = themeNotifier.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
  final box = await Hive.openBox('settings');
  await box.put('themeMode', themeNotifier.value == ThemeMode.light ? 'light' : 'dark');
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    RecordsScreen(),
    SummaryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lightDivider;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: dividerColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Records',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}