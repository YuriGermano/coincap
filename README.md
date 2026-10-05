# CoinCap - Rastreador & Conversor de Criptomoedas

---

## Funcionalidades Principais

- **Mercado em Tempo Real**:
  - Listagem dos principais ativos ordenados por valor de mercado (*Market Cap*), preço, ranking e variação nas últimas 24h.
  - Carrossel com as **Maiores Altas e Baixas** (*Top Movers*) calculados dinamicamente.
  - Cards de acesso rápido no topo para **Comparar Ativos** e **Corretoras**.
  - Atualização automática em segundo plano e suporte a recarregamento manual (*Pull-to-Refresh*).

- **Busca Inteligente**:
  - Pesquisa instantânea por nome, símbolo ou *slug* com sistema de *debounce* (sem sobrecarregar a rede).
  - Sugestões dos ativos mais populares e busca com *fallback* em memória.

- **Moedas Favoritas**:
  - Salve suas criptomoedas preferidas para acesso rápido.
  - Persistência local no dispositivo (`SharedPreferences`) e atualização reativa em tempo real com `ValueNotifier`.

- **Conversor de Câmbio & Cripto**:
  - Conversão instantânea bidirecional entre dezenas de moedas fiduciárias (BRL, USD, EUR, GBP, etc.) e criptoativos (BTC, ETH, SOL, DOGE, etc.).
  - Taxas atualizadas e cálculo instantâneo.

- **Comparador de Ativos**:
  - Compare até 10 criptomoedas simultaneamente lado a lado.
  - Mini-gráficos de tendência (*sparklines*), preços, variação 24h, capitalização, volume e fornecimento em circulação (*circulating supply*).
  - Modal para adicionar ou remover ativos facilmente.

- **Listagem de Corretoras (Exchanges)**:
  - Ranking global das principais corretoras com volume em USD e percentual de participação de mercado.
  - Filtros e ordenação por Volume, Número de Pares de Negociação e Ordem Alfabética.
  - Visualização detalhada dos pares negociados em cada corretora com cotações e volumes individuais.

- **Detalhes do Ativo**:
  - Gráfico interativo com seleção de intervalos temporais (**1D**, **7D**, **1M**, **1A**).
  - Métricas financeiras (VWAP 24h, Supply, Max Supply, Market Cap, Volume).
  - Indicadores técnicos (RSI, Médias Móveis SMA/EMA, MACD).
  - Mercados onde o ativo específico é transacionado.

---

## Tecnologias Utilizadas

- **Framework**: [Flutter](https://flutter.dev/) (Dart `>=3.12.0 <4.0.0`)
- **Comunicação HTTP**: Pacote oficial [`http`](https://pub.dev/packages/http).
- **Ícones**: Material Design Icons & Cupertino Icons.
- **Persistência**: `SharedPreferences` para preferências e lista de favoritos.

---

## Pré-requisitos

Antes de iniciar, certifique-se de ter instalado em seu computador:

1. **Git**: Para clonar o repositório ([Download Git](https://git-scm.com/)).
2. **Flutter SDK**: Versão estável recente (recomendado Flutter 3.22 ou superior) ([Instalação do Flutter](https://docs.flutter.dev/get-started/install)).
3. **Dart SDK**: Já incluso na instalação do Flutter.
4. Um editor de código de sua preferência:
   - [VS Code](https://code.visualstudio.com/) com extensões **Flutter** e **Dart**.
   - [Android Studio](https://developer.android.com/studio) configurado com emulador Android.
5. Um dispositivo de execução:
   - Emulador Android ou iOS.
   - Dispositivo físico conectado via USB com depuração ativada.
   - Navegador Chrome ou Desktop (Windows/Linux/macOS) caso habilitado no Flutter.

---

## Guia Passo a Passo: Do Clone à Execução

### 1. Clonar o Repositório

Abra o terminal (Prompt de Comando, PowerShell ou Terminal do Linux/macOS) e execute:

```bash
git clone https://github.com/YuriGermano/coincap.git
```

### 2. Acessar o Diretório do Projeto

```bash
cd coincap
```

### 3. Verificar o Ambiente Flutter

Verifique se todas as dependências do ambiente Flutter estão configuradas corretamente:

```bash
flutter doctor
```

### 4. Instalar as Dependências

Baixe os pacotes necessários especificados no `pubspec.yaml`:

```bash
flutter pub get
```

### 5. Identificar Dispositivos Conectados

Para listar os dispositivos, emuladores e navegadores disponíveis para execução:

```bash
flutter devices
```

### 6. Executar o Aplicativo

Para rodar o app no dispositivo padrão conectado:

```bash
flutter run
```

Se desejar especificar um dispositivo (por exemplo, no emulador Android ou no Windows Desktop):

```bash
# Executar em um dispositivo específico (obtenha o ID com flutter devices)
flutter run -d <DEVICE_ID>

# Exemplo para Windows Desktop:
flutter run -d windows

# Exemplo para Google Chrome:
flutter run -d chrome
```

---

## Testes e Qualidade de Código

Para garantir que o código está íntegro e sem erros de lint ou falhas nos testes:

### Análise Estática de Código (Linter)
```bash
flutter analyze
```

### Executar a Suíte de Testes
```bash
flutter test

```

---

## Atalhos Úteis no Terminal Durante a Execução (`flutter run`)

- `r`: **Hot Reload** (recarrega alterações de código na tela quase instantaneamente).
- `R`: **Hot Restart** (reinicia o estado da aplicação rapidamente).
- `q`: Encerra o aplicativo e desanexa o terminal.
- `h`: Exibe a lista completa de comandos de desenvolvimento.