class CardModel {
  final String id;
  final String name;
  final String type; // Ej: Character
  final String color;
  final String imageUrl;
  final String cardNumber;
  final String rarity;
  final String power;
  final String cost;
  final String cardText;
  final String counter;
  
  // NUEVO: Subtipos (Familias/Tags)
  final List<String> subTypes;
  
  final List<CardModel> versions;

  CardModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.imageUrl,
    required this.cardNumber,
    required this.rarity,
    required this.power,
    required this.cost,
    required this.cardText,
    required this.counter,
    required this.subTypes,
    this.versions = const [],
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    var versionsList = <CardModel>[];
    if (json['versions'] != null) {
      json['versions'].forEach((v) {
        versionsList.add(CardModel.fromJson(v));
      });
    }

    // Lógica para leer subtipos (puede venir como lista o null)
    List<String> parsedSubTypes = [];
    if (json['sub_types'] != null) {
      if (json['sub_types'] is List) {
        parsedSubTypes = List<String>.from(json['sub_types']);
      } else if (json['sub_types'] is String) {
        parsedSubTypes = [json['sub_types']];
      }
    }

    return CardModel(
      id: json['card_set_id'] ?? json['card_image_id'] ?? '',
      name: json['card_name'] ?? 'Sin nombre',
      type: json['card_type'] ?? 'Desconocido',
      color: json['card_color'] ?? 'N/A',
      imageUrl: json['card_image'] ?? '', 
      cardNumber: json['card_set_id']?.toString() ?? '???',
      rarity: json['rarity'] ?? 'N/A',
      power: json['card_power']?.toString() ?? '-',
      cost: json['card_cost']?.toString() ?? '-',
      cardText: json['card_text'] ?? 'Sin efecto',
      counter: json['counter_amount']?.toString() ?? '-',
      subTypes: parsedSubTypes, // Asignamos los tipos
      versions: versionsList,
    );
  }
}