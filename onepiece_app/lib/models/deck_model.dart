class DeckModel {
  final String id;
  final String name;
  final List<String> cards;

  DeckModel({
    required this.id,
    required this.name,
    required this.cards,
  });

  factory DeckModel.fromJson(Map<String, dynamic> json) {
    return DeckModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Sin nombre',
      cards: List<String>.from(json['cards'] ?? []),
    );
  }
}
