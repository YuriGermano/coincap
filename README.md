# CoinCap (CoinMaster)

Aplicativo Flutter para rastreamento, conversão e análise de criptomoedas em tempo real, consumindo a API pública da CoinCap.

---

##  Funcionalidades

- **Mercado em Tempo Real**: Cotações, variação em 24h, ranking de market cap e destaques de maiores altas/baixas (*Top Movers*).
- **Busca Rápida**: Pesquisa instantânea por nome ou símbolo com suporte a *debounce*.
- **Detalhes do Ativo**: Gráficos históricos (1D, 7D, 1M, 1A), estatísticas de mercado e indicadores técnicos.
- **Conversor**: Conversão direta entre moedas fiduciárias (BRL, USD, EUR, etc.) e criptoativos.
- **Comparador**: Comparação lado a lado de múltiplos ativos com métricas e sparklines.
- **Corretoras (Exchanges)**: Listagem e ranking das principais exchanges e seus pares de negociação.
- **Favoritos & Perfil**: Sistema de autenticação local (login/cadastro) com persistência de favoritos por usuário.

---

##  Tecnologias

- **Framework**: [Flutter](https://flutter.dev/) (Dart `>=3.12.0 <4.0.0`)
- **API**: [CoinCap API v3](https://coincap.io/) via pacote `http`
- **Banco de Dados Local**: `sqflite` (autenticação e favoritos) & `crypto` (hash de senhas)
- **Configuração**: `flutter_dotenv`

---

##  Como Executar

### 1. Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e configurado.

### 2. Clonar e Configurar

```bash
# Clone o repositório
git clone https://github.com/YuriGermano/coincap.git
cd coincap

# Crie o arquivo .env a partir do exemplo

Configuração do arquivo `.env`:
```
API_BASE_URL=https://rest.coincap.io/v3
API_KEY=sua_chave_aqui
API_TIMEOUT=30000
```

### 3. Instalar Dependências e Executar

```bash
flutter pub get
flutter run
```

---

##  Testes

Para executar os testes automatizados:

```bash
flutter test
```