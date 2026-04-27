// ── IPO / FPO Model ──────────────────────────────────────────────────────────
class IpoModel {
  final String symbol;
  final String companyName;
  final String type; // IPO, FPO, Debenture, Mutual Fund
  final double sharePrice;
  final int totalUnits;
  final String openDate;
  final String closeDate;
  final String status; // Open, Upcoming, Closed, Allotted
  final String sector;
  final String? logoUrl;

  IpoModel({
    required this.symbol,
    required this.companyName,
    required this.type,
    required this.sharePrice,
    required this.totalUnits,
    required this.openDate,
    required this.closeDate,
    required this.status,
    required this.sector,
    this.logoUrl,
  });

  factory IpoModel.fromJson(Map<String, dynamic> json) => IpoModel(
        symbol: json['symbol'] ?? '',
        companyName: json['companyName'] ?? json['name'] ?? '',
        type: json['type'] ?? 'IPO',
        sharePrice: double.tryParse(json['sharePrice']?.toString() ?? '100') ?? 100,
        totalUnits: int.tryParse(json['totalUnits']?.toString() ?? '0') ?? 0,
        openDate: json['openDate'] ?? '',
        closeDate: json['closeDate'] ?? '',
        status: json['status'] ?? 'Upcoming',
        sector: json['sector'] ?? '',
        logoUrl: json['logoUrl'],
      );
}

// ── Right Share Model ────────────────────────────────────────────────────────
class RightShareModel {
  final String symbol;
  final String companyName;
  final String ratio; // e.g. "1:0.5"
  final double sharePrice;
  final String openDate;
  final String closeDate;
  final String status;
  final String sector;

  RightShareModel({
    required this.symbol,
    required this.companyName,
    required this.ratio,
    required this.sharePrice,
    required this.openDate,
    required this.closeDate,
    required this.status,
    required this.sector,
  });

  factory RightShareModel.fromJson(Map<String, dynamic> json) => RightShareModel(
        symbol: json['symbol'] ?? '',
        companyName: json['companyName'] ?? '',
        ratio: json['ratio'] ?? '',
        sharePrice: double.tryParse(json['sharePrice']?.toString() ?? '100') ?? 100,
        openDate: json['openDate'] ?? '',
        closeDate: json['closeDate'] ?? '',
        status: json['status'] ?? 'Upcoming',
        sector: json['sector'] ?? '',
      );
}

// ── Bonus / Dividend Model ───────────────────────────────────────────────────
class BonusModel {
  final String symbol;
  final String companyName;
  final double bonusPercent;
  final double cashDividend;
  final double? rightPercent;
  final String bookCloseDate;
  final String status; // Announced, Approved, Distributed
  final String fiscalYear;
  final String sector;
  final bool isCreditBonus; // credit bonus vs stock bonus

  BonusModel({
    required this.symbol,
    required this.companyName,
    required this.bonusPercent,
    required this.cashDividend,
    this.rightPercent,
    required this.bookCloseDate,
    required this.status,
    required this.fiscalYear,
    required this.sector,
    this.isCreditBonus = false,
  });

  factory BonusModel.fromJson(Map<String, dynamic> json) => BonusModel(
        symbol: json['symbol'] ?? '',
        companyName: json['companyName'] ?? '',
        bonusPercent: double.tryParse(json['bonus']?.toString() ?? '0') ?? 0,
        cashDividend: double.tryParse(json['cash']?.toString() ?? '0') ?? 0,
        rightPercent: double.tryParse(json['right']?.toString() ?? '0'),
        bookCloseDate: json['bookCloseDate'] ?? '',
        status: json['status'] ?? 'Announced',
        fiscalYear: json['fiscalYear'] ?? '',
        sector: json['sector'] ?? '',
        isCreditBonus: json['isCreditBonus'] ?? false,
      );
}

// ── Promoter Share Unlock Model ──────────────────────────────────────────────
class PromoterShareModel {
  final String symbol;
  final String companyName;
  final double units;
  final String unlockDate;
  final double pricePerUnit;
  final String status; // Locked, Unlocking Soon, Unlocked, On Sale
  final String daysLeft;
  final String sector;

  PromoterShareModel({
    required this.symbol,
    required this.companyName,
    required this.units,
    required this.unlockDate,
    required this.pricePerUnit,
    required this.status,
    required this.daysLeft,
    required this.sector,
  });

