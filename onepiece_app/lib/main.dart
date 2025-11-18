import 'package:flutter/material.dart';
import 'pages/cards_page.dart';
import 'pages/decks_page.dart';
import 'pages/profile_page.dart';

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
    CardsPage(),   
    DecksPage(),   
    ProfilePage(), 
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One Piece Decks'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.style), label: 'Cartas'),
          NavigationDestination(icon: Icon(Icons.layers), label: 'Mazos'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Perfil'),
        ],
      ),
    );
  }
}
