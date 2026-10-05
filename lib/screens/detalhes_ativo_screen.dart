import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/market.dart';
import '../models/price_point.dart';
import '../models/ta_indicators.dart';
import '../services/coincap_service.dart';
import '../services/favoritos_service.dart';
import '../utils/formatadores.dart';
import '../widgets/grafico_detalhes.dart';

class DetalhesAtivoScreen extends StatefulWidget {
  final String slug;
  final Asset? assetInicial;

  const DetalhesAtivoScreen({
    super.key,
    required this.slug,
    this.assetInicial,
  });

  @override
  State<DetalhesAtivoScreen> createState() => _DetalhesAtivoScreenState();
}

class _DetalhesAtivoScreenState extends State<DetalhesAtivoScreen> {
  Asset? _ativo;

  // Intervalo do gráfico ("1D", "7D", "1M", "1A")
  String _intervaloSelecionado = "7D";
  List<PricePoint> _historico = [];
  bool _carregandoHistorico = true;

  // Aba selecionada: 0 = Visão geral, 1 = Análise técnica, 2 = Onde comprar
  int _abaIndex = 0;

  // Indicadores técnicos
  TaIndicators? _indicadores;
  bool _carregandoTa = false;

  // Mercados
  List<Market> _mercados = [];
  bool _carregandoMercados = false;
  Timer? _timerAtualizacao;

