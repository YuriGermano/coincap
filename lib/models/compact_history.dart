import 'price_point.dart';

class CompactHistory {
  final String slug;
  final DateTime startTime;
  final DateTime endTime;
  final int intervalMinutes;
  final int dataPoints;
  final List<PricePoint> points;

  CompactHistory({
    required this.slug,
    required this.startTime,
    required this.endTime,
    required this.intervalMinutes,
    required this.dataPoints,
    required this.points,
  });

  factory CompactHistory.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final slug = (data['slug'] ?? '').toString();

    DateTime parseTime(dynamic v) {
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt;
      }
      return DateTime.now();
    }

    final startTime = parseTime(data['startTime']);
    final endTime = parseTime(data['endTime']);
    final intervalMinutes = int.tryParse('${data['intervalMinutes']}') ?? 0;
    final dataPointsCount = int.tryParse('${data['dataPoints']}') ?? 0;

    final historyCsv = (data['history'] ?? '').toString();
    final points = <PricePoint>[];

    for (final linha in historyCsv.split('\n')) {
      final partes = linha.trim().split(',');
      if (partes.length < 2) continue;
      final timestamp = int.tryParse(partes[0]);
      final preco = double.tryParse(partes[1]);
      if (timestamp != null && preco != null) {
        points.add(PricePoint(
          DateTime.fromMillisecondsSinceEpoch(timestamp),
          preco,
        ));
      }
    }

    return CompactHistory(
      slug: slug,
      startTime: startTime,
      endTime: endTime,
      intervalMinutes: intervalMinutes,
      dataPoints: dataPointsCount,
      points: points,
    );
  }
}

class CompactHistoryResponse {
  final CompactHistory data;

  CompactHistoryResponse({required this.data});

  factory CompactHistoryResponse.fromJson(Map<String, dynamic> json) =>
      CompactHistoryResponse(data: CompactHistory.fromJson(json));
}

