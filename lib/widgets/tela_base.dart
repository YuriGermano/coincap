import 'package:flutter/material.dart';
import '../utils/formatadores.dart';

class TelaBase extends StatelessWidget {
  final String titulo;
  final Widget? acao;
  final Widget child;

  const TelaBase({
    super.key,
    required this.titulo,
    this.acao,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF26003F), Color(0xFF0A0014)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: corPilula,
                        child: Icon(Icons.chevron_left, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ?acao,
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}