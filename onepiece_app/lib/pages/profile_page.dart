import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  
  final TextEditingController _usernameController = TextEditingController(); 
  final TextEditingController _fullNameController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingImage = false; 
  bool _obscurePass = true;

  final Color _woodDark = const Color(0xFF3E2723);
  final Color _woodLight = const Color(0xFF4E342E);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    
    _usernameController.text = _currentUser?.displayName ?? "";
    _emailController.text = _currentUser?.email ?? "";
    _passwordController.text = "";

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error cargando perfil extendido: $e");
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70, 
      maxWidth: 512, 
      maxHeight: 512
    );
    
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${_currentUser!.uid}.jpg');
      
      final bytes = await image.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      
      final uploadTask = storageRef.putData(bytes, metadata);

      await uploadTask;

      String downloadUrl = await storageRef.getDownloadURL();
      downloadUrl = "$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      await _currentUser!.updatePhotoURL(downloadUrl);
      
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'photoUrl': downloadUrl
      }, SetOptions(merge: true));

      await _currentUser!.reload();
      setState(() {
        _currentUser = FirebaseAuth.instance.currentUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Foto actualizada con éxito!"), backgroundColor: Colors.green));
      }

    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al subir: $e"), backgroundColor: _pirateRed));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Widget _buildAvatarWidget() {
    final String? photoUrl = _currentUser?.photoURL;
    
    return GestureDetector(
      onTap: _isEditing ? _uploadImage : null,
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
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
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

          if (_isUploadingImage)
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const CircularProgressIndicator(color: Colors.white),
            ),

          if (_isEditing && !_isUploadingImage)
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

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    String feedback = "";
    bool success = true;

    try {
      if (_usernameController.text.trim() != _currentUser!.displayName) {
        await _currentUser!.updateDisplayName(_usernameController.text.trim());
        feedback += "Apodo actualizado. ";
      }

      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'fullName': _fullNameController.text.trim(),
        'email': _currentUser!.email,
      }, SetOptions(merge: true));

      if (_emailController.text.trim().isNotEmpty && _emailController.text.trim() != _currentUser!.email) {
        await _currentUser!.verifyBeforeUpdateEmail(_emailController.text.trim());
        feedback += "Revisa tu nuevo correo. ";
      }

      if (_passwordController.text.isNotEmpty) {
        await _currentUser!.updatePassword(_passwordController.text.trim());
        feedback += "Contraseña cambiada. ";
      }

      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser;
      setState(() => _isEditing = false);
      
      if (feedback.isEmpty) feedback = "Datos guardados correctamente.";

    } on FirebaseAuthException catch (e) {
      success = false;
      if (e.code == 'requires-recent-login') {
        feedback = "Por seguridad, cierra sesión y vuelve a entrar para cambiar datos sensibles.";
      } else {
        feedback = "Error: ${e.message}";
      }
    } catch (e) {
      success = false;
      feedback = "Error: $e";
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(feedback), 
          backgroundColor: success ? Colors.green : _pirateRed
        ));
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: _woodDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_circle, size: 80, color: _goldColor.withOpacity(0.5)),
              const SizedBox(height: 20),
              const Text("Identifícate, pirata.", style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _goldColor, foregroundColor: Colors.black),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())).then((_) { 
                   setState(() { _currentUser = FirebaseAuth.instance.currentUser; });
                   _loadUserData(); 
                }),
                child: const Text("INICIAR SESIÓN"),
              )
            ],
          ),
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
                  _buildField("Correo", _emailController, Icons.email, _isEditing),
                  const SizedBox(height: 10),

                  if (_isEditing)
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
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('decks')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
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
                        SizedBox(height: 10),
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
        content: const Text("El mazo se perderá para siempre en el fondo del mar.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () {
            FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('decks').doc(docId).delete();
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
}