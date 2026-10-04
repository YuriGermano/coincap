import 'package:flutter/material.dart';
import '../utils/formatadores.dart';
import 'comparar_screen.dart';
import 'corretoras_screen.dart';

class MercadoScreen extends StatelessWidget {
  const MercadoScreen({super.key});

  Widget _atalho(
    BuildContext context,
    IconData icone,
    String titulo,
    String subtitulo,
    Widget destino,
  ) {
    return Card(
      color: corCartao,
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destino),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: corPilula,
                child: Icon(icone, size: 18, color: corDestaque),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: corTextoSuave,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Mercado",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _atalho(
                    context,
                    Icons.swap_horiz,
                    "Comparar",
                    "Ativos lado a lado",
                    const CompararScreen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _atalho(
                    context,
                    Icons.open_in_new,
                    "Corretoras",
                    "Volume e pares",
                    const CorretorasScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}