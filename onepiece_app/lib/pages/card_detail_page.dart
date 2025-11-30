import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardDetailPage extends StatefulWidget {
  final CardModel card;
  const CardDetailPage({super.key, required this.card});

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late CardModel _displayCard;

  @override
  void initState() {
    super.initState();
    _displayCard = widget.card;
  }

  void _swapCard(CardModel newCard) {
    setState(() => _displayCard = newCard);
  }

  List<Color> _getAppBarGradient(String colorName) {
    final c = colorName.toLowerCase();
    List<Color> colors = [];
    if (c.contains('red')) colors.add(Colors.red[900]!);
    if (c.contains('green')) colors.add(Colors.green[900]!);
    if (c.contains('blue')) colors.add(Colors.blue[900]!);
    if (c.contains('purple')) colors.add(Colors.purple[900]!);
    if (c.contains('yellow')) colors.add(Colors.amber[800]!);
    if (c.contains('black')) colors.add(Colors.grey[900]!);
    
    if (colors.isEmpty) return [Colors.grey[800]!, Colors.black];
    if (colors.length == 1) return [colors[0], colors[0].withOpacity(0.7)];
    return colors;
  }

  String _formatValue(String val) {
    if (val == 'NULL' || val.trim() == '-') return '0';
    return val;
  }

  Widget _buildImagePlaceholder({required double height, bool isSmall = false}) {
    return Container(
      height: height,
      width: isSmall ? 50 : null,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(isSmall ? 4 : 12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: isSmall
            ? const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 20)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.white12),
                  const SizedBox(height: 10),
                  Text("Arte no disponible", style: TextStyle(color: Colors.white24, fontFamily: 'serif', fontSize: 14)),
                  Text(_displayCard.cardNumber, style: TextStyle(color: Colors.amber.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allVersions = [widget.card, ...widget.card.versions];
    final gradientColors = _getAppBarGradient(_displayCard.color);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_displayCard.cardNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors))),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientColors.first.withOpacity(0.4), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Hero(
                    tag: _displayCard.id,
                    child: Image.network(
                      _displayCard.imageUrl,
                      height: 350,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, p) => p == null ? child : const CircularProgressIndicator(color: Colors.white),
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(height: 350),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _displayCard.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'serif', letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(20)),
                    child: Text(_displayCard.type.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
            ),

            if (allVersions.length > 1)
              Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: allVersions.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final v = allVersions[index];
                    final isSelected = v.imageUrl == _displayCard.imageUrl;
                    return GestureDetector(
                      onTap: () => _swapCard(v),
                      child: Column(
                        children: [
                          Container(
                            height: 70, width: 50,
                            decoration: BoxDecoration(border: isSelected ? Border.all(color: Colors.amber, width: 3) : Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.network(v.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => _buildImagePlaceholder(height: 70, isSmall: true)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("V${index + 1}", style: TextStyle(color: isSelected ? Colors.amber : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCircle(label: "Coste", value: _formatValue(_displayCard.cost), color: Colors.blueGrey),
                  _StatCircle(label: "Poder", value: _formatValue(_displayCard.power), color: Colors.redAccent),
                  _StatCircle(label: "Counter", value: _formatValue(_displayCard.counter), color: Colors.green),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  if (_displayCard.subTypes.isNotEmpty) ...[
                    const Text("FAMILIAS", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white24, 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _displayCard.subTypes.join(" / "), 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 14, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 30),
                  ],

                  const Text("EFECTO", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(_displayCard.cardText.isEmpty ? "Sin efecto." : _displayCard.cardText, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("ID: ${_displayCard.cardNumber}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 20),
                  Text("Rareza: ${_displayCard.rarity}", style: const TextStyle(color: Colors.amber)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCircle({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 55, height: 55, alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2), color: Colors.black, boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]),
          child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}