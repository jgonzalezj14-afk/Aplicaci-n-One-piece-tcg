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

  // NUEVA FUNCIÓN: Obtener colores para degradado de App Bar
  List<Color> _getAppBarColors(String colorName) {
    final colors = colorName.toLowerCase().split(' ');
    List<Color> appBarColors = [];

    for (var c in colors) {
      if (c.contains('red')) appBarColors.add(Colors.redAccent[700]!);
      else if (c.contains('green')) appBarColors.add(Colors.green[700]!);
      else if (c.contains('blue')) appBarColors.add(Colors.blue[700]!);
      else if (c.contains('purple')) appBarColors.add(Colors.purple[700]!);
      else if (c.contains('yellow')) appBarColors.add(Colors.amber[700]!);
      else if (c.contains('black')) appBarColors.add(Colors.grey[800]!);
    }
    
    if (appBarColors.isEmpty) return [Colors.grey[800]!, Colors.grey[900]!]; // Default
    if (appBarColors.length == 1) return [appBarColors[0], appBarColors[0].withOpacity(0.7)]; // Single color gradient
    return appBarColors; // Multiple colors for gradient
  }

  Color _getCardColor(String colorName) {
    final c = colorName.toLowerCase();
    if (c.contains('red')) return Colors.redAccent;
    if (c.contains('green')) return Colors.green;
    if (c.contains('blue')) return Colors.blue;
    if (c.contains('purple')) return Colors.purpleAccent;
    if (c.contains('yellow')) return Colors.amber;
    if (c.contains('black')) return Colors.grey[800]!;
    return Colors.grey;
  }

  // Helper para mostrar el Coste o 0
  String _getCostValue(String cost) {
    return (cost == '-' || cost.toLowerCase() == 'null') ? '0' : cost;
  }

  @override
  Widget build(BuildContext context) {
    final allVersions = [widget.card, ...widget.card.versions];
    final cardColor = _getCardColor(_displayCard.color);
    final appBarColors = _getAppBarColors(_displayCard.color);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_displayCard.cardNumber),
        // AHORA LA APP BAR ES UN DEGRADADO DE LOS COLORES DE LA CARTA
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: appBarColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER VISUAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor.withOpacity(0.6), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _displayCard.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'serif', shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(20)),
                    child: Text(_displayCard.type.toUpperCase(), style: const TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 2. SELECTOR DE VERSIONES
            if (allVersions.length > 1)
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allVersions.length,
                  itemBuilder: (context, index) {
                    final v = allVersions[index];
                    final isSelected = v.id == _displayCard.id;
                    return GestureDetector(
                      onTap: () => _swapCard(v),
                      child: Container(
                        width: 50, margin: const EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? cardColor : Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                        ),
                        child: Text("V${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),

            // 3. DETALLES Y TIPOS
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCircle(label: "Coste", value: _getCostValue(_displayCard.cost), color: Colors.blueGrey), // Coste ahora muestra 0
                      _StatCircle(label: "Poder", value: _displayCard.power, color: Colors.redAccent),
                      _StatCircle(label: "Counter", value: _displayCard.counter, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // SECCIÓN: TIPOS/FAMILIAS
                  if (_displayCard.subTypes.isNotEmpty) ...[
                    const Text("FAMILIAS / TIPOS", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _displayCard.subTypes.map((type) => Chip(
                        // FONDO TRANSPARENTE, BORDE BLANCO, TEXTO BLANCO
                        backgroundColor: Colors.transparent,
                        labelStyle: const TextStyle(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white54, width: 1),
                        ),
                        label: Text(type),
                      )).toList(),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // EFECTO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("EFECTO", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        Text(_displayCard.cardText.isEmpty ? "Sin efecto." : _displayCard.cardText, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(label: "ID Set", value: _displayCard.cardNumber),
                  _InfoRow(label: "Rareza", value: _displayCard.rarity),
                  _InfoRow(label: "Color", value: _displayCard.color),
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
          width: 60, height: 60, alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
          child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}