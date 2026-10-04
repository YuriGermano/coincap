List<double> _lerHistorico(dynamic historico) {
  if (historico is! Map) return [];

  final csv = historico["last30Days"];
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
    required this.historico,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        slug: json["slug"] ?? '',
        symbol: json["symbol"] ?? '',
        name: json["name"] ?? '',
        price: double.tryParse('${json["price"]}') ?? 0,
        marketCap: double.tryParse('${json["marketCap"]}'),
        volume: double.tryParse('${json["volume"]}'),
        changePercent24Hr: double.tryParse('${json["changePercent24Hr"]}'),
        supply: double.tryParse('${json["supply"]}'),
        historico: _lerHistorico(json["history"]),
      );
}

class AssetResponse {
  List<Asset> data;

  AssetResponse({required this.data});

  factory AssetResponse.fromJson(Map<String, dynamic> json) => AssetResponse(
        data: List<Asset>.from(json["data"].map((x) => Asset.fromJson(x))),
      );
}