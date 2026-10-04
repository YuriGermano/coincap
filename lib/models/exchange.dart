class Exchange {
  String exchangeId;
  String name;
  String rank;
  double? percentTotalVolume;
  double? volumeUsd;
  int tradingPairs;
  String? exchangeUrl;

  Exchange({
    required this.exchangeId,
    required this.name,
    required this.rank,
    this.percentTotalVolume,
    this.volumeUsd,
    required this.tradingPairs,
    this.exchangeUrl,
  });

  factory Exchange.fromJson(Map<String, dynamic> json) => Exchange(
        exchangeId: json["exchangeId"] ?? '',
        name: json["name"] ?? '',
        rank: '${json["rank"] ?? ''}',
        percentTotalVolume: double.tryParse('${json["percentTotalVolume"]}'),
        volumeUsd: double.tryParse('${json["volumeUsd"]}'),
        tradingPairs: int.tryParse('${json["tradingPairs"]}') ?? 0,
        exchangeUrl: json["exchangeUrl"],
      );
}

class ExchangeResponse {
  List<Exchange> data;

  ExchangeResponse({required this.data});

  factory ExchangeResponse.fromJson(Map<String, dynamic> json) =>
      ExchangeResponse(
        data: List<Exchange>.from(json["data"].map((x) => Exchange.fromJson(x))),
      );
}