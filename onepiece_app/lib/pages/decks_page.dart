import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../services/api_service.dart';

class DecksPage extends StatefulWidget {
  const DecksPage({super.key});

  @override
  State<DecksPage> createState() => _DecksPageState();
}

class _DecksPageState extends State<DecksPage> {
  final ApiService _apiService = ApiService();
  List<CardModel> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedColor = 'All';
  String _selectedType = 'All';

  DeckModel _currentDeck = DeckModel.empty();
  final TextEditingController _deckNameController = TextEditingController(text: "Nuevo Mazo");

  final Color _woodColor = const Color(0xFF2D1E18);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _parchmentColor = const Color(0xFFFFF8E1);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchCardsForSearch(); 
  }

  Future<void> _fetchCardsForSearch() async {
    if (!mounted) return; 
    setState(() => _isSearching = true);
    
    try {
      final result = await _apiService.getCardsPaginated(
        query: _searchQuery,
        color: _selectedColor,
        type: _selectedType,
        page: 1,
        pageSize: 100, 
      );
      
      if (mounted) {
        setState(() {
          _searchResults = result['cards'];
        });
      }
    } catch (e) {
      debugPrint("Error buscando cartas: $e");
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _addToDeck(CardModel card) {
    if (_currentDeck.count >= 50) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡La bodega está llena! Máximo 50 cartas.")));
       return;
    }
    setState(() {
      _currentDeck.cards.add(card);
    });
  }

  void _removeFromDeck(CardModel card) {
    setState(() {
      _currentDeck.cards.remove(card);
    });
  }

  void _saveDeck() {
    if (_currentDeck.count == 0) return;
    _currentDeck.name = _deckNameController.text;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _goldColor,
        content: Text("Mazo '${_currentDeck.name}' guardado en el cofre!", style: const TextStyle(color: Colors.black)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      appBar: AppBar(
        title: const Text('ASTILLERO DE MAZOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3, 
            child: _buildDeckSection(),
          ),
          const Divider(color: Colors.black, thickness: 3),
          Expanded(
            flex: 4,
            child: _buildSearchSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckSection() {
    return Container(
      color: _woodColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deckNameController,
                  style: TextStyle(color: _goldColor, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "Nombre del Mazo...",
                    hintStyle: TextStyle(color: _goldColor.withOpacity(0.5)),
                    border: InputBorder.none,
                    icon: Icon(Icons.edit, color: _goldColor),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _goldColor)
                ),
                child: Text("${_currentDeck.count} / 50 Cartas", style: TextStyle(color: _parchmentColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _pirateRed, foregroundColor: Colors.white),
                onPressed: _currentDeck.count > 0 ? _saveDeck : null,
                icon: const Icon(Icons.save),
                label: const Text("GUARDAR"),
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                 border: Border.all(color: _goldColor.withOpacity(0.3))
              ),
              child: _currentDeck.count == 0 
                ? Center(child: Text("¡Tu mazo está vacío! Añade cartas desde abajo.", style: TextStyle(color: _parchmentColor.withOpacity(0.5))))
                : ListView.builder(
                    scrollDirection: Axis.horizontal, 
                    itemCount: _currentDeck.cards.length,
                    itemBuilder: (context, index) {
                      final card = _currentDeck.cards[index];
                      return GestureDetector(
                        onTap: () => _removeFromDeck(card),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          width: 80,
                          child: Image.network(
                            card.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => Container(color: Colors.grey, child: const Icon(Icons.broken_image)),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: const Color(0xFF4E342E), 
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              IconButton(
                onPressed: _fetchCardsForSearch, 
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle),
                  child: const Icon(Icons.search, color: Colors.black)
                )
              )
            ],
          ),
          _buildFilters(),
          const SizedBox(height: 10),
          Expanded(
            child: _isSearching 
              ? Center(child: CircularProgressIndicator(color: _goldColor))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, 
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final card = _searchResults[index];
                    return GestureDetector(
                      onTap: () => _addToDeck(card),
                      child: Image.network(
                        card.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(color: _parchmentColor, child: const Center(child: Icon(Icons.broken_image))),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Buscar para añadir...',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.add_circle_outline, color: Colors.white54),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
        onSubmitted: (val) { 
          _searchQuery = val; 
          _fetchCardsForSearch(); 
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: _buildDropdown(_selectedType, ['All', 'Leader', 'Character', 'Event', 'Stage'], (val) { setState(() => _selectedType = val!); _fetchCardsForSearch(); })),
          const SizedBox(width: 10),
          Expanded(child: _buildDropdown(_selectedColor, ['All', 'Red', 'Blue', 'Green', 'Purple', 'Black', 'Yellow'], (val) { setState(() => _selectedColor = val!); _fetchCardsForSearch(); })),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _goldColor.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _woodColor,
          icon: Icon(Icons.arrow_drop_down, color: _goldColor),
          style: TextStyle(color: _parchmentColor, fontWeight: FontWeight.bold, fontSize: 12),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}