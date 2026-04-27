import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/nepse_api_service.dart';
import '../widgets/common_widgets.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final _api = NepseApiService();
  List<StockModel> _stocks = [];
  List<StockModel> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _selectedSector = 'All';

  final _sectors = ['All', 'Commercial Banks', 'Hydropower', 'Non Life Insurance',
    'Life Insurance', 'Microfinance', 'Manufacturing', 'Hotels'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _stocks = await _api.getLiveStocks();
    _filter();
    setState(() => _loading = false);
  }

  void _filter() {
    setState(() {
      _filtered = _stocks.where((s) {
        final matchSearch = _search.isEmpty ||
            s.symbol.toLowerCase().contains(_search.toLowerCase()) ||
            s.companyName.toLowerCase().contains(_search.toLowerCase());
        final matchSector = _selectedSector == 'All' || s.sector == _selectedSector;
        return matchSearch && matchSector;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Live Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search symbol or company...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (v) {
                _search = v;
                _filter();
              },
            ),
          ),
          // Sector filter
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _sectors.length,
              itemBuilder: (_, i) {
                final s = _sectors[i];
                final selected = s == _selectedSector;
                return GestureDetector(
                  onTap: () {
                    _selectedSector = s;
                    _filter();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Symbol', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('LTP', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('Change', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('Volume', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? ListView.builder(
                    itemCount: 8,
                    itemBuilder: (_, __) => const ShimmerCard(height: 64))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    backgroundColor: AppColors.card,
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _StockRow(stock: _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final StockModel stock;
  const _StockRow({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isUp = stock.isPositive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.symbol,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(stock.sector,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatPrice(stock.ltp),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isUp ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: isUp ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
                Text(
                  '${isUp ? '+' : ''}${stock.change.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: isUp
                          ? AppColors.green.withOpacity(0.7)
                          : AppColors.red.withOpacity(0.7),
                      fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatLarge(stock.volume.toDouble()),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
