import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  final Color _woodColor = const Color(0xFF2D1E18);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _parchmentColor = const Color(0xFFFFF8E1);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        if (snapshot.hasData) {
          return Scaffold(
            backgroundColor: _woodColor,
            appBar: AppBar(title: const Text("MI CAMAROTE"), backgroundColor: Colors.black, foregroundColor: _goldColor, centerTitle: true),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  Text("¡Bienvenido, ${snapshot.data!.email}!", style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Cerrar Sesión (Temporal)", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _woodColor,
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/eb03.jpg"), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_pin, size: 100, color: _goldColor),
                  const SizedBox(height: 30),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _goldColor.withOpacity(0.5)),
                    ),
                    child: const Text(
                      "Inicia sesión para poder crear tus mazos, guardarlos y modificarlos cuando quieras, y si aún no tienes cuenta regístrate.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text("INICIAR SESIÓN / REGISTRARSE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldColor,
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        elevation: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}