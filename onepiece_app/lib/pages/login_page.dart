import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true; 
  bool _isLoading = false;

  final Color _woodDark = const Color(0xFF3E2723);
  final Color _goldColor = const Color(0xFFFFC107);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      String message = "Ocurrió un error inesperado.";
      
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Usuario no encontrado o contraseña incorrecta.";
      } else if (e.code == 'wrong-password') {
        message = "Contraseña incorrecta.";
      } else if (e.code == 'invalid-email') {
        message = "El formato del email no es válido.";
      } else if (e.code == 'too-many-requests') {
        message = "Demasiados intentos. Intenta más tarde.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    String email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escribe tu email arriba para recuperar la contraseña."), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Correo enviado a $email. Revisa tu spam."), 
            backgroundColor: Colors.green
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        title: const Text("INICIAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.anchor, size: 80, color: _goldColor),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  labelStyle: TextStyle(color: _goldColor),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  prefixIcon: Icon(Icons.email, color: _goldColor),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(color: _goldColor),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  prefixIcon: Icon(Icons.lock, color: _goldColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    "¿Olvidaste tu contraseña?", 
                    style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: _goldColor))
                : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _login,
                  child: const Text("ENTRAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}