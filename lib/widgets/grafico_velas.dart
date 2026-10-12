import 'dart:math';
import 'package:flutter/material.dart';
import '../models/candlestick.dart';
import '../utils/formatadores.dart';

class GraficoVelas extends StatelessWidget {
  final List<Candlestick> velas;
  final bool carregando;

  const GraficoVelas({
    super.key,
    required this.velas,
    this.carregando = false,
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

    if (velas.length < 2) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: corCartao.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Gráfico de velas indisponível",
          style: TextStyle(color: corTextoSuave),
        ),
      );
    }

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
          painter: _PintorGraficoVelas(velas),
        ),
      ),
    );
  }
}

class _PintorGraficoVelas extends CustomPainter {
  final List<Candlestick> velas;

  _PintorGraficoVelas(this.velas);

  @override
  void paint(Canvas canvas, Size size) {
    if (velas.length < 2) return;

    // Calcular min/max globais
    double minGlobal = double.infinity;
    double maxGlobal = double.negativeInfinity;
    for (final vela in velas) {
      if (vela.low < minGlobal) minGlobal = vela.low;
      if (vela.high > maxGlobal) maxGlobal = vela.high;
    }

    final faixa = (maxGlobal - minGlobal) == 0 ? 1.0 : (maxGlobal - minGlobal);
    const margemY = 6.0;
    final alturaUtil = size.height - (margemY * 2);

    // Largura de cada vela
    final espacoTotal = size.width;
    final larguraVela = espacoTotal / velas.length;
    final larguraCorpo = max(larguraVela * 0.6, 2.0);
    final larguraPavio = max(larguraVela * 0.12, 1.0);

    for (var i = 0; i < velas.length; i++) {
      final vela = velas[i];
      final centroX = (i + 0.5) * larguraVela;
      final subiu = vela.close >= vela.open;
      final cor = subiu ? corVerde : corVermelha;

      // Posições Y (invertido: preço alto = y baixo)
      double toY(double preco) {
        final normalizado = (preco - minGlobal) / faixa;
        return size.height - margemY - (normalizado * alturaUtil);
      }

      final yHigh = toY(vela.high);
      final yLow = toY(vela.low);
      final yOpen = toY(vela.open);
      final yClose = toY(vela.close);

      // Pavio (linha vertical de high a low)
      final pincelPavio = Paint()
        ..color = cor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = larguraPavio;

      canvas.drawLine(
        Offset(centroX, yHigh),
        Offset(centroX, yLow),
        pincelPavio,
      );

      // Corpo (retângulo de open a close)
      final corpoTop = min(yOpen, yClose);
      final corpoBottom = max(yOpen, yClose);
      final alturaCorpo = max(corpoBottom - corpoTop, 1.0);

      final pincelCorpo = Paint()
        ..color = cor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centroX - larguraCorpo / 2,
            corpoTop,
            larguraCorpo,
            alturaCorpo,
          ),
          const Radius.circular(1),
        ),
        pincelCorpo,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorGraficoVelas antigo) {
    return antigo.velas != velas;
  }
}
