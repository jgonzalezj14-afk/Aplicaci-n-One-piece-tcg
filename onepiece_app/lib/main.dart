import 'package:flutter/material.dart';
import 'pages/cards_page.dart';
import 'pages/decks_page.dart';
import 'pages/profile_page.dart';
import 'pages/home_page.dart'; 

void main() {
  runApp(const OnePieceDecksApp());
}

class OnePieceDecksApp extends StatelessWidget {
  const OnePieceDecksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Piece Decks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
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

  final List<Widget> _pages = const [
    HomePage(),     
    CardsPage(),   
    DecksPage(),    
    ProfilePage(),  
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final Color _goldColor = const Color(0xFFFFC107);
    final Color _lightParchment = const Color(0xFFFFF8E1);

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
          backgroundColor: const Color(0xFF2D1E18),
          selectedItemColor: _goldColor,
          unselectedItemColor: _lightParchment.withOpacity(0.6),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed, 
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home), 
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Cartas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.layers),
              label: 'Mazos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}