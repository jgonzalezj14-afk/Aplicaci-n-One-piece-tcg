import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(
              'https://i.imgur.com/zL4Krbz.png', 
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Usuario One Piece',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.orangeAccent),
            title: const Text('Editar perfil',
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.orangeAccent),
            title: const Text('Cartas favoritas',
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
