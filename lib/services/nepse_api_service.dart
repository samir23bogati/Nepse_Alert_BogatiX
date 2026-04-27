import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class NepseApiService {
  // Official NEPSE API base
  static const String _nepseBase = 'https://www.nepalstock.com/api';
  // ShareSansar & Merolagani for corporate actions
  static const String _sharesansarBase = 'https://www.sharesansar.com';
  static const String _merolaganiBase = 'https://merolagani.com';

  // Custom API (deploy to Render.com for free)
  // Replace this with your deployed Render URL after deployment
  static const String _customApiBase = 'https://your-app-name.onrender.com/api';
  static bool _useCustomApi = false; // Set to true after deployment

  static final NepseApiService _instance = NepseApiService._internal();
  factory NepseApiService() => _instance;
  NepseApiService._internal();

  final _client = http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; NepseTracker/1.0)',
        'Referer': 'https://www.nepalstock.com/',
      };

  // ── Market Summary ──────────────────────────────────────────────────────
  Future<MarketSummary> getMarketSummary() async {
    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/nepse-data/market-open'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final marketStat = data['marketStatus'] ?? {};
        return MarketSummary(
          nepseIndex:
              double.tryParse(marketStat['nepseIndex']?.toString() ?? '0') ?? 0,
          change: double.tryParse(
                  marketStat['currentDifference']?.toString() ?? '0') ??
              0,
          changePercent: double.tryParse(
                  marketStat['percentageChange']?.toString() ?? '0') ??
              0,
          totalTurnover:
              double.tryParse(marketStat['totalTurnover']?.toString() ?? '0') ??
                  0,
          totalTransactions: int.tryParse(
                  marketStat['totalTransactions']?.toString() ?? '0') ??
              0,
          totalTradedShares: int.tryParse(
                  marketStat['totalTradedShares']?.toString() ?? '0') ??
              0,
          totalScrips:
              int.tryParse(marketStat['totalScrips']?.toString() ?? '0') ?? 0,
          isMarketOpen: marketStat['isOpen'] == 'OPEN',
        );
      }
    } catch (_) {}
    return _mockMarketSummary();
  }

  // ── Live Stock Prices ────────────────────────────────────────────────────
  Future<List<StockModel>> getLiveStocks({String? sector}) async {
    try {
      final res = await _client.post(
        Uri.parse('$_nepseBase/nots/security/floorsheet'),
        headers: _headers,
        body: json.encode({
          'page': 0,
          'size': 50,
          'sort': 'contractId,desc',
        }),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data['floorsheets']?['content'] as List? ?? [];
        return list.map((e) => StockModel.fromJson(e)).toList();
      }
    } catch (_) {}
    // Fallback: official today's price list
    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/market/securities/headings'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => StockModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockStocks();
  }

  // ── Floorsheet ────────────────────────────────────────────────────────────
  Future<List<FloorsheetEntry>> getFloorsheet({
    String? symbol,
    int page = 0,
    int size = 100,
  }) async {
    try {
      final body = <String, dynamic>{
        'page': page,
        'size': size,
        'sort': 'contractId,desc',
      };
      if (symbol != null && symbol.isNotEmpty) {
        body['stockSymbol'] = symbol;
      }
      final res = await _client.post(
        Uri.parse('$_nepseBase/nots/security/floorsheet'),
        headers: _headers,
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data['floorsheets']?['content'] as List? ?? [];
        return list.map((e) => FloorsheetEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockFloorsheet(symbol ?? 'NABIL');
  }

  // ── Broker Activity (aggregated from floorsheet) ─────────────────────────
  Future<List<BrokerActivity>> getBrokerActivity(String symbol) async {
    final floorsheet = await getFloorsheet(symbol: symbol, size: 500);

    final Map<int, Map<String, dynamic>> brokerMap = {};

    for (final entry in floorsheet) {
      // Buyer
      if (!brokerMap.containsKey(entry.buyerBroker)) {
        brokerMap[entry.buyerBroker] = {
          'buyQty': 0,
          'sellQty': 0,
          'buyAmt': 0.0,
          'sellAmt': 0.0
        };
      }
      brokerMap[entry.buyerBroker]!['buyQty'] += entry.quantity;
      brokerMap[entry.buyerBroker]!['buyAmt'] += entry.amount;

      // Seller
      if (!brokerMap.containsKey(entry.sellerBroker)) {
        brokerMap[entry.sellerBroker] = {
          'buyQty': 0,
          'sellQty': 0,
          'buyAmt': 0.0,
          'sellAmt': 0.0
        };
      }
      brokerMap[entry.sellerBroker]!['sellQty'] += entry.quantity;
      brokerMap[entry.sellerBroker]!['sellAmt'] += entry.amount;
    }

    final activities = brokerMap.entries
        .map((e) => BrokerActivity(
              brokerId: e.key,
              brokerName: 'Broker ${e.key}',
              buyQuantity: e.value['buyQty'],
              sellQuantity: e.value['sellQty'],
              buyAmount: e.value['buyAmt'],
              sellAmount: e.value['sellAmt'],
              netPosition: e.value['buyQty'] - e.value['sellQty'],
            ))
        .toList();

    activities.sort((a, b) => (b.buyQuantity + b.sellQuantity)
        .compareTo(a.buyQuantity + a.sellQuantity));

    return activities.take(20).toList();
  }

// ── IPO Data (from merolagani) ───────────────────────────────────────────
  Future<List<IpoModel>> getActiveIpos() async {
    // Custom API (deployed on Render.com)
    if (_useCustomApi) {
      try {
        final res = await _client.get(
          Uri.parse('$_customApiBase/ipo'),
          headers: _headers,
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List;
          return data.map((e) => IpoModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    // NEPSE official IPO endpoint
    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/public-issue/open-public-issue'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => IpoModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockIpos();
  }

  Future<List<IpoModel>> getUpcomingIpos() async {
    // Custom API (deployed on Render.com)
    if (_useCustomApi) {
      try {
        final res = await _client.get(
          Uri.parse('$_customApiBase/ipo'),
          headers: _headers,
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List;
          final allIpos = data.map((e) => IpoModel.fromJson(e)).toList();
          return allIpos
              .where((ipo) =>
                  ipo.status.toLowerCase() == 'upcoming' ||
                  ipo.status.toLowerCase() == 'coming soon')
              .toList();
        }
      } catch (_) {}
    }

    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/public-issue/upcoming-public-issue'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => IpoModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockUpcomingIpos();
  }

  // ── Right Shares ──────────────────────────────────────────────────────────
  Future<List<RightShareModel>> getRightShares() async {
    // Custom API (deployed on Render.com)
    if (_useCustomApi) {
      try {
        final res = await _client.get(
          Uri.parse('$_customApiBase/right-share'),
          headers: _headers,
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List;
          return data.map((e) => RightShareModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/rights-share/open'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => RightShareModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockRightShares();
  }

  // ── Bonus & Dividends ─────────────────────────────────────────────────────
  Future<List<BonusModel>> getBonusData() async {
    // Custom API (deployed on Render.com)
    if (_useCustomApi) {
      try {
        final res = await _client.get(
          Uri.parse('$_customApiBase/bonus'),
          headers: _headers,
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List;
          return data.map((e) => BonusModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/bonus-share/announced'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => BonusModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockBonus();
  }

  // ── Promoter Share Unlock ─────────────────────────────────────────────────
  Future<List<PromoterShareModel>> getPromoterShares() async {
    // Custom API (deployed on Render.com)
    if (_useCustomApi) {
      try {
        final res = await _client.get(
          Uri.parse('$_customApiBase/promoter'),
          headers: _headers,
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List;
          return data.map((e) => PromoterShareModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    try {
      final res = await _client.get(
        Uri.parse('$_nepseBase/nots/promoter-share/unlocking'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((e) => PromoterShareModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockPromoterShares();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MOCK DATA (used when API is unreachable / during development)
  // ════════════════════════════════════════════════════════════════════════════

  MarketSummary _mockMarketSummary() => MarketSummary(
        nepseIndex: 2387.45,
        change: 23.67,
        changePercent: 1.00,
        totalTurnover: 4823456780,
        totalTransactions: 58234,
        totalTradedShares: 12456789,
        totalScrips: 198,
        isMarketOpen: true,
      );

  List<StockModel> _mockStocks() => [
        StockModel(
            symbol: 'NABIL',
            companyName: 'Nabil Bank Limited',
            ltp: 985.0,
            change: 15.0,
            changePercent: 1.55,
            open: 972.0,
            high: 990.0,
            low: 970.0,
            previousClose: 970.0,
            volume: 34521,
            turnover: 33800000,
            sector: 'Commercial Banks'),
        StockModel(
            symbol: 'NICA',
            companyName: 'NIC Asia Bank',
            ltp: 672.0,
            change: -8.0,
            changePercent: -1.18,
            open: 680.0,
            high: 682.0,
            low: 668.0,
            previousClose: 680.0,
            volume: 28100,
            turnover: 18900000,
            sector: 'Commercial Banks'),
        StockModel(
            symbol: 'NRIC',
            companyName: 'Nepal Reinsurance Company',
            ltp: 1340.0,
            change: 45.0,
            changePercent: 3.47,
            open: 1300.0,
            high: 1350.0,
            low: 1295.0,
            previousClose: 1295.0,
            volume: 8900,
            turnover: 11900000,
            sector: 'Non Life Insurance'),
        StockModel(
            symbol: 'HIDCL',
            companyName: 'Hydroelectricity Investment',
            ltp: 298.0,
            change: -5.0,
            changePercent: -1.65,
            open: 304.0,
            high: 305.0,
            low: 296.0,
            previousClose: 303.0,
            volume: 67300,
            turnover: 20100000,
            sector: 'Hydropower'),
        StockModel(
            symbol: 'SHIVM',
            companyName: 'Shivam Cements',
            ltp: 450.0,
            change: 12.0,
            changePercent: 2.74,
            open: 440.0,
            high: 455.0,
            low: 438.0,
            previousClose: 438.0,
            volume: 12400,
            turnover: 5580000,
            sector: 'Manufacturing'),
        StockModel(
            symbol: 'GBIME',
            companyName: 'Global IME Bank',
            ltp: 241.0,
            change: 3.0,
            changePercent: 1.26,
            open: 238.0,
            high: 245.0,
            low: 237.0,
            previousClose: 238.0,
            volume: 98700,
            turnover: 23800000,
            sector: 'Commercial Banks'),
        StockModel(
            symbol: 'SBL',
            companyName: 'Siddhartha Bank',
            ltp: 312.0,
            change: -4.0,
            changePercent: -1.27,
            open: 317.0,
            high: 318.0,
            low: 310.0,
            previousClose: 316.0,
            volume: 45600,
            turnover: 14200000,
            sector: 'Commercial Banks'),
        StockModel(
            symbol: 'NLG',
            companyName: 'Nepal Life Insurance',
            ltp: 2340.0,
            change: 60.0,
            changePercent: 2.63,
            open: 2280.0,
            high: 2360.0,
            low: 2275.0,
            previousClose: 2280.0,
            volume: 5430,
            turnover: 12600000,
            sector: 'Life Insurance'),
      ];

  List<FloorsheetEntry> _mockFloorsheet(String symbol) =>
      List.generate(30, (i) {
        final buyers = [1, 3, 5, 7, 11, 21, 34, 42, 55, 58];
        final sellers = [2, 4, 6, 8, 12, 22, 35, 43, 56, 59];
        return FloorsheetEntry(
          transactionId: 1000000 + i,
          symbol: symbol,
          buyerBroker: buyers[i % buyers.length],
          sellerBroker: sellers[i % sellers.length],
          quantity: (i + 1) * 50,
          rate: 985.0 + (i % 5) - 2,
          amount: ((i + 1) * 50) * (985.0 + (i % 5) - 2),
          time:
              '${10 + i ~/ 6}:${(i * 10) % 60 < 10 ? '0' : ''}${(i * 10) % 60}',
        );
      });

  List<IpoModel> _mockIpos() => [
        IpoModel(
            symbol: 'YAMBH',
            companyName: 'Yambaling Hydropower Ltd',
            type: 'IPO',
            sharePrice: 100,
            totalUnits: 1743000,
            openDate: '2082-01-16',
            closeDate: '2082-01-22',
            status: 'Open',
            sector: 'Hydropower'),
        IpoModel(
            symbol: 'NPHB',
            companyName: 'Norvic International Hospital',
            type: 'IPO',
            sharePrice: 250,
            totalUnits: 2500000,
            openDate: '2082-01-25',
            closeDate: '2082-01-29',
            status: 'Upcoming',
            sector: 'Others'),
      ];

  List<IpoModel> _mockUpcomingIpos() => [
        IpoModel(
            symbol: 'SEF2',
            companyName: 'Siddhartha Equity Fund 2',
            type: 'Mutual Fund',
            sharePrice: 10,
            totalUnits: 85000000,
            openDate: '2082-01-21',
            closeDate: '2082-01-24',
            status: 'Upcoming',
            sector: 'Mutual Fund'),
        IpoModel(
            symbol: 'APPLO',
            companyName: 'Apollo Hydropower Ltd',
            type: 'IPO',
            sharePrice: 100,
            totalUnits: 780200,
            openDate: '2082-02-01',
            closeDate: '2082-02-05',
            status: 'Upcoming',
            sector: 'Hydropower'),
      ];

  List<RightShareModel> _mockRightShares() => [
        RightShareModel(
            symbol: 'UAIL',
            companyName: 'United Ajod Insurance Ltd',
            ratio: '100:10',
            sharePrice: 100,
            openDate: '2082-01-01',
            closeDate: '2082-01-16',
            status: 'Open',
            sector: 'Non Life Insurance'),
        RightShareModel(
            symbol: 'HPL',
            companyName: 'Himalayan Power Partner Ltd',
            ratio: '1:0.5',
            sharePrice: 100,
            openDate: '2082-01-17',
            closeDate: '2082-02-06',
            status: 'Open',
            sector: 'Hydropower'),
        RightShareModel(
            symbol: 'KSBBL',
            companyName: 'Kumari Bank Ltd',
            ratio: '1:0.3',
            sharePrice: 100,
            openDate: '2082-02-10',
            closeDate: '2082-03-01',
            status: 'Upcoming',
            sector: 'Commercial Banks'),
      ];

  List<BonusModel> _mockBonus() => [
        BonusModel(
            symbol: 'MLBBL',
            companyName: 'Mithila Laghubitta',
            bonusPercent: 14.25,
            cashDividend: 0,
            bookCloseDate: '2082-01-10',
            status: 'Distributed',
            fiscalYear: '2079/80',
            sector: 'Microfinance',
            isCreditBonus: false),
        BonusModel(
            symbol: 'UMHL',
            companyName: 'United Modi Hydropower Ltd',
            bonusPercent: 7.0,
            cashDividend: 2.0,
            bookCloseDate: '2082-01-15',
            status: 'Approved',
            fiscalYear: '2079/80',
            sector: 'Hydropower'),
        BonusModel(
            symbol: 'NABIL',
            companyName: 'Nabil Bank Ltd',
            bonusPercent: 10.0,
            cashDividend: 5.0,
            bookCloseDate: '2082-02-01',
            status: 'Announced',
            fiscalYear: '2079/80',
            sector: 'Commercial Banks'),
        BonusModel(
            symbol: 'GBIME',
            companyName: 'Global IME Bank',
            bonusPercent: 0,
            cashDividend: 8.0,
            bookCloseDate: '2082-02-05',
            status: 'Announced',
            fiscalYear: '2079/80',
            sector: 'Commercial Banks',
            isCreditBonus: true),
      ];

  List<PromoterShareModel> _mockPromoterShares() => [
        PromoterShareModel(
            symbol: 'CHHL',
            companyName: 'City Hotel Ltd',
            units: 27239328,
            unlockDate: '2082-02-05',
            pricePerUnit: 142.0,
            status: 'Unlocking Soon',
            daysLeft: '8 days',
            sector: 'Hotels'),
        PromoterShareModel(
            symbol: 'PRABHU',
            companyName: 'Prabhu Bank Ltd',
            units: 244124,
            unlockDate: '2082-01-28',
            pricePerUnit: 310.0,
            status: 'On Sale',
            daysLeft: 'Now',
            sector: 'Commercial Banks'),
        PromoterShareModel(
            symbol: 'CBIL',
            companyName: 'Citizen Bank Int\'l Ltd',
            units: 1444084,
            unlockDate: '2082-01-20',
            pricePerUnit: 106.0,
            status: 'On Sale',
            daysLeft: 'Now',
            sector: 'Commercial Banks'),
        PromoterShareModel(
            symbol: 'KMBL',
            companyName: 'Kumari Bank Ltd',
            units: 7883,
            unlockDate: '2082-02-15',
            pricePerUnit: 198.0,
            status: 'Locked',
            daysLeft: '19 days',
            sector: 'Commercial Banks'),
      ];
}
