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

    
    List<String> parseColors(String colorString) {
      return colorString
          .toLowerCase()
          .replaceAll("/", " ") 
          .split(" ") 
          .map((c) => c.trim()) 
          .where((c) => c.isNotEmpty) 
          .toList();
    }

    final List<String> leaderColors = parseColors(leader!.color);
    final List<String> cardColors = parseColors(card.color);
    
    bool match = false;
    
    for (String cColor in cardColors) {
      if (leaderColors.contains(cColor)) {
        match = true;
        break; 
      }
    }

    if (!match) return "¡Tu Capitán (${leader!.color}) no permite cartas ${card.color}!";

    cards.add(card);
    cards.sort((a, b) {
        int costA = int.tryParse(a.cost) ?? 0;
        int costB = int.tryParse(b.cost) ?? 0;
        return costA.compareTo(costB);
    });
    
    return null;
  }

  void removeCard(CardModel card) {
    if (leader == card) {
      leader = null;
    } else {
      cards.remove(card);
    }
  }
}