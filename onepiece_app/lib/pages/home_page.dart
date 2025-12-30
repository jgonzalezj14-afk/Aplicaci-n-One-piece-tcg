import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
import 'card_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  
  List<CardModel> _topLeaders = [];
  CardModel? _randomCard; 
  bool _isLoadingLeaders = true;
  bool _isLoadingRandom = false; 

  final Color _woodColor = const Color(0xFF2D1E18);
  final Color _goldColor = const Color(0xFFFFC107);
  final Color _pirateRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchTopLeaders();
  }

  Future<void> _fetchTopLeaders() async {
    try {
      final leaders = await _apiService.getCardsByIds([
        'OP13-079', 'OP13-002', 'OP12-020'
      ]);
      if (mounted) setState(() { _topLeaders = leaders; _isLoadingLeaders = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLeaders = false);
    }
  }

  Future<void> _generateRandomCard() async {
    setState(() => _isLoadingRandom = true);
    try {
      final card = await _apiService.getRandomCard();
      if (mounted) setState(() => _randomCard = card);
    } catch (e) {
      debugPrint("Error carta random: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRandom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      appBar: AppBar(
        title: const Text('ONE PIECE DECKS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        foregroundColor: _goldColor,
        centerTitle: true,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.black38, 
                border: Border(bottom: BorderSide(color: _goldColor, width: 2))
              ),
              child: Column(
                children: [
                  const Icon(Icons.anchor, size: 60, color: Colors.white54),
                  const SizedBox(height: 15),
                  Text(
                    "Bienvenido al Grand Line", 
                    style: TextStyle(color: _goldColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif'), 
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Gestiona tus mazos y conquista los mares con la mejor aplicación de One Piece TCG.", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionTitle(Icons.star, "TOP LÍDERES META"),
            const SizedBox(height: 20),
            SizedBox(
              height: 290,
              child: _isLoadingLeaders
                  ? Center(child: CircularProgressIndicator(color: _goldColor))
                  : _topLeaders.isEmpty 
                      ? const Center(child: Text("No se encontraron datos...", style: TextStyle(color: Colors.white54)))
                      : Center(
                          child: ListView.builder(
                            shrinkWrap: true, 
                            scrollDirection: Axis.horizontal, 
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _topLeaders.length,
                            itemBuilder: (context, index) => _buildLeaderCard(context, _topLeaders[index]),
                          ),
                        ),
            ),

            const SizedBox(height: 40),

            _buildSectionTitle(Icons.new_releases, "PRÓXIMAS COLECCIONES"),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Center(
                child: ListView(
                  shrinkWrap: true, 
                  scrollDirection: Axis.horizontal, 
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildCollectionCard("PRB-02", "Premium Booster 2", "assets/images/prb02.jpg"),
                    const SizedBox(width: 15),
                    _buildCollectionCard("OP-14", "Seven Warlords", "assets/images/op14.jpg"),
                    const SizedBox(width: 15),
                    _buildCollectionCard("EB-03", "Extra Booster 3", "assets/images/eb03.jpg"),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 50),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              color: Colors.black26,
              child: Column(
                children: [
                  _buildSectionTitle(Icons.casino, "DESCUBRE UN TESORO"),
                  const SizedBox(height: 10),
                  const Text("¡Genera una carta aleatoria de toda la base de datos!", style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 30),
                  
                  ElevatedButton.icon(
                    onPressed: _isLoadingRandom ? null : _generateRandomCard,
                    icon: _isLoadingRandom 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 28),
                    label: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_isLoadingRandom ? "BUSCANDO..." : "GENERAR CARTA", style: const TextStyle(fontSize: 18)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      elevation: 10,
                      shadowColor: _goldColor.withOpacity(0.5),
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (_randomCard != null)
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailPage(card: _randomCard!))),
                      child: Column(
                        children: [
                          Hero(
                            tag: "card_${_randomCard!.id}",
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: _goldColor.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)],
                                border: Border.all(color: _goldColor, width: 3)
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _randomCard!.imageUrl,
                                  height: 450, 
                                  fit: BoxFit.contain,
                                  errorBuilder: (c,e,s) => Container(width: 300, height: 450, color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white, size: 50)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(_randomCard!.name, style: TextStyle(color: _goldColor, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(_randomCard!.cardNumber, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _goldColor, size: 28),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildLeaderCard(BuildContext context, CardModel card) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CardDetailPage(card: card))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
            color: Colors.black, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: _goldColor.withOpacity(0.6), width: 2), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(3, 3))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), 
                  child: Image.network(
                      card.imageUrl, 
                      fit: BoxFit.cover, 
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[900], child: const Icon(Icons.person, size: 60, color: Colors.white24))
                  )
                )
            ),
            Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(color: _pirateRed.withOpacity(0.9), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10))), 
                child: Column(children: [
                    Text(card.name, textAlign: TextAlign.center, style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis), 
                    Text(card.cardNumber, style: const TextStyle(color: Colors.white70, fontSize: 11))
                ])
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(String code, String name, String imagePath) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: const Color(0xFF5D4037), width: 2), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6)], 
          image: DecorationImage(
              image: AssetImage(imagePath), 
              fit: BoxFit.cover, 
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)
          ), 
          color: Colors.grey[800]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(code, style: TextStyle(color: _goldColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: const [Shadow(color: Colors.black, blurRadius: 10)])),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
          const SizedBox(height: 15),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
              decoration: BoxDecoration(color: _pirateRed, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)), 
              child: const Text("PRÓXIMAMENTE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))
          )
        ],
      ),
    );
  }
}