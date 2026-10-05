import 'dart:math';
import 'package:flutter/material.dart';
import '../models/price_point.dart';
import '../utils/formatadores.dart';

class GraficoDetalhes extends StatelessWidget {
  final List<PricePoint> pontos;
  final bool carregando;
  final Color? corLinha;

  const GraficoDetalhes({
    super.key,
    required this.pontos,
    this.carregando = false,
    this.corLinha,
  });

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: corCartao.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: corDestaque),
      );
    }

    if (pontos.length < 2) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: corCartao.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Histórico indisponível",
          style: TextStyle(color: corTextoSuave),
        ),
      );
    }

    final precos = pontos.map((p) => p.price).toList();
    final subiu = precos.last >= precos.first;
    final cor = corLinha ?? (subiu ? corVerde : corVermelha);

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: corCartao.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          size: Size.infinite,
          painter: _PintorGraficoDetalhes(precos, cor),
        ),
      ),
    );
  }
}

class _PintorGraficoDetalhes extends CustomPainter {
  final List<double> precos;
  final Color cor;

  _PintorGraficoDetalhes(this.precos, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    if (precos.length < 2) return;

    final minimo = precos.reduce(min);
    final maximo = precos.reduce(max);
    final faixa = (maximo - minimo) == 0 ? 1.0 : (maximo - minimo);

    final caminhoLinha = Path();
    final caminhoArea = Path();

    // Margens internas
    const margemY = 10.0;
    final alturaUtil = size.height - (margemY * 2);

    for (var i = 0; i < precos.length; i++) {
      final x = (size.width * i) / (precos.length - 1);
      final normalizado = (precos[i] - minimo) / faixa;
      final y = size.height - margemY - (normalizado * alturaUtil);

      if (i == 0) {
        caminhoLinha.moveTo(x, y);
        caminhoArea.moveTo(x, size.height);
        caminhoArea.lineTo(x, y);
      } else {
        caminhoLinha.lineTo(x, y);
        caminhoArea.lineTo(x, y);
      }
    }

    caminhoArea.lineTo(size.width, size.height);
    caminhoArea.close();

    // Pintar gradiente da área
    final gradiente = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        cor.withValues(alpha: 0.35),
        cor.withValues(alpha: 0.02),
      ],
    );

    final pincelArea = Paint()
      ..shader = gradiente.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(caminhoArea, pincelArea);

    // Pintar a linha principal
    final pincelLinha = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(caminhoLinha, pincelLinha);
  }

  @override
  bool shouldRepaint(covariant _PintorGraficoDetalhes antigo) {
    return antigo.precos != precos || antigo.cor != cor;
  }
}
