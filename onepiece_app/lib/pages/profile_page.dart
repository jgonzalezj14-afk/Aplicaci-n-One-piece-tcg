import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  final Color _woodColor = const Color(0xFF2D1E18);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _parchmentColor = const Color(0xFFFFF8E1);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      appBar: AppBar(
        title: const Text('MI CAMAROTE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: _parchmentColor, 
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF5D4037), width: 3),
            boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(4, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: _woodColor,
                child: Icon(Icons.person, size: 70, color: _goldColor),
              ),
              const SizedBox(height: 30),

              _buildProfileInfo("Usuario:", "Capitán Luffy"),
              _buildProfileInfo("Nombre:", "Monkey D. Luffy"),
              _buildProfileInfo("Contraseña:", "************"), 

              const SizedBox(height: 40),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pirateRed,
                  foregroundColor: _parchmentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: _goldColor, width: 2),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("¡Sesión cerrada! ¡Hasta la próxima, pirata!"))
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("CERRAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _woodColor, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: TextStyle(color: Colors.black87, fontSize: 16, fontFamily: 'serif')),
        ],
      ),
    );
  }
}