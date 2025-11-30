import 'card_model.dart';

class DeckModel {
  String id;
  String name;
  List<CardModel> cards;
  DateTime createdAt;

  DeckModel({
    required this.id,
    required this.name,
    required this.cards,
    required this.createdAt,
  });

  factory DeckModel.empty() {
    return DeckModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Nuevo Mazo',
      cards: [],
      createdAt: DateTime.now(),
    );
  }

  int get count => cards.length;
}