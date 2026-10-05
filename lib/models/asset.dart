List<double> _lerHistorico(dynamic historico) {
  if (historico is! Map) return [];

  final csv = historico["last30Days"] ?? historico["last24Hours"] ?? historico["last365Days"];
  if (csv is! String) return [];

  final pontos = <double>[];
  for (final linha in csv.split('\n')) {
    final partes = linha.trim().split(',');
    if (partes.length < 2) continue;
    final preco = double.tryParse(partes[1]);
    if (preco != null) pontos.add(preco);
  }
  return pontos;
}

class Asset {
  String slug;
  String symbol;
  String name;
  double price;
  double? marketCap;
  double? volume;
  double? changePercent24Hr;
  double? supply;
  double? maxSupply;
  double? vwap24Hr;
  int? rank;
  String? explorer;
  List<double> historico;

  Asset({
    required this.slug,
    required this.symbol,
    required this.name,
    required this.price,
    this.marketCap,
    this.volume,
    this.changePercent24Hr,
    this.supply,
    this.maxSupply,
    this.vwap24Hr,
    this.rank,
    this.explorer,
    required this.historico,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    final slug = (json["slug"] ?? json["id"] ?? '').toString();
    final symbol = (json["symbol"] ?? '').toString().toUpperCase();
    final name = (json["name"] ?? slug).toString();
    final price = double.tryParse('${json["price"] ?? json["priceUsd"]}') ?? 0.0;
    final marketCap = double.tryParse('${json["marketCap"] ?? json["marketCapUsd"]}');
    final volume = double.tryParse('${json["volume"] ?? json["volumeUsd24Hr"]}');
    final changePercent24Hr = double.tryParse('${json["changePercent24Hr"]}');
    final supply = double.tryParse('${json["supply"]}');
    final maxSupply = double.tryParse('${json["maxSupply"]}');
    final vwap24Hr = double.tryParse('${json["vwap24Hr"]}');
    final rank = int.tryParse('${json["rank"]}');
    final explorer = json["explorer"]?.toString();
    final historico = _lerHistorico(json["history"]);

    return Asset(
      slug: slug,
      symbol: symbol,
      name: name,
      price: price,
      marketCap: marketCap,
      volume: volume,
      changePercent24Hr: changePercent24Hr,
      supply: supply,
      maxSupply: maxSupply,
      vwap24Hr: vwap24Hr,
      rank: rank,
      explorer: explorer,
      historico: historico,
    );
  }
}

class AssetResponse {
  List<Asset> data;

  AssetResponse({required this.data});

  factory AssetResponse.fromJson(Map<String, dynamic> json) => AssetResponse(
        data: List<Asset>.from(
          (json["data"] as List? ?? []).map((x) => Asset.fromJson(x as Map<String, dynamic>)),
        ),
      );
}