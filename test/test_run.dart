import 'package:coincap/services/coincap_service.dart';

void main() async {
  final funcs = <String, Future Function()>{
    'buscarListaAtivos': () => CoinCapService.buscarListaAtivos(),
    'buscarDetalhesAtivo': () => CoinCapService.buscarDetalhesAtivo('bitcoin'),
    'buscarHistorico': () => CoinCapService.buscarHistorico('bitcoin'),
    'buscarMercadosAtivo': () => CoinCapService.buscarMercadosAtivo('bitcoin'),
    'buscarCorretoras': () => CoinCapService.buscarCorretoras(),
    'buscarMercados': () => CoinCapService.buscarMercados('binance'),
    'buscarMercadosComFiltro': () => CoinCapService.buscarMercadosComFiltro(baseSymbol: 'BTC', quoteSymbol: 'USDT'),
    'buscarTaxas': () => CoinCapService.buscarTaxas(),
    'buscarTaxaIndividual': () => CoinCapService.buscarTaxaIndividual('bitcoin'),
    'buscarIndicadoresTecnicos': () => CoinCapService.buscarIndicadoresTecnicos('bitcoin'),
    'buscarVelas': () => CoinCapService.buscarVelas('bitcoin'),
    'buscarHistoricoCompactado': () => CoinCapService.buscarHistoricoCompactado('bitcoin'),
    'buscarAtivosPorNome': () => CoinCapService.buscarAtivosPorNome('bitcoin'),
    'buscarTopMovers gainers': () => CoinCapService.buscarTopMovers(direction: 'gainers'),
    'buscarTopMovers losers': () => CoinCapService.buscarTopMovers(direction: 'losers'),
    'buscarAtivos': () => CoinCapService.buscarAtivos(['bitcoin', 'ethereum']),
  };

  for (final entry in funcs.entries) {
    try {
      final res = await entry.value();
      print('[OK] ${entry.key}: $res');
    } catch (e) {
      print('[ERRO] ${entry.key}: $e');
    }
  }
}
