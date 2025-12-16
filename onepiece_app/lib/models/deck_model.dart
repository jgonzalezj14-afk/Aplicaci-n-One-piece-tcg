import 'package:cloud_firestore/cloud_firestore.dart';
import 'card_model.dart';

class DeckModel {
  String? id;
  String name;
  CardModel? leader;
  List<CardModel> cards;

  DeckModel({
    this.id,
    this.name = 'Nuevo Mazo',
    this.leader,
    List<CardModel>? cards,
  }) : cards = cards ?? [];

  int get totalCards => cards.length;

  int countCopies(String cardId) {
    return cards.where((c) => c.cardNumber == cardId).length;
  }

  String? addCard(CardModel card) {
    if (card.type.toLowerCase().contains('leader')) {
      if (leader != null) return "¡Ya tienes un Líder! Elimínalo antes de poner otro.";
      leader = card;
      return null;
    }

    if (leader == null) return "¡Primero elige a tu Líder!";
    if (totalCards >= 50) return "¡El mazo está lleno! Máximo 50 cartas.";
    if (countCopies(card.cardNumber) >= 4) return "¡Solo 4 copias por carta!";

    final leaderColors = leader!.colorsList;
    final cardColors = card.colorsList;
    
    bool match = cardColors.any((cColor) => leaderColors.contains(cColor));

    if (!match) return "¡Tu Capitán (${leader!.color}) no permite cartas ${card.color}!";

    cards.add(card);
    cards.sort((a, b) => a.costValue.compareTo(b.costValue));
    return null;
  }

  void removeCard(CardModel card) {
    if (leader == card) {
      leader = null;
    } else {
      cards.remove(card);
    }
  }

  void clear() {
    leader = null;
    cards.clear();
    name = "Nuevo Mazo";
    id = null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
      'leader': leader != null ? _cardToMap(leader!) : null,
      'cards': cards.map((c) => _cardToMap(c)).toList(),
    };
  }

  Map<String, dynamic> _cardToMap(CardModel c) {
    return {
      'card_set_id': c.cardNumber,
      'card_name': c.name,
      'card_image': c.imageUrl,
      'card_type': c.type,
      'card_color': c.color,
      'card_cost': c.cost,
      'card_power': c.power,
      'card_text': c.cardText,
    };
  }

  factory DeckModel.fromMap(Map<String, dynamic> map, String docId) {
    CardModel? loadedLeader;
    if (map['leader'] != null) {
      loadedLeader = CardModel.fromJson(map['leader']);
    }

    List<CardModel> loadedCards = [];
    if (map['cards'] != null) {
      for (var c in map['cards']) {
        loadedCards.add(CardModel.fromJson(c));
      }
    }

    return DeckModel(
      id: docId,
      name: map['name'] ?? 'Mazo Importado',
      leader: loadedLeader,
      cards: loadedCards,
    );
  }

  String toClipboardString() {
    StringBuffer buffer = StringBuffer();
    
    if (leader != null) {
      buffer.writeln("1x${leader!.cardNumber}");
    }

    Map<String, int> counts = {};
    for (var card in cards) {
      counts[card.cardNumber] = (counts[card.cardNumber] ?? 0) + 1;
    }

    counts.forEach((id, qty) {
      buffer.writeln("${qty}x$id");
    });

    return buffer.toString().trim();
  }
}