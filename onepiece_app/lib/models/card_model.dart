class CardModel {
  final String id;
  final String name;
  final String type;
  final String color;
  final String imageUrl;
  final String cardNumber;
  final String rarity;
  final String power;
  final String cost;
  final String cardText;
  final String counter;
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

    dynamic rawPower = json['card_power'] ?? json['power'];
    dynamic rawCounter = json['counter_amount'] ?? json['counter'];
    dynamic rawSubTypes = json['sub_types'] ?? json['type'];

   
    
    bool familyIsNumber = rawSubTypes != null && int.tryParse(rawSubTypes.toString()) != null;
    
    bool powerIsText = rawPower != null && int.tryParse(rawPower.toString()) == null;

    if (familyIsNumber && powerIsText) {
      
      rawCounter = rawSubTypes;
      
      rawSubTypes = rawPower;
      
      rawPower = "0"; 
    }

    List<String> parsedSubTypes = [];
    if (rawSubTypes != null) {
      if (rawSubTypes is List) {
        parsedSubTypes = List<String>.from(rawSubTypes);
      } else {
        parsedSubTypes = rawSubTypes.toString().split('/');
      }
    }
    parsedSubTypes = parsedSubTypes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return CardModel(
      id: json['card_set_id'] ?? json['card_image_id'] ?? '',
      name: json['card_name'] ?? 'Sin nombre',
      type: json['card_type'] ?? 'Desconocido',
      color: json['card_color'] ?? 'N/A',
      imageUrl: json['card_image'] ?? '', 
      cardNumber: json['card_set_id']?.toString() ?? '???',
      rarity: json['rarity'] ?? 'N/A',
      
      power: rawPower?.toString() ?? '-',
      counter: rawCounter?.toString() ?? '-',
      subTypes: parsedSubTypes,

      cost: json['card_cost']?.toString() ?? '-',
      cardText: json['card_text'] ?? 'Sin efecto',
      versions: versionsList,
    );
  }
}