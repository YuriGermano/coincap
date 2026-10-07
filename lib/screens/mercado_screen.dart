import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/coincap_service.dart';
import '../utils/formatadores.dart';
import 'comparar_screen.dart';
import 'corretoras_screen.dart';
import 'detalhes_ativo_screen.dart';
import 'perfil_screen.dart';

class MercadoScreen extends StatefulWidget {
  const MercadoScreen({super.key});

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  List<Asset> _topMovers = [];
  List<Asset> _ativosMercado = [];
  bool _carregando = true;
  bool _erro = false;
  Timer? _timerAtualizacao;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    // Atualização suave a cada 90 segundos sem forçar bypass de cache
    _timerAtualizacao = Timer.periodic(const Duration(seconds: 90), (_) {
      if (mounted) {
        _carregarDados(silencioso: true, forcar: false);
      }
    });
  }

  @override
  void dispose() {
    _timerAtualizacao?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados({bool silencioso = false, bool forcar = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = false;
      });
    }

    try {
      final ativos = await CoinCapService.buscarListaAtivos(
        limit: 30,
        forcarAtualizacao: forcar,
      );
      
      // Calcula os maiores desempenhos diretamente dos ativos em memória para economizar chamadas
      final ordenados = List<Asset>.from(ativos)
        ..sort((a, b) => (b.changePercent24Hr ?? 0).compareTo(a.changePercent24Hr ?? 0));
      final movers = ordenados.take(6).toList();

      if (mounted) {
        setState(() {
          _ativosMercado = ativos;
          _topMovers = movers;
          _carregando = false;
          _erro = _ativosMercado.isEmpty && _topMovers.isEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = _ativosMercado.isEmpty;
        });
      }
    }
  }

  void _abrirDetalhes(Asset ativo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesAtivoScreen(
          slug: ativo.slug,
          assetInicial: ativo,
        ),
      ),
    );
  }

  Widget _cardTopMover(Asset ativo) {
    final subiu = (ativo.changePercent24Hr ?? 0) >= 0;

    return GestureDetector(
      onTap: () => _abrirDetalhes(ativo),
      child: Container(
        width: 114,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: corCartao,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ativo.symbol,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              formatarPreco(ativo.price, prefixo: '\$'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              formatarPercentual(ativo.changePercent24Hr),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subiu ? corVerde : corVermelha,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemAtivoMercado(Asset ativo) {
    final subiu = (ativo.changePercent24Hr ?? 0) >= 0;
    final letra = ativo.symbol.isNotEmpty ? ativo.symbol[0] : 'C';

    return InkWell(
      onTap: () => _abrirDetalhes(ativo),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: corPilula,
              child: Text(
                letra,
                style: const TextStyle(
                  color: corDestaque,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ativo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "#${ativo.rank ?? '-'} · ${ativo.symbol}",
                    style: const TextStyle(
                      color: corTextoSuave,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarPreco(ativo.price, prefixo: '\$'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatarPercentual(ativo.changePercent24Hr),
                  style: TextStyle(
                    color: subiu ? corVerde : corVermelha,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardAtalho({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: corCartao,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        maxLines: 1,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: corDestaque,
        backgroundColor: corCartao,
        onRefresh: () => _carregarDados(forcar: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Mercado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mercado",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: "Perfil",
                        icon: const Icon(Icons.person_outline, color: corTextoSuave),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerfilScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: "Atualizar cotações",
                        icon: const Icon(Icons.refresh, color: corTextoSuave),
                        onPressed: () => _carregarDados(forcar: true),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Atalhos principais: Comparar e Corretoras
              Row(
                children: [
                  _cardAtalho(
                    icone: Icons.swap_horiz,
                    titulo: "Comparar",
                    subtitulo: "Ativos lado a lado",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CompararScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _cardAtalho(
                    icone: Icons.business,
                    titulo: "Corretoras",
                    subtitulo: "Volume e pares",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CorretorasScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seção: MAIORES ALTAS E BAIXAS
              const Text(
                "MAIORES ALTAS E BAIXAS",
                style: TextStyle(
                  color: corTextoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              if (_carregando && _topMovers.isEmpty)
                Container(
                  height: 90,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: corDestaque),
                )
              else if (_topMovers.isNotEmpty)
                SizedBox(
                  height: 108,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _topMovers.length,
                    itemBuilder: (context, i) => _cardTopMover(_topMovers[i]),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: corCartao,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Nenhum destaque no momento",
                    style: TextStyle(color: corTextoSuave, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 28),

              // Seção: ATIVOS POR VALOR DE MERCADO
              const Text(
                "ATIVOS POR VALOR DE MERCADO",
                style: TextStyle(
                  color: corTextoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              if (_carregando && _ativosMercado.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(color: corDestaque)),
                )
              else if (_erro)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off, color: corTextoSuave, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          "Falha ao carregar ativos de mercado",
                          style: TextStyle(color: corTextoSuave),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPilula,
                            foregroundColor: corDestaque,
                          ),
                          onPressed: _carregarDados,
                          child: const Text("Tentar novamente"),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ativosMercado.length,
                  separatorBuilder: (_, _) => Divider(
                    color: Colors.white.withValues(alpha: 0.04),
                    height: 1,
                  ),
                  itemBuilder: (context, i) => _itemAtivoMercado(_ativosMercado[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}