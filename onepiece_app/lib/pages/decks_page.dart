import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class DecksPage extends StatefulWidget {
  const DecksPage({super.key});

  @override
  State<DecksPage> createState() => _DecksPageState();
}

class _DecksPageState extends State<DecksPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _deckScrollController = ScrollController();
  final ScrollController _searchScrollController = ScrollController();
  final TextEditingController _deckNameController = TextEditingController();

  DeckModel _currentDeck = DeckModel();
  User? _currentUser;

  String _searchQuery = '';
  String _selectedColor = 'All';
  String _selectedType = 'All';

  List<CardModel> _searchResults = [];
  bool _isLoading = false;

  final Color _woodDark = const Color(0xFF3E2723);
  final Color _woodLight = const Color(0xFF5D4037);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _parchmentColor = const Color(0xFFFFF8E1);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchCardsForSearch();
    _currentUser = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _deckScrollController.dispose();
    _searchScrollController.dispose();
    _deckNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchCardsForSearch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getCardsPaginated(
        query: _searchQuery,
        color: _selectedColor,
        type: _selectedType,
        page: 1,
        pageSize: 300,
      );

      if (mounted) {
        List<CardModel> rawCards = result['cards'];
        final Map<String, CardModel> uniqueCards = {};
        for (var card in rawCards) {
          if (!uniqueCards.containsKey(card.cardNumber)) {
            uniqueCards[card.cardNumber] = card;
          }
        }
        setState(() => _searchResults = uniqueCards.values.toList());
      }
    } catch (e) {
      debugPrint("Error buscando cartas: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addCardToDeck(CardModel card) {
    String? error = _currentDeck.addCard(card);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: _pirateRed));
    } else {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_deckScrollController.hasClients) {
          _deckScrollController.animateTo(
            _deckScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _removeCardFromDeck(CardModel card) {
    setState(() {
      _currentDeck.removeCard(card);
    });
  }

  void _clearDeck() {
    setState(() {
      _currentDeck.clear();
      _deckNameController.clear();
    });
  }

  Future<void> _importFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Portapapeles vacío")));
      return;
    }

    String text = data.text!;
    Map<String, int> cardsToImport = {}; 

    List<String> lines = text.split('\n');
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final regexSimple = RegExp(r'^(\d+)x\s?([A-Z0-9-]+)$');
      int quantity = 1;
      String id = "";

      if (regexSimple.hasMatch(line)) {
        final match = regexSimple.firstMatch(line)!;
        quantity = int.parse(match.group(1)!);
        id = match.group(2)!;
      } else {
        final regexID = RegExp(r'([A-Z]+[0-9]+-[0-9]+)');
        if (regexID.hasMatch(line)) {
          id = regexID.firstMatch(line)!.group(1)!;
          final regexQty = RegExp(r'^(\d+)x');
          if (regexQty.hasMatch(line)) {
            quantity = int.parse(regexQty.firstMatch(line)!.group(1)!);
          }
        }
      }

      if (id.isNotEmpty) {
        cardsToImport[id] = quantity;
      }
    }

    if (cardsToImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se detectaron cartas válidas.")));
      return;
    }

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      List<String> idsToFetch = cardsToImport.keys.toList();
      List<CardModel> fetchedCards = await _apiService.getCardsByIds(idsToFetch);

      Set<String> foundIds = fetchedCards.map((c) => c.cardNumber).toSet();
      List<String> missingIds = idsToFetch.where((id) => !foundIds.contains(id)).toList();

      _clearDeck(); 
      int addedCount = 0;

      for (var card in fetchedCards) {
        int qty = cardsToImport[card.cardNumber] ?? 1;
        if (card.type.toLowerCase().contains('leader')) {
           _currentDeck.leader = card;
        } else {
           for (int i = 0; i < qty; i++) {
             _currentDeck.cards.add(card); 
             addedCount++;
           }
        }
      }
      _currentDeck.cards.sort((a, b) => a.costValue.compareTo(b.costValue));

      Navigator.pop(context); 
      setState(() {}); 

      if (missingIds.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _woodDark,
            title: const Text("Importación con Avisos", style: TextStyle(color: Colors.orange)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("✅ Se han añadido $addedCount cartas correctamente.", style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 15),
                  const Text("⚠️ No se encontraron estas cartas por falta de información en la api:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(5)),
                    width: double.infinity,
                    child: Text(missingIds.join('\n'), style: TextStyle(color: _pirateRed, fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Éxito! $addedCount cartas importadas."), backgroundColor: Colors.green));
      }

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error importando: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveDeckToFirebase() async {
    if (_currentUser == null) {
      _showLoginRequiredDialog("guardar mazos");
      return;
    }

    if (_currentDeck.leader == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Falta el Capitán! Elige un Líder."), backgroundColor: Colors.orange));
      return;
    }
    if (_deckNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ponle nombre al mazo!"), backgroundColor: Colors.orange));
      return;
    }

    if (_currentDeck.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡El mazo está vacío!"), backgroundColor: Colors.orange));
      return;
    }

    _currentDeck.name = _deckNameController.text.trim();

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.amber)));

      final decksRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('decks');

      if (_currentDeck.id != null) {
        await decksRef.doc(_currentDeck.id).update(_currentDeck.toMap());
      } else {
        DocumentReference docRef = await decksRef.add(_currentDeck.toMap());
        _currentDeck.id = docRef.id;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mazo '${_currentDeck.name}' guardado!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: _pirateRed));
    }
  }

  void _showLoadDecksDialog() {
    if (_currentUser == null) {
      _showLoginRequiredDialog("cargar mazos");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _woodDark,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text("MIS MAZOS GUARDADOS", style: TextStyle(color: _goldColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser!.uid)
                      .collection('decks')
                      .orderBy('updatedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _goldColor));
                    var docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Center(child: Text("No tienes mazos guardados.", style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        String docId = docs[index].id;
                        String name = data['name'] ?? "Sin nombre";
                        int count = (data['cards'] as List).length;
                        return Card(
                          color: Colors.black45,
                          child: ListTile(
                            leading: const Icon(Icons.layers, color: Colors.white),
                            title: Text(name, style: TextStyle(color: _goldColor)),
                            subtitle: Text("$count cartas", style: const TextStyle(color: Colors.white54)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('decks').doc(docId).delete();
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _currentDeck = DeckModel.fromMap(data, docId);
                                _deckNameController.text = _currentDeck.name;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard() async {
    String data = _currentDeck.toClipboardString();
    await Clipboard.setData(ClipboardData(text: data));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Copiado al portapapeles"), backgroundColor: _goldColor.withOpacity(0.8)));
  }

  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _woodDark,
        title: Text("Identificación Requerida", style: TextStyle(color: _goldColor)),
        content: Text("Para $action, necesitas estar registrado.", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _goldColor, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: const Text("Iniciar Sesión"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        title: const Text("CONSTRUCTOR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _clearDeck, icon: const Icon(Icons.delete_sweep), tooltip: "Limpiar"),
          IconButton(onPressed: _showLoadDecksDialog, icon: const Icon(Icons.folder_open), tooltip: "Cargar"),
          IconButton(onPressed: _copyToClipboard, icon: const Icon(Icons.copy), tooltip: "Copiar Texto"),
          IconButton(onPressed: _importFromClipboard, icon: const Icon(Icons.paste), tooltip: "Importar"),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 6, child: _buildDeckArea()),
          Container(height: 6, color: _goldColor),
          Expanded(flex: 4, child: _buildSearchArea()),
        ],
      ),
    );
  }

  Widget _buildDeckArea() {
    Map<String, List<CardModel>> groupedCards = {};
    for (var card in _currentDeck.cards) {
      if (!groupedCards.containsKey(card.cardNumber)) groupedCards[card.cardNumber] = [];
      groupedCards[card.cardNumber]!.add(card);
    }

    return Container(
      color: _woodDark,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 45,
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.white54, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _deckNameController,
                    style: TextStyle(color: _goldColor, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Nombre del Mazo...",
                      hintStyle: TextStyle(color: _goldColor.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 12),
                    ),
                    onChanged: (val) => _currentDeck.name = val,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentDeck.totalCards == 50 ? Colors.green[800] : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _goldColor),
                  ),
                  child: Text("${_currentDeck.totalCards}/50", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saveDeckToFirebase,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text("GUARDAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pirateRed,
                    foregroundColor: _parchmentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  ),
                )
              ],
            ),
          ),
          Divider(color: _goldColor.withOpacity(0.3), height: 15, thickness: 2),
          Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("LÍDER", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _currentDeck.leader != null ? () => _removeCardFromDeck(_currentDeck.leader!) : null,
                      child: Container(
                        width: 120,
                        height: 170,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: _goldColor, width: 4),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black26,
                          boxShadow: [BoxShadow(color: _goldColor.withOpacity(0.3), blurRadius: 20)]
                        ),
                        child: _currentDeck.leader == null
                            ? Center(child: Icon(Icons.person_add, color: _goldColor.withOpacity(0.5), size: 50))
                            : ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.network(_currentDeck.leader!.imageUrl, fit: BoxFit.cover)),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                    child: RawScrollbar(
                      thumbVisibility: true,
                      controller: _deckScrollController,
                      thumbColor: _goldColor.withOpacity(0.6),
                      thickness: 8,
                      radius: const Radius.circular(10),
                      child: GridView.count(
                        controller: _deckScrollController,
                        crossAxisCount: 7,
                        childAspectRatio: 0.7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        padding: const EdgeInsets.all(8),
                        children: groupedCards.values.map((list) => _buildCardStack(list)).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(List<CardModel> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final firstCard = cards.first;
    final count = cards.length;
    return GestureDetector(
      onTap: () => _removeCardFromDeck(firstCard),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (count > 1) Positioned(top: 2, left: 2, right: -2, bottom: -2, child: Opacity(opacity: 0.6, child: _buildCardImage(firstCard.imageUrl))),
          if (count > 2) Positioned(top: 4, left: 4, right: -4, bottom: -4, child: Opacity(opacity: 0.4, child: _buildCardImage(firstCard.imageUrl))),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(4), boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 3)]),
            child: _buildCardImage(firstCard.imageUrl),
          ),
          Positioned(
            bottom: 2, right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4), border: Border.all(color: _goldColor, width: 1)),
              child: Text("x$count", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardImage(String url) => ClipRRect(borderRadius: BorderRadius.circular(3), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey[800])));

  Widget _buildSearchArea() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: Colors.black87,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "Buscar...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.white, size: 22),
                      contentPadding: EdgeInsets.only(bottom: 8),
                    ),
                    onSubmitted: (val) { _searchQuery = val; _fetchCardsForSearch(); },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown(_selectedType, ['All', 'Leader', 'Character', 'Event', 'Stage'], 'Tipo', (v) { setState(() => _selectedType = v!); _fetchCardsForSearch(); })),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown(_selectedColor, ['All', 'Red', 'Blue', 'Green', 'Purple', 'Black', 'Yellow'], 'Color', (v) { setState(() => _selectedColor = v!); _fetchCardsForSearch(); })),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: _woodLight,
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: _goldColor))
              : RawScrollbar(
                  thumbVisibility: true,
                  controller: _searchScrollController,
                  thumbColor: _goldColor.withOpacity(0.8),
                  thickness: 8,
                  radius: const Radius.circular(10),
                  child: GridView.builder(
                    controller: _searchScrollController,
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 0.7, 
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final card = _searchResults[index];
                      return GestureDetector(
                        onTap: () => _addCardToDeck(card),
                        child: Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(3)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2), 
                              child: Image.network(card.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey))
                            )
                        ),
                      );
                    },
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String value, List<String> items, String hint, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      height: 40,
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _woodDark,
          icon: Icon(Icons.arrow_drop_down, color: _goldColor, size: 20),
          style: TextStyle(color: _parchmentColor, fontWeight: FontWeight.bold, fontSize: 11),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}