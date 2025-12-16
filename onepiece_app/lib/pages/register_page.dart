import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nicknameController = TextEditingController(); // Apodo
  final TextEditingController _fullNameController = TextEditingController(); // Nombre Completo
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  final Color _woodDark = const Color(0xFF3E2723);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _pirateRed = const Color(0xFFD32F2F);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_nicknameController.text.trim());
        
        await user.reload(); 
        user = FirebaseAuth.instance.currentUser;

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': "", 
        });

        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Bienvenido a bordo, pirata! Ya puedes entrar."), backgroundColor: Colors.green),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Error al registrarse";
      if (e.code == 'email-already-in-use') msg = "Ese correo ya está registrado.";
      if (e.code == 'weak-password') msg = "La contraseña es muy débil (mínimo 6 caracteres).";
      if (e.code == 'invalid-email') msg = "El correo no es válido.";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _pirateRed));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: _pirateRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        title: const Text("UNIRSE A LA TRIPULACIÓN"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.person_add_alt_1, size: 80, color: _goldColor),
                const SizedBox(height: 20),
                
                _buildTextField("Apodo (Nick)", _nicknameController, Icons.tag),
                const SizedBox(height: 15),
                
                _buildTextField("Nombre Real", _fullNameController, Icons.badge),
                const SizedBox(height: 15),
                
                _buildTextField("Correo Electrónico", _emailController, Icons.email),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v != null && v.length < 6) ? "Mínimo 6 caracteres" : null,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    labelStyle: TextStyle(color: _goldColor),
                    prefixIcon: Icon(Icons.lock, color: _goldColor),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

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
                    onPressed: _register,
                    child: const Text("CREAR CUENTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? "Campo requerido" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _goldColor),
        prefixIcon: Icon(icon, color: _goldColor),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor)),
      ),
    );
  }
}