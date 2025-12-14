import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLogin = true; 
  bool _isLoading = false;

  final Color _woodColor = const Color(0xFF2D1E18);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _pirateRed = const Color(0xFFD32F2F);

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'username': _usernameController.text.trim(),
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (mounted) {
        Navigator.pop(context);
      }
      
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.message ?? "Error desconocido en alta mar");
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError("Error: $e");
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showError("Escribe tu correo primero para enviarte el pergamino de recuperación.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("¡Correo enviado! Revisa tu bandeja de entrada."), backgroundColor: Colors.green),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "No se pudo enviar el correo");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: _pirateRed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      appBar: AppBar(
        title: Text(_isLogin ? "INICIAR TRAVESÍA" : "NUEVO PIRATA", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isLogin ? Icons.lock_open : Icons.person_add, size: 60, color: _goldColor),
              const SizedBox(height: 20),

              if (!_isLogin) ...[
                _buildTextField(_usernameController, "Nombre de Usuario", Icons.alternate_email),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_firstNameController, "Nombre", Icons.badge)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_lastNameController, "Apellido", Icons.badge_outlined)),
                  ],
                ),
                const SizedBox(height: 15),
              ],

              _buildTextField(_emailController, "Correo Electrónico", Icons.email),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Contraseña", Icons.key, isPassword: true),
              
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldColor,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black))
                    : Text(_isLogin ? "ABRIR COMPUERTAS" : "UNIRSE A LA TRIPULACIÓN"),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                   setState(() {
                     _isLogin = !_isLogin;
                   });
                },
                child: Text(
                  _isLogin 
                    ? "¿Aún no tienes cuenta? Regístrate aquí" 
                    : "¿Ya tienes cuenta? Inicia sesión",
                  style: const TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor, width: 2)),
        prefixIcon: Icon(icon, color: _goldColor),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }
}