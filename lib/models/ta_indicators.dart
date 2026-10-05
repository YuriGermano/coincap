class TaIndicators {
  final double? vwap24Hr;
  final double? rsi;
  final double? sma;
  final double? ema;
  final double? macd;
  final double? macdSignal;
  final double? macdHistogram;

  TaIndicators({
    this.vwap24Hr,
    this.rsi,
    this.sma,
    this.ema,
    this.macd,
    this.macdSignal,
    this.macdHistogram,
  });

  factory TaIndicators.fromJson(Map<String, dynamic> json) {
    double? extrairDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    final vwap = extrairDouble(json['vwap24'] ?? json['vwap24Hr'] ?? json['vwap']);
    final rsi = json['rsi'] is Map ? extrairDouble(json['rsi']['rsi']) : extrairDouble(json['rsi']);
    final sma = json['sma'] is Map ? extrairDouble(json['sma']['sma']) : extrairDouble(json['sma']);
    final ema = json['ema'] is Map ? extrairDouble(json['ema']['ema']) : extrairDouble(json['ema']);
    
    double? macdVal;
    double? macdSig;
    double? macdHist;
    if (json['macd'] is Map) {
      macdVal = extrairDouble(json['macd']['macd']);
      macdSig = extrairDouble(json['macd']['signal']);
      macdHist = extrairDouble(json['macd']['histogram']);
    } else {
      macdVal = extrairDouble(json['macd']);
    }

    return TaIndicators(
      vwap24Hr: vwap,
      rsi: rsi,
      sma: sma,
      ema: ema,
      macd: macdVal,
      macdSignal: macdSig,
      macdHistogram: macdHist,
    );
  }
}
