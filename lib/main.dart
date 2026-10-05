import 'package:flutter/material.dart';
import 'screens/buscar_screen.dart';
import 'screens/comparar_screen.dart';
import 'screens/conversor_screen.dart';
import 'screens/corretoras_screen.dart';
import 'screens/detalhes_ativo_screen.dart';
import 'screens/favoritos_screen.dart';
import 'screens/mercado_screen.dart';

void main() {
  runApp(const CoinCapApp());
}

class CoinCapApp extends StatelessWidget {
  const CoinCapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinCap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0014),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/detalhes') {
          final slug = settings.arguments as String? ?? 'bitcoin';
          return MaterialPageRoute(
            builder: (_) => DetalhesAtivoScreen(slug: slug),
          );
        }
        if (settings.name == '/comparar') {
          return MaterialPageRoute(builder: (_) => const CompararScreen());
        }
        if (settings.name == '/corretoras') {
          return MaterialPageRoute(builder: (_) => const CorretorasScreen());
        }
        return MaterialPageRoute(builder: (_) => const TelaInicial());
      },
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF26003F), Color(0xFF0A0014)],
          ),
        ),
        child: IndexedStack(
          index: _indice,
          children: [
            const MercadoScreen(),
            const BuscarScreen(),
            FavoritosScreen(
              onIrParaMercado: () {
                setState(() => _indice = 0);
              },
            ),
            const ConversorScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A0014),
        selectedItemColor: const Color(0xFFA78BFA),
        unselectedItemColor: const Color(0xFF6B5A80),
        elevation: 0,
        currentIndex: _indice,
        onTap: (indice) {
          setState(() {
            _indice = indice;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Início",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search, color: Color(0xFFA78BFA)),
            label: "Buscar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            activeIcon: Icon(Icons.star),
            label: "Favoritos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            activeIcon: Icon(Icons.swap_horizontal_circle),
            label: "Conversor",
          ),
        ],
      ),
    );
  }
}