  @override
  void initState() {
    super.initState();
    _ativo = widget.assetInicial;
    _carregarAtivo(forcar: false);
    _carregarHistorico();

    // Atualização em segundo plano a cada 2 minutos
    _timerAtualizacao = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        _carregarAtivo(forcar: false);
      }
    });
  }

  @override
  void dispose() {
    _timerAtualizacao?.cancel();
    super.dispose();
  }

  Future<void> _carregarAtivo({bool forcar = false}) async {
    try {
      final detalhes = await CoinCapService.buscarDetalhesAtivo(
        widget.slug,
        forcarAtualizacao: forcar,
      );
      if (mounted) {
        setState(() {
          _ativo = detalhes;
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarHistorico({bool forcar = false}) async {
    setState(() => _carregandoHistorico = true);

    String intervalParam;
    switch (_intervaloSelecionado) {
      case "1D":
        intervalParam = "m15";
        break;
      case "7D":
        intervalParam = "h1";
        break;
      case "1M":
        intervalParam = "h6";
        break;
      case "1A":
        intervalParam = "d1";
        break;
      default:
        intervalParam = "h1";
    }

    try {
      final pontos = await CoinCapService.buscarHistorico(
        widget.slug,
        interval: intervalParam,
        forcarAtualizacao: forcar,
      );
      if (mounted) {
        setState(() {
          _historico = pontos;
          _carregandoHistorico = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregandoHistorico = false;
        });
      }
    }
  }

  Future<void> _carregarIndicadores() async {
    if (_indicadores != null || _carregandoTa) return;
    setState(() => _carregandoTa = true);
    try {
      final res = await CoinCapService.buscarIndicadoresTecnicos(widget.slug);
      if (mounted) {
        setState(() {
          _indicadores = res;
          _carregandoTa = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoTa = false);
    }
  }

  Future<void> _carregarMercados() async {
    if (_mercados.isNotEmpty || _carregandoMercados) return;
    setState(() => _carregandoMercados = true);
    try {
      final res = await CoinCapService.buscarMercadosAtivo(widget.slug);
      if (mounted) {
        setState(() {
          _mercados = res;
          _carregandoMercados = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoMercados = false);
    }
  }

  void _aoMudarAba(int index) {
    setState(() => _abaIndex = index);
    if (index == 1) {
      _carregarIndicadores();
    } else if (index == 2) {
      _carregarMercados();
    }
  }

  Widget _linhaMetrica(String rotulo, String valor, {Color? valorCor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              color: corTextoSuave,
              fontSize: 14,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: valorCor ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudoAbaVisaoGeral(Asset ativo) {
    return Column(
      children: [
        _linhaMetrica("Valor de mercado", formatarCompacto(ativo.marketCap, prefixo: '\$')),
        _linhaMetrica("Volume (24h)", formatarCompacto(ativo.volume, prefixo: '\$')),
        _linhaMetrica(
          "Fornecimento circulante",
          ativo.supply != null
              ? "${formatarCompacto(ativo.supply)} ${ativo.symbol}"
              : "-",
        ),
        _linhaMetrica(
          "Fornecimento máximo",
          ativo.maxSupply != null
              ? "${formatarCompacto(ativo.maxSupply)} ${ativo.symbol}"
              : "Ilimitado",
        ),
        _linhaMetrica("VWAP (24h)", formatarPreco(ativo.vwap24Hr, prefixo: '\$')),
      ],
    );
  }

  Widget _conteudoAbaTecnica() {
    if (_carregandoTa) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: corDestaque)),
      );
    }
    if (_indicadores == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            "Indicadores técnicos indisponíveis",
            style: TextStyle(color: corTextoSuave),
          ),
        ),
      );
    }

    final rsi = _indicadores!.rsi;
    String rsiStatus = "-";
    Color rsiCor = Colors.white;
    if (rsi != null) {
      if (rsi >= 70) {
        rsiStatus = "Sobrecomprado";
        rsiCor = corVermelha;
      } else if (rsi <= 30) {
        rsiStatus = "Sobrevendido";
        rsiCor = corVerde;
      } else {
        rsiStatus = "Neutro";
        rsiCor = corDestaque;
      }
    }

    return Column(
      children: [
        _linhaMetrica(
          "RSI (Índice de Força Relativa)",
          rsi != null ? "${rsi.toStringAsFixed(1)} ($rsiStatus)" : "-",
          valorCor: rsiCor,
        ),
        _linhaMetrica("VWAP 24h", formatarPreco(_indicadores!.vwap24Hr, prefixo: '\$')),
        _linhaMetrica("SMA (Média Móvel Simples)", formatarPreco(_indicadores!.sma, prefixo: '\$')),
        _linhaMetrica("EMA (Média Móvel Exp.)", formatarPreco(_indicadores!.ema, prefixo: '\$')),
        _linhaMetrica(
          "MACD",
          _indicadores!.macd != null ? _indicadores!.macd!.toStringAsFixed(2) : "-",
        ),
        if (_indicadores!.macdSignal != null)
          _linhaMetrica("MACD Sinal", _indicadores!.macdSignal!.toStringAsFixed(2)),
      ],
    );
  }

  Widget _conteudoAbaMercados() {
    if (_carregandoMercados) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: corDestaque)),
      );
    }
    if (_mercados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            "Nenhum mercado encontrado",
            style: TextStyle(color: corTextoSuave),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mercados.take(8).length,
      separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.06)),
      itemBuilder: (context, i) {
        final m = _mercados[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: corPilula,
                child: Text(
                  m.exchangeId.isNotEmpty ? m.exchangeId[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    color: corDestaque,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.exchangeId.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${m.baseSymbol}/${m.quoteSymbol}",
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
                    formatarPreco(m.priceUsd, prefixo: '\$'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "Vol: ${formatarCompacto(m.volumeUsd24Hr, prefixo: '\$')}",
                    style: const TextStyle(
                      color: corTextoSuave,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _ativo ??
        Asset(
          slug: widget.slug,
          symbol: widget.slug.toUpperCase(),
          name: widget.slug,
          price: 0,
          historico: [],
        );

    final variacao = ativo.changePercent24Hr;
    final subiu = variacao == null || variacao >= 0;

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
          child: Column(
            children: [
              // Barra Superior: Voltar, Título e Favorito
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: corPilula.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    Text(
                      ativo.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: FavoritosService.instance.favoritosNotifier,
                      builder: (context, favoritos, _) {
                        final isFav = favoritos.contains(ativo.slug.toLowerCase());
                        return GestureDetector(
                          onTap: () {
                            FavoritosService.instance.alternar(ativo.slug);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 1),
                                backgroundColor: corCartao,
                                content: Text(
                                  isFav
                                      ? "${ativo.name} removido dos favoritos"
                                      : "${ativo.name} adicionado aos favoritos!",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: corPilula.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.star : Icons.star_border,
                              color: isFav ? const Color(0xFFFBBF24) : Colors.white70,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Conteúdo Rolável
              Expanded(
                child: RefreshIndicator(
                  color: corDestaque,
                  backgroundColor: corCartao,
                  onRefresh: () async {
                    await Future.wait([
                      _carregarAtivo(forcar: true),
                      _carregarHistorico(forcar: true),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      const SizedBox(height: 8),
                      // Símbolo e Rank
                      Text(
                        "${ativo.symbol} · #${ativo.rank ?? 1}",
                        style: const TextStyle(
                          color: corTextoSuave,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Preço Grande
                      Text(
                        formatarPreco(ativo.price, prefixo: '\$'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Variação % 24h
                      Text(
                        "${formatarPercentual(variacao)} (24h)",
                        style: TextStyle(
                          color: subiu ? corVerde : corVermelha,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Seletor de Intervalo [1D, 7D, 1M, 1A]
                      Row(
                        children: ["1D", "7D", "1M", "1A"].map((intervalo) {
                          final selecionado = _intervaloSelecionado == intervalo;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                if (_intervaloSelecionado != intervalo) {
                                  setState(() => _intervaloSelecionado = intervalo);
                                  _carregarHistorico();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selecionado ? corDestaque : corPilula,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  intervalo,
                                  style: TextStyle(
                                    color: selecionado ? const Color(0xFF0A0014) : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Gráfico do Preço
                      GraficoDetalhes(
                        pontos: _historico,
                        carregando: _carregandoHistorico,
                      ),
                      const SizedBox(height: 24),

                      // Abas Segmentadas: [Visão geral, Análise técnica, Onde comprar]
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: corPilula,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _abaBotao(0, "Visão geral"),
                            _abaBotao(1, "Análise técnica"),
                            _abaBotao(2, "Onde comprar"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Conteúdo da Aba Ativa
                      IndexedStack(
                        index: _abaIndex,
                        children: [
                          _conteudoAbaVisaoGeral(ativo),
                          _conteudoAbaTecnica(),
                          _conteudoAbaMercados(),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _abaBotao(int index, String rotulo) {
    final ativa = _abaIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _aoMudarAba(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: ativa ? corCartao : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            rotulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ativa ? Colors.white : corTextoSuave,
              fontSize: 12.5,
              fontWeight: ativa ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
