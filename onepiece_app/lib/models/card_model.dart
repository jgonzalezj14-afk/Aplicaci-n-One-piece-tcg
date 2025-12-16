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


  List<String> get colorsList {
    return color
        .toLowerCase()
        .replaceAll("/", " ")
        .split(" ")
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  int get costValue => int.tryParse(cost) ?? 0;
  int get powerValue => int.tryParse(power) ?? 0;
  int get counterValue => int.tryParse(counter) ?? 0;

  static const List<String> knownFamilies = [
    "Straw Hat Crew", "Heart Pirates", "Kid Pirates", "Animal Kingdom Pirates",
    "Big Mom Pirates", "Whitebeard Pirates", "Red Hair Pirates", "Roger Pirates",
    "Kuja Pirates", "Donquixote Pirates", "Thriller Bark Pirates", "Drake Pirates",
    "Beautiful Pirates", "Fire Tank Pirates", "On Air Pirates", "Hawkins Pirates",
    "Fallen Monk Pirates", "Bonney Pirates", "Spade Pirates", "Sun Pirates",
    "Arlong Pirates", "Krieg Pirates", "Black Cat Pirates", "Buggy Pirates",
    "Giant Warrior Pirates", "Foxy Pirates", "New Fish-Man Pirates", "Caribou Pirates",
    "Bartoclub", "Happosui Army", "Ideoman Gym", "Tontatta Corps", "Yonta Maria Grand Fleet",
    "New Giant Warrior Pirates", "Nox Pirates", "Rolling Pirates", "Rumbar Pirates",
    "Saruyama Alliance", "Fake Straw Hat Crew", "Barrels Pirates", "Bellamy Pirates",
    "Blackbeard Pirates", "Bluejam Pirates", "Brownbeard Pirates", "Cook Pirates",
    "Flying Pirates", "Golden Lion Pirates", "Roshyamaners", "Wapol Pirates",
    "Cross Guild", "Plague", "Disaster",
    
    "Navy", "Supernovas", "The Seven Warlords of the Sea", "Four Emperors", 
    "Worst Generation", "Revolutionary Army", "Cipher Pol", "CP9", "CP0", 
    "Baroque Works", "Impel Down", "Former Navy", "Neo Navy", "World Government",
    "Celestial Dragons", "Jailer Beasts", "Gorosei", "God Knights",
    
    "Land of Wano", "Wano Country", "East Blue", "Alabasta", "Skypiea", "Water Seven",
    "Thriller Bark", "Sabaody", "Impel Down", "Marineford", "Fish-Man Island",
    "Punk Hazard", "Dressrosa", "Whole Cake Island", "Egghead", "Amazon Lily",
    "Germa 66", "Vinsmoke Family", "Galley-La Company", "Mountain Bandits",
    "Shandian", "Sky Island", "Moon", "Lunarian", "Minks", "Fish-Man", "Merfolk",
    "Homies", "Scientist", "Vegapunk", "Seraphim", "Pacifista", "Smile", 
    "Gifters", "Pleasures", "Waiters", "Headliners", "Flying Six", "Numbers",
    "Kozuki Clan", "Kurozumi Clan", "Nine Red Scabbards", "Animal", "Giant",
    
    "FILM", "Uta", "Red Hair", "Music", "Odyssey", "Gran Tesoro", "Golden",
    "Festival", "Daughter", "Standard"
  ];

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

    bool isNumeric(dynamic s) => s != null && int.tryParse(s.toString()) != null;
    
    if (isNumeric(rawSubTypes)) {
        String tempNum = rawSubTypes.toString();
        String tempText = "";

        if (rawPower != null && !isNumeric(rawPower)) {
            tempText = rawPower.toString();
            rawPower = "0"; 
        } 
        
        rawCounter = tempNum;
        rawSubTypes = tempText.isNotEmpty ? tempText : null; 
    }
    
    if (rawPower != null && !isNumeric(rawPower) && rawPower.toString().length > 3) {
        rawSubTypes = rawPower;
        rawPower = "-";
    }

    List<String> finalSubTypes = [];
    String combinedString = "";

    if (rawSubTypes != null) {
      if (rawSubTypes is List) {
        combinedString = rawSubTypes.join(" ");
      } else {
        combinedString = rawSubTypes.toString();
      }
    }

    combinedString = combinedString.replaceAll("/", " ").trim();
    
    String combinedLower = combinedString.toLowerCase();

    for (String family in knownFamilies) {
      if (combinedLower.contains(family.toLowerCase())) {
        finalSubTypes.add(family);
      }
    }

    if (finalSubTypes.isEmpty && combinedString.isNotEmpty) {
       finalSubTypes = combinedString.split(" ");
    }

    finalSubTypes = finalSubTypes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet() 
        .toList();
    
    finalSubTypes.sort(); 

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
      cost: json['card_cost']?.toString() ?? '-',
      cardText: json['card_text'] ?? 'Sin efecto',
      
      subTypes: finalSubTypes,
      versions: versionsList,
    );
  }
}