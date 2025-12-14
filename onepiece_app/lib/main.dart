import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  
import 'firebase_options.dart'; 
import 'pages/home_page.dart';
import 'pages/decks_page.dart'; 
import 'pages/cards_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Piece TCG',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF2D1E18), 
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CardsPage(), 
    const Center(child: Text("MAZOS (Próximamente)")), 
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color _goldColor = const Color(0xFFFFC107);
  final Color _lightParchment = const Color(0xFFFFF8E1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF2D1E18),
          textTheme: TextTheme(
            labelSmall: TextStyle(color: _lightParchment),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF1E120D), 
          selectedItemColor: _goldColor,
          unselectedItemColor: _lightParchment.withOpacity(0.6),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed, 
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.anchor), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cartas'),
            BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Mazos'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}