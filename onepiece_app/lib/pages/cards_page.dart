import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
import 'card_detail_page.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  final ApiService _apiService = ApiService();
  
  String _searchQuery = '';
  String _selectedColor = 'All';
  String _selectedType = 'All';

  List<CardModel> _cards = [];
  bool _isLoading = false;
  int _page = 1;
  int _totalPages = 1;

  final Color _woodColor = const Color(0xFF2D1E18); 
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _parchmentColor = const Color(0xFFFFF8E1);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getCardsPaginated(
        query: _searchQuery,
        color: _selectedColor,
        type: _selectedType,
        page: _page,
      );
      setState(() {
        _cards = result['cards'];
        _totalPages = result['totalPages'];
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _page = page);
    _fetchCards();
  }


  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Buscar carta...',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: (val) { 
          _searchQuery = val; 
          _page = 1; 
          _fetchCards(); 
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              _selectedType, 
              ['All', 'Leader', 'Character', 'Event', 'Stage'], 
              (val) {
                setState(() => _selectedType = val!);
                _page = 1;
                _fetchCards();
              }
            )
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDropdown(
              _selectedColor, 
              ['All', 'Red', 'Blue', 'Green', 'Purple', 'Black', 'Yellow'], 
              (val) {
                setState(() => _selectedColor = val!);
                _page = 1;
                _fetchCards();
              }
            )
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          style: TextStyle(color: _parchmentColor, fontWeight: FontWeight.bold),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: _goldColor));
    if (_cards.isEmpty) return const Center(child: Text('Sin resultados', style: TextStyle(color: Colors.white)));

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailPage(card: card))),
          
          child: Container(
            decoration: BoxDecoration(
              color: _parchmentColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))],
              border: Border.all(color: const Color(0xFF5D4037), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: _pirateRed,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    "WANTED",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black87, fontFamily: 'serif', fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Divider(color: Colors.black26, thickness: 1, indent: 10, endIndent: 10),
                        const SizedBox(height: 4),
                        Text(
                          card.type,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[800], fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          card.color,
                          style: TextStyle(color: Colors.grey[600], fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  color: const Color(0xFFD7CCC8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card.cardNumber, style: TextStyle(fontSize: 8, color: Colors.grey[900], fontWeight: FontWeight.bold)),
                      Text("P: ${card.power}", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    List<Widget> pageButtons = [];
    
    pageButtons.add(IconButton(
      icon: const Icon(Icons.chevron_left, color: Colors.white),
      onPressed: _page > 1 ? () => _goToPage(_page - 1) : null,
    ));

    for (int i = 0; i < 4; i++) {
      int p = _page + i;
      if (p > _totalPages) break;
      pageButtons.add(
        GestureDetector(
          onTap: () => _goToPage(p),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 35, height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p == _page ? _goldColor : Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p == _page ? _goldColor : Colors.white24),
            ),
            child: Text("$p", style: TextStyle(color: p == _page ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      );
    }

    pageButtons.add(IconButton(
      icon: const Icon(Icons.chevron_right, color: Colors.white),
      onPressed: _page < _totalPages ? () => _goToPage(_page + 1) : null,
    ));

    return Container(
      height: 60,
      color: Colors.black26,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: pageButtons),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      appBar: AppBar(
        title: const Text('ONE PIECE DECKS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(), 
          Expanded(child: _buildGrid()),
          _buildPagination(),
        ],
      ),
    );
  }
}