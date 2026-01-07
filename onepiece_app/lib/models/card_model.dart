import '../services/api_service.dart';
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
    "?", 
    "Mary Geoise",
    "Drum Kingdom",
    "Supernovas", "Worst Generation", "Four Emperors", "The Seven Warlords of the Sea",
    "Revolutionary Army", "Cross Guild", "Germa 66", "Vinsmoke Family",
    "Baroque Works", "Thriller Bark Pirates", "Donquixote Pirates", "Kuja Pirates",
    "Sun Pirates", "God Knights", "The Five Elders", "Gorosei",
    "Celestial Dragons", "World Government", "Navy", "Former Navy", "Neo Navy",
    "Cipher Pol", "CP0", "CP9", "Impel Down", "Jailer Beasts",

    "Straw Hat Crew", "Heart Pirates", "Kid Pirates", "Animal Kingdom Pirates",
    "Big Mom Pirates", "Whitebeard Pirates", "Red Hair Pirates", "Roger Pirates",
    "Blackbeard Pirates", "Air Pirates", "Alvida Pirates", "Arlong Pirates",
    "Barrels Pirates", "Bartoclub", "Beautiful Pirates", "Bellamy Pirates",
    "Black Cat Pirates", "Bluejam Pirates", "Bonney Pirates", "Brownbeard Pirates",
    "Buggy Pirates", "Caribou Pirates", "Cook Pirates", "Drake Pirates",
    "Fallen Monk Pirates", "Fake Straw Hat Crew", "Fire Tank Pirates", "Flying Pirates",
    "Foxy Pirates", "Gasparde Pirates", "Giant Warrior Pirates", "Golden Lion Pirates",
    "Hawkins Pirates", "Krieg Pirates", "Macro Pirates", "New Giant Warrior Pirates",
    "New Fish-Man Pirates", "Nox Pirates", "On Air Pirates", "Rolling Pirates",
    "Rosy Life Riders", "Rumbar Pirates", "Saruyama Alliance", "Schneider Pirates",
    "Spade Pirates", "Trump Siblings", "Wapol Pirates", "Yes Pirates",
    "Yonta Maria Grand Fleet",

    "East Blue", "Alabasta", "Skypiea", "Water Seven", "Thriller Bark",
    "Sabaody Archipelago", "Sabaody", "Marineford", "Fish-Man Island",
    "Punk Hazard", "Dressrosa", "Whole Cake Island", "Land of Wano", "Wano Country",
    "Egghead", "Kingdom of Prodence", "Amazon Lily", "Kamabakka Queendom",
    "Lulusia Kingdom", "Goa Kingdom", "Shimotsuki Village", "Mokomo Dukedom",
    "Kingdom of Germa", "Tequila Wolf", "Weatheria", "Boin Archipelago",
    "Momoiro Island", "Torino Kingdom", "Kuraigana Island", "Karakuri Island",
    "Baldimore", "Namakura Island", "Rusukaina", "Swallow Island",
    "Konomi Islands", "Shells Town", "Orange Town", "Syrup Village", "Baratie",
    "Cocoyasi Village", "Loguetown", "Twin Cape", "Whiskey Peak", "Little Garden",
    "Drum Island", "Jaya", "Long Ring Long Land", "Ohara",

    "Kozuki Clan", "Kouzuki Clan",
    "Kurozumi Clan", "Nine Red Scabbards", "Ninja",
    "Smile", "Gifters", "Pleasures", "Waiters", "Headliners", "Flying Six", "Numbers",

    "Scientist", "Vegapunk", "Satellite", "Seraphim", "Pacifista",
    "MADS", "Neo-MADS", "Centaur",

    "Galley-La Company", "Franky Family", "Bounty Hunters", "Mountain Bandits",
    "Happosui Army", "Ideoman Gym", "Tontatta Corps", "House of Lambs",
    "Mugiwara Store", "News Coo",

    "Fish-Man", "Merfolk", "Minks", "Giant", "Lunarian", "Shandian",
    "Sky Island", "Moon", "Homies", "Animal", "Human",

    "FILM", "Uta", "Music", "Odyssey", "Gran Tesoro", "Golden",
    "Festival", "Daughter", "Video Game", "Live Action",
    "25th Anniversary", "Anniversary",

    "Plague", "Disaster", "Special"
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
      
      imageUrl: ApiService.fixUrl(json['card_image'] ?? ''),
      
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