import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async'; 
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  User? _currentUser;
  
  final TextEditingController _usernameController = TextEditingController(); 
  final TextEditingController _fullNameController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  File? _pendingImageFile;

  final Color _woodDark = const Color(0xFF3E2723);
  final Color _woodLight = const Color(0xFF4E342E);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    
    _usernameController.text = _currentUser?.displayName ?? "";
    _emailController.text = _currentUser?.email ?? "";
    _passwordController.text = "";
    _confirmPasswordController.text = ""; 
    _pendingImageFile = null;

    try {
      var data = await _dbService.getUserData(_currentUser!.uid);
      if (data != null && mounted) {
        setState(() {
          _fullNameController.text = data['fullName'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70, 
      maxWidth: 512, 
      maxHeight: 512
    );
    
    if (image == null) return;

    setState(() {
      _pendingImageFile = File(image.path);
    });
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;
    
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Las contraseñas no coinciden!"), backgroundColor: Colors.orange));
        return;
      }
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      if (_pendingImageFile != null) {
        String downloadUrl = await _dbService.uploadProfileImage(_currentUser!.uid, XFile(_pendingImageFile!.path));
        await _currentUser!.updatePhotoURL(downloadUrl);
      }

      await _authService.updateAuthProfile(
        displayName: _usernameController.text.trim(),
        newPassword: _passwordController.text.trim()
      );

      await _dbService.updateUserData(
        _currentUser!.uid,
        fullName: _fullNameController.text.trim(),
      );

      await _authService.reloadUser();
      
      if (mounted) {
        setState(() {
           _currentUser = _authService.currentUser;
           _isEditing = false;
           _pendingImageFile = null;
           _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cambios guardados correctamente"), backgroundColor: Colors.green));
      }

    } on FirebaseAuthException catch (e) {
      String feedback = "Error: ${e.message}";
      if (e.code == 'requires-recent-login') {
        feedback = "Por seguridad, cierra sesión y vuelve a entrar para cambiar datos sensibles.";
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback), backgroundColor: _pirateRed));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: _pirateRed));
      }
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/login_bg.jpg",
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.black),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_circle, size: 80, color: _goldColor),
                  const SizedBox(height: 20),
                  const Text("Identifícate, pirata.", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldColor, 
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                    child: const Text("INICIAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _woodDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        title: const Text("CAMAROTE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: "Abandonar barco"),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1E18),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _goldColor, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildAvatarWidget(),
                  const SizedBox(height: 15),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          if (_isEditing) _loadUserData(); 
                          setState(() => _isEditing = !_isEditing);
                        },
                        icon: Icon(_isEditing ? Icons.close : Icons.edit_note, color: _isEditing ? _pirateRed : _goldColor),
                        label: Text(_isEditing ? "CANCELAR" : "EDITAR PERFIL", style: TextStyle(color: _isEditing ? _pirateRed : _goldColor)),
                      )
                    ],
                  ),
                  
                  _buildField("Apodo", _usernameController, Icons.tag, _isEditing),
                  const SizedBox(height: 10),
                  _buildField("Nombre Real", _fullNameController, Icons.badge, _isEditing),
                  const SizedBox(height: 10),
                  _buildField("Correo", _emailController, Icons.email, false),
                  const SizedBox(height: 10),

                  if (_isEditing)
                    Column(
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePass,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Nueva Contraseña",
                            labelStyle: TextStyle(color: _goldColor),
                            prefixIcon: Icon(Icons.lock_outline, color: _goldColor),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _goldColor)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPass,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Confirmar Contraseña",
                            labelStyle: TextStyle(color: _goldColor),
                            prefixIcon: Icon(Icons.lock_reset, color: _goldColor),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _goldColor)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPass ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading 
                      ? Center(child: CircularProgressIndicator(color: _goldColor))
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _updateProfile,
                        child: const Text("GUARDAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: _goldColor),
                  const SizedBox(width: 10),
                  const Text("MIS TESOROS (MAZOS)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getUserDecksStream(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _goldColor));
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(10)),
                    child: const Column(
                      children: [
                        Icon(Icons.map_outlined, size: 50, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text("Aún no tienes mapas del tesoro.", style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    List cards = data['cards'] ?? [];
                    String leaderName = (data['leader'] != null) ? data['leader']['card_name'] : "Sin Líder";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: _woodLight,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.description, color: _goldColor),
                        ),
                        title: Text(data['name'] ?? "Mazo Desconocido", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("$leaderName • ${cards.length} cartas", style: const TextStyle(color: Colors.white54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _woodDark,
        title: const Text("¿Quemar este mapa?", style: TextStyle(color: Colors.white)),
        content: const Text("El mazo se perderá para siempre.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () {
            _dbService.deleteDeck(_currentUser!.uid, docId);
            Navigator.pop(c);
          }, child: const Text("Borrar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool isEditing) {
    return TextField(
      controller: controller,
      enabled: isEditing,
      style: TextStyle(color: isEditing ? Colors.white : Colors.white70, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _goldColor),
        prefixIcon: Icon(icon, color: _goldColor, size: 20),
        filled: isEditing,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: isEditing ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)) : InputBorder.none,
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor)),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final String? photoUrl = _currentUser?.photoURL;
    
    ImageProvider? imageProvider;
    if (_pendingImageFile != null) {
      imageProvider = FileImage(_pendingImageFile!);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
    }

    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _goldColor,
              border: Border.all(color: _goldColor, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))]
            ),
            child: ClipOval(
              child: imageProvider != null
                ? Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator(color: _woodDark));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image, size: 50, color: _woodDark.withOpacity(0.5));
                    },
                  )
                : Icon(Icons.person, size: 65, color: _woodDark),
            ),
          ),

          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle, border: Border.all(color: _woodDark, width: 2)),
                child: Icon(Icons.camera_alt, size: 22, color: _woodDark),
              ),
            )
        ],
      ),
    );
  }
}