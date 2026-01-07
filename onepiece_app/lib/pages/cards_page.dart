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
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  
  String _selectedColor = 'All Colors';
  String _selectedType = 'All Types';
  String _selectedSet = 'All Sets';
  String _selectedCost = 'All Costs';

  final List<String> _sets = [
    'All Sets', 'OP-01', 'OP-02', 'OP-03', 'OP-04', 'OP-05', 
    'OP-06', 'OP-07', 'OP-08', 'OP-09', 'OP-10', 'OP-11', 'OP-12', 'OP-13','RB-01', 'EB-01', 'EB-02', 'P', 'ST','PRB01','PRB02'
  ];

  final List<String> _types = ['All Types', 'Leader', 'Character', 'Event', 'Stage'];
  final List<String> _colors = ['All Colors', 'Red', 'Blue', 'Green', 'Purple', 'Black', 'Yellow'];
  final List<String> _costs = ['All Costs', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

  List<CardModel> _cards = [];
  bool _isLoading = false;
  int _page = 1;
  int _totalPages = 1;

  final Color _woodColor = const Color(0xFF2D1E18); 
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _parchmentColor = const Color(0xFFFFF8E1); 
  final Color _activePageColor = const Color(0xFF4FC3F7); 

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCards() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getCardsPaginated(
        query: _searchQuery,
        color: _selectedColor,
        type: _selectedType,
        set: _selectedSet,
        cost: _selectedCost,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _cards = result['cards'];
          _totalPages = result['totalPages'];
        });
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
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
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Buscar carta...', hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none, prefixIcon: Icon(Icons.search, color: Colors.white54), contentPadding: EdgeInsets.symmetric(vertical: 15)),
        onSubmitted: (val) { _searchQuery = val; _page = 1; _fetchCards(); },
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, String hint, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8), border: Border.all(color: _goldColor.withOpacity(0.5))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, hint: Text(hint, style: TextStyle(color: Colors.white54)), dropdownColor: _woodColor, icon: Icon(Icons.arrow_drop_down, color: _goldColor), style: TextStyle(color: _parchmentColor, fontWeight: FontWeight.bold, fontSize: 12),
          items: items.toSet().toList().map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Column(
        children: [
          Row(children: [
            Expanded(flex: 3, child: _buildDropdown(_selectedType, _types, 'Tipo', (v) { setState(() => _selectedType = v!); _page=1; _fetchCards(); })), 
            const SizedBox(width: 10), 
            Expanded(flex: 2, child: _buildDropdown(_selectedColor, _colors, 'Color', (v) { setState(() => _selectedColor = v!); _page=1; _fetchCards(); }))
          ]),
          const SizedBox(height: 10),
          Row(children: [
             Expanded(flex: 3, child: _buildDropdown(_selectedSet, _sets, 'Colección', (v) { setState(() => _selectedSet = v!); _page=1; _fetchCards(); })),
             const SizedBox(width: 10),
             Expanded(flex: 2, child: _buildDropdown(_selectedCost, _costs, 'Coste', (v) { setState(() => _selectedCost = v!); _page=1; _fetchCards(); })),
          ]),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: _goldColor));
    if (_cards.isEmpty) return const Center(child: Text('Sin resultados', style: TextStyle(color: Colors.white)));
    return RawScrollbar(
      thumbVisibility: true, controller: _scrollController, thumbColor: _goldColor.withOpacity(0.8), thickness: 10, radius: const Radius.circular(20), trackVisibility: true, trackColor: Colors.black26,
      child: GridView.builder(
        controller: _scrollController, padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12, right: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.70),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailPage(card: card))),
            child: Hero(
              tag: card.id,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), 
                    boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))], 
                    image: DecorationImage(
                        image: NetworkImage('https://images.weserv.nl/?url=${card.imageUrl}'), 
                        fit: BoxFit.cover, 
                        onError: (e,s) {}
                    ), 
                    color: Colors.grey[800]
                ),
                child: Stack(children: [if (card.versions.isNotEmpty) Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text("+${card.versions.length}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))), Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 2), color: Colors.black.withOpacity(0.7), child: Text(card.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.none))))]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    List<Widget> pageButtons = [];
    pageButtons.add(_buildPageButton("«", () => _goToPage(_page - 1), enabled: _page > 1));
    List<int> pagesToShow = [];
    pagesToShow.add(1);
    for (int i = _page - 1; i <= _page + 1; i++) { if (i > 1 && i < _totalPages) pagesToShow.add(i); }
    if (_totalPages > 1) pagesToShow.add(_totalPages);
    pagesToShow = pagesToShow.toSet().toList()..sort();
    int previous = 0;
    for (int p in pagesToShow) {
      if (previous > 0 && p - previous > 1) pageButtons.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("...", style: TextStyle(color: Colors.white54))));
      pageButtons.add(_buildPageNumber(p, p == _page));
      previous = p;
    }
    pageButtons.add(_buildPageButton("»", () => _goToPage(_page + 1), enabled: _page < _totalPages));
    return Container(height: 60, color: Colors.black26, padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: pageButtons));
  }

  Widget _buildPageNumber(int number, bool isActive) {
    return GestureDetector(onTap: () => _goToPage(number), child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 35, height: 35, alignment: Alignment.center, decoration: BoxDecoration(color: isActive ? _activePageColor : Colors.white, borderRadius: BorderRadius.circular(4), border: isActive ? null : Border.all(color: Colors.grey[300]!)), child: Text("$number", style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))));
  }

  Widget _buildPageButton(String text, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(onTap: enabled ? onTap : null, child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 35, height: 35, alignment: Alignment.center, decoration: BoxDecoration(color: enabled ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(4)), child: Text(text, style: TextStyle(color: enabled ? Colors.black87 : Colors.white24, fontWeight: FontWeight.bold, fontSize: 18))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      body: Column(
        children: [
          const SizedBox(height: 10), 
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _buildGrid()),
          _buildPagination(),
        ],
      ),
    );
  }
}