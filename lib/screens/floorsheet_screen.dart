import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/nepse_api_service.dart';
import '../widgets/common_widgets.dart';

class FloorsheetScreen extends StatefulWidget {
  const FloorsheetScreen({super.key});

  @override
  State<FloorsheetScreen> createState() => _FloorsheetScreenState();
}

class _FloorsheetScreenState extends State<FloorsheetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _api = NepseApiService();
  final _symbolController = TextEditingController(text: 'NABIL');

  List<FloorsheetEntry> _floorsheet = [];
  List<BrokerActivity> _brokerActivity = [];
  bool _loading = false;
  String _currentSymbol = 'NABIL';

  final _popularSymbols = ['NABIL', 'GBIME', 'NICA', 'SBL', 'HIDCL', 'NLG', 'NRIC', 'SHIVM'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadFloorsheet();
  }

  Future<void> _loadFloorsheet() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getFloorsheet(symbol: _currentSymbol),
      _api.getBrokerActivity(_currentSymbol),
    ]);
    setState(() {
      _floorsheet = results[0] as List<FloorsheetEntry>;
      _brokerActivity = results[1] as List<BrokerActivity>;
      _loading = false;
    });
  }

  void _search() {
    final sym = _symbolController.text.trim().toUpperCase();
    if (sym.isEmpty) return;
    _currentSymbol = sym;
    _loadFloorsheet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Floorsheet & Broker Activity'),
      ),
      body: Column(
        children: [
          // Symbol search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _symbolController,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter stock symbol (e.g. NABIL)',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // Quick symbol chips
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _popularSymbols.length,
              itemBuilder: (_, i) {
                final sym = _popularSymbols[i];
                final selected = sym == _currentSymbol;
                return GestureDetector(
                  onTap: () {
                    _symbolController.text = sym;
                    _currentSymbol = sym;
                    _loadFloorsheet();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.cardBorder),
                    ),
                    child: Text(sym,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Tabs
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tab,
              tabs: [
                Tab(text: 'Floorsheet (${_floorsheet.length})'),
                Tab(text: 'Broker Activity'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loading
                ? ListView.builder(
                    itemCount: 6,
                    itemBuilder: (_, __) => const ShimmerCard(height: 60))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _buildFloorsheet(),
                      _buildBrokerActivity(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorsheet() {
    if (_floorsheet.isEmpty) {
      return const EmptyState(
          message: 'No floorsheet data', icon: Icons.receipt_long_outlined);
    }
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Buyer', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Seller', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Qty', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Rate', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 3, child: Text('Amount', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _floorsheet.length,
            itemBuilder: (_, i) {
              final e = _floorsheet[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _brokerBadge(e.buyerBroker, AppColors.green),
                    ),
                    Expanded(
                      flex: 2,
                      child: _brokerBadge(e.sellerBroker, AppColors.red),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.quantity.toString(),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatPrice(e.rate),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        formatLarge(e.amount),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _brokerBadge(int id, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          'Br $id',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );

  Widget _buildBrokerActivity() {
    if (_brokerActivity.isEmpty) {
      return const EmptyState(
          message: 'No broker data', icon: Icons.business_outlined);
    }
    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(AppColors.green, 'Buyer'),
              const SizedBox(width: 16),
              _legend(AppColors.red, 'Seller'),
              const SizedBox(width: 16),
              _legend(AppColors.primary, 'Net Long'),
              const SizedBox(width: 16),
              _legend(AppColors.orange, 'Net Short'),
            ],
          ),
        ),
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: const Row(
            children: [
              Expanded(flex: 1, child: Text('Broker', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Buy Qty', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Sell Qty', style: TextStyle(color: AppColors.red, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Net', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 3, child: Text('Buy Amt', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _brokerActivity.length,
            itemBuilder: (_, i) {
              final b = _brokerActivity[i];
              final isNetLong = b.netPosition >= 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.transparent : AppColors.surface.withOpacity(0.3),
                  border: const Border(
                      bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${b.brokerId}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatLarge(b.buyQuantity.toDouble()),
                        style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatLarge(b.sellQuantity.toDouble()),
                        style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${isNetLong ? '+' : ''}${formatLarge(b.netPosition.toDouble())}',
                        style: TextStyle(
                            color: isNetLong ? AppColors.primary : AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        formatLarge(b.buyAmount),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      );
}
