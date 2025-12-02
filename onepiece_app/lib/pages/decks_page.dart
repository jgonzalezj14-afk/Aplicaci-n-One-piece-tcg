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
  final ScrollController _deckScrollController = ScrollController();
  final ScrollController _searchScrollController = ScrollController();
  
  DeckModel _currentDeck = DeckModel();
  
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
  }

  @override
  void dispose() {
    _deckScrollController.dispose();
    _searchScrollController.dispose();
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
      print(e);
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

  Widget _buildCardStack(List<CardModel> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final firstCard = cards.first;
    final count = cards.length;

    return GestureDetector(
      onTap: () => _removeCardFromDeck(firstCard),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (count > 1)
            Positioned(top: 3, left: 3, right: -3, bottom: -3, child: Opacity(opacity: 0.6, child: _buildCardImage(firstCard.imageUrl))),
          if (count > 2)
            Positioned(top: 6, left: 6, right: -6, bottom: -6, child: Opacity(opacity: 0.4, child: _buildCardImage(firstCard.imageUrl))),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 3)]
            ),
            child: _buildCardImage(firstCard.imageUrl),
          ),
          
          Positioned(
            bottom: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87, 
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: _goldColor, width: 1)
              ),
              child: Text(
                "x$count", 
                style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        url, 
        fit: BoxFit.cover,
        errorBuilder: (c,e,s) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white)),
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
                const Icon(Icons.anchor, color: Colors.white54, size: 28),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: _goldColor, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Nombre del Mazo...",
                      hintStyle: TextStyle(color: _goldColor.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 8)
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentDeck.totalCards == 50 ? Colors.green[800] : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _goldColor),
                  ),
                  child: Text("${_currentDeck.totalCards}/50", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(Icons.save, size: 22),
                  label: const Text("GUARDAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pirateRed, 
                    foregroundColor: _parchmentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              ],
            ),
          ),
          Divider(color: _goldColor.withOpacity(0.3), height: 15, thickness: 2),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text("LÍDER", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _currentDeck.leader != null ? () => _removeCardFromDeck(_currentDeck.leader!) : null,
                      child: Container(
                        width: 150, 
                        height: 210, 
                        margin: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: _goldColor, width: 4), 
                          borderRadius: BorderRadius.circular(10), 
                          color: Colors.black26,
                          boxShadow: [BoxShadow(color: _goldColor.withOpacity(0.3), blurRadius: 20)]
                        ),
                        child: _currentDeck.leader == null
                            ? Center(child: Icon(Icons.person_add, color: _goldColor.withOpacity(0.5), size: 60))
                            : ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.network(_currentDeck.leader!.imageUrl, fit: BoxFit.cover)),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10)
                    ),
                    child: RawScrollbar(
                      thumbVisibility: true,
                      controller: _deckScrollController,
                      thumbColor: _goldColor.withOpacity(0.6),
                      thickness: 10,
                      radius: const Radius.circular(10),
                      child: GridView.count(
                        controller: _deckScrollController,
                        crossAxisCount: 8, 
                        scrollDirection: Axis.vertical, 
                        childAspectRatio: 0.72, 
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        padding: const EdgeInsets.all(10),
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
                  thickness: 10,
                  radius: const Radius.circular(10),
                  trackVisibility: true,
                  trackColor: Colors.black26,
                  child: GridView.builder(
                    controller: _searchScrollController,
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10, 
                      childAspectRatio: 0.7, 
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final card = _searchResults[index];
                      return GestureDetector(
                        onTap: () => _addCardToDeck(card),
                        child: Tooltip(
                          message: "${card.name} (Coste: ${card.cost})",
                          child: Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(3)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2), 
                                child: Image.network(card.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey))
                              )
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _woodDark,
          hint: Text(hint, style: TextStyle(color: Colors.white54, fontSize: 12)),
          icon: Icon(Icons.arrow_drop_down, color: _goldColor, size: 20),
          style: TextStyle(color: _parchmentColor, fontWeight: FontWeight.bold, fontSize: 12),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(flex: 6, child: _buildDeckArea()),
          Container(height: 6, color: _goldColor), 
          Expanded(flex: 4, child: _buildSearchArea()),
        ],
      ),
    );
  }
}