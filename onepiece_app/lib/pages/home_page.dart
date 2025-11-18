import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sailing, size: 100, color: Colors.redAccent),
          const SizedBox(height: 20),
          const Text(
            'Bienvenido a One Piece Decks',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Explora cartas, crea mazos y domina los mares.',
          ),
        ],
      ),
    );
  }
}
