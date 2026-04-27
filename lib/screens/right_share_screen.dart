// ─────────────────────────────────────────────────────────────────────────────
// RIGHT SHARE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/nepse_api_service.dart';
import '../widgets/common_widgets.dart';

class RightShareScreen extends StatefulWidget {
  const RightShareScreen({super.key});
  @override
  State<RightShareScreen> createState() => _RightShareScreenState();
}

class _RightShareScreenState extends State<RightShareScreen> {
  final _api = NepseApiService();
  List<RightShareModel> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _data = await _api.getRightShares();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Right Shares')),
      body: _loading
          ? ListView.builder(itemCount: 4, itemBuilder: (_, __) => const ShimmerCard(height: 120))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              child: _data.isEmpty
                  ? const EmptyState(message: 'No active right shares', icon: Icons.account_balance_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) => _RightShareCard(item: _data[i]),
                    ),
            ),
    );
  }
}

class _RightShareCard extends StatelessWidget {
  final RightShareModel item;
  const _RightShareCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.companyName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    Row(children: [
                      Text(item.symbol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: 6),
                      SectorBadge(item.sector),
                    ]),
                  ],
                ),
              ),
              StatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem('Ratio', item.ratio),
                _infoItem('Price', 'Rs. ${item.sharePrice.toStringAsFixed(0)}'),
                _infoItem('Opens', item.openDate),
                _infoItem('Closes', item.closeDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// BONUS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class BonusScreen extends StatefulWidget {
  const BonusScreen({super.key});
  @override
  State<BonusScreen> createState() => _BonusScreenState();
}

class _BonusScreenState extends State<BonusScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _api = NepseApiService();
  List<BonusModel> _all = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await _api.getBonusData();
    setState(() => _loading = false);
  }

  List<BonusModel> get _bonus => _all.where((b) => b.bonusPercent > 0 && !b.isCreditBonus).toList();
  List<BonusModel> get _cash => _all.where((b) => b.cashDividend > 0).toList();
  List<BonusModel> get _credit => _all.where((b) => b.isCreditBonus).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Bonus & Dividends'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Bonus Share'), Tab(text: 'Cash Div'), Tab(text: 'Credit Bonus')],
        ),
      ),
      body: _loading
          ? ListView.builder(itemCount: 4, itemBuilder: (_, __) => const ShimmerCard(height: 120))
          : TabBarView(
              controller: _tab,
              children: [
                _BonusList(items: _bonus, type: 'bonus', onRefresh: _load),
                _BonusList(items: _cash, type: 'cash', onRefresh: _load),
                _BonusList(items: _credit, type: 'credit', onRefresh: _load),
              ],
            ),
    );
  }
}

class _BonusList extends StatelessWidget {
  final List<BonusModel> items;
  final String type;
  final Future<void> Function() onRefresh;
  const _BonusList({required this.items, required this.type, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyState(message: 'No data available', icon: Icons.card_giftcard_outlined);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _BonusCard(item: items[i], type: type),
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  final BonusModel item;
  final String type;
  const _BonusCard({required this.item, required this.type});

  Color get _color => type == 'bonus' ? AppColors.green : type == 'cash' ? AppColors.orange : AppColors.purple;
  IconData get _icon => type == 'bonus' ? Icons.card_giftcard_rounded : type == 'cash' ? Icons.payments_rounded : Icons.savings_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.companyName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                Row(children: [
                  Text(item.symbol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  SectorBadge(item.sector),
                ]),
                const SizedBox(height: 4),
                Text('Book Close: ${item.bookCloseDate}  |  FY: ${item.fiscalYear}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.bonusPercent > 0)
                Text('${item.bonusPercent}%', style: TextStyle(color: _color, fontSize: 20, fontWeight: FontWeight.w800)),
              if (item.cashDividend > 0)
                Text('Rs.${item.cashDividend}', style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              StatusBadge(item.status),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROMOTER SHARE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PromoterScreen extends StatefulWidget {
  const PromoterScreen({super.key});
  @override
  State<PromoterScreen> createState() => _PromoterScreenState();
}

class _PromoterScreenState extends State<PromoterScreen> {
  final _api = NepseApiService();
  List<PromoterShareModel> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _data = await _api.getPromoterShares();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Promoter Share Unlock')),
      body: _loading
          ? ListView.builder(itemCount: 4, itemBuilder: (_, __) => const ShimmerCard(height: 120))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              child: _data.isEmpty
                  ? const EmptyState(message: 'No promoter unlock data', icon: Icons.lock_open_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) => _PromoterCard(item: _data[i]),
                    ),
            ),
    );
  }
}

class _PromoterCard extends StatelessWidget {
  final PromoterShareModel item;
  const _PromoterCard({required this.item});

  Color get _statusColor {
    switch (item.status.toLowerCase()) {
      case 'on sale': return AppColors.green;
      case 'unlocking soon': return AppColors.orange;
      case 'locked': return AppColors.red;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.lock_open_rounded, color: _statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.companyName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    Row(children: [
                      Text(item.symbol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: 6),
                      SectorBadge(item.sector),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(item.status),
                  const SizedBox(height: 4),
                  Text(item.daysLeft, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem('Units', formatLarge(item.units)),
                _infoItem('Price/Unit', 'Rs. ${item.pricePerUnit.toStringAsFixed(0)}'),
                _infoItem('Total Value', formatLarge(item.units * item.pricePerUnit)),
                _infoItem('Unlock Date', item.unlockDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
  ]);
}