  factory PromoterShareModel.fromJson(Map<String, dynamic> json) => PromoterShareModel(
        symbol: json['symbol'] ?? '',
        companyName: json['companyName'] ?? '',
        units: double.tryParse(json['units']?.toString() ?? '0') ?? 0,
        unlockDate: json['unlockDate'] ?? '',
        pricePerUnit: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        status: json['status'] ?? 'Locked',
        daysLeft: json['daysLeft']?.toString() ?? '—',
        sector: json['sector'] ?? '',
      );
}

// ── Live Stock Price Model ───────────────────────────────────────────────────
class StockModel {
  final String symbol;
  final String companyName;
  final double ltp; // Last Traded Price
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double previousClose;
  final int volume;
  final double turnover;
  final String sector;

  StockModel({
    required this.symbol,
    required this.companyName,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.previousClose,
    required this.volume,
    required this.turnover,
    required this.sector,
  });

  bool get isPositive => change >= 0;

  factory StockModel.fromJson(Map<String, dynamic> json) => StockModel(
        symbol: json['symbol'] ?? '',
        companyName: json['securityName'] ?? json['companyName'] ?? '',
        ltp: double.tryParse(json['lastTradedPrice']?.toString() ?? json['ltp']?.toString() ?? '0') ?? 0,
        change: double.tryParse(json['percentageChange']?.toString() ?? '0') ?? 0,
        changePercent: double.tryParse(json['percentageChange']?.toString() ?? '0') ?? 0,
        open: double.tryParse(json['openPrice']?.toString() ?? '0') ?? 0,
        high: double.tryParse(json['highPrice']?.toString() ?? '0') ?? 0,
        low: double.tryParse(json['lowPrice']?.toString() ?? '0') ?? 0,
        previousClose: double.tryParse(json['previousClose']?.toString() ?? '0') ?? 0,
        volume: int.tryParse(json['totalTradeQuantity']?.toString() ?? '0') ?? 0,
        turnover: double.tryParse(json['totalTradeValue']?.toString() ?? '0') ?? 0,
        sector: json['sector'] ?? '',
      );
}

// ── Floorsheet / Broker Activity Model ──────────────────────────────────────
class FloorsheetEntry {
  final int transactionId;
  final String symbol;
  final int buyerBroker;
  final int sellerBroker;
  final int quantity;
  final double rate;
  final double amount;
  final String time;

  FloorsheetEntry({
    required this.transactionId,
    required this.symbol,
    required this.buyerBroker,
    required this.sellerBroker,
    required this.quantity,
    required this.rate,
    required this.amount,
    required this.time,
  });

  factory FloorsheetEntry.fromJson(Map<String, dynamic> json) => FloorsheetEntry(
        transactionId: int.tryParse(json['contractId']?.toString() ?? '0') ?? 0,
        symbol: json['stockSymbol'] ?? '',
        buyerBroker: int.tryParse(json['buyerMemberId']?.toString() ?? '0') ?? 0,
        sellerBroker: int.tryParse(json['sellerMemberId']?.toString() ?? '0') ?? 0,
        quantity: int.tryParse(json['contractQuantity']?.toString() ?? '0') ?? 0,
        rate: double.tryParse(json['contractRate']?.toString() ?? '0') ?? 0,
        amount: double.tryParse(json['contractAmount']?.toString() ?? '0') ?? 0,
        time: json['tradeBookId']?.toString() ?? '',
      );
}

class BrokerActivity {
  final int brokerId;
  final String brokerName;
  final int buyQuantity;
  final int sellQuantity;
  final double buyAmount;
  final double sellAmount;
  final int netPosition; // buy - sell

  BrokerActivity({
    required this.brokerId,
    required this.brokerName,
    required this.buyQuantity,
    required this.sellQuantity,
    required this.buyAmount,
    required this.sellAmount,
    required this.netPosition,
  });
}

// ── Market Summary ────────────────────────────────────────────────────────────
class MarketSummary {
  final double nepseIndex;
  final double change;
  final double changePercent;
  final double totalTurnover;
  final int totalTransactions;
  final int totalTradedShares;
  final int totalScrips;
  final bool isMarketOpen;

  MarketSummary({
    required this.nepseIndex,
    required this.change,
    required this.changePercent,
    required this.totalTurnover,
    required this.totalTransactions,
    required this.totalTradedShares,
    required this.totalScrips,
    required this.isMarketOpen,
  });

  bool get isPositive => change >= 0;
}
