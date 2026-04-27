import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/nepse_api_service.dart';
import '../widgets/common_widgets.dart';

class IpoScreen extends StatefulWidget {
  const IpoScreen({super.key});

  @override
  State<IpoScreen> createState() => _IpoScreenState();
}

class _IpoScreenState extends State<IpoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _api = NepseApiService();
  List<IpoModel> _active = [];
  List<IpoModel> _upcoming = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Future.wait([
      _api.getActiveIpos(),
      _api.getUpcomingIpos(),
    ]);
    setState(() {
      _active = res[0] as List<IpoModel>;
      _upcoming = res[1] as List<IpoModel>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('IPO / FPO Tracker'),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Open (${_active.length})'),
            Tab(text: 'Upcoming (${_upcoming.length})'),
          ],
        ),
      ),
      body: _loading
          ? ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(height: 140))
          : TabBarView(
              controller: _tab,
              children: [
                _IpoList(ipos: _active, onRefresh: _load),
                _IpoList(ipos: _upcoming, onRefresh: _load),
              ],
            ),
    );
  }
}

class _IpoList extends StatelessWidget {
  final List<IpoModel> ipos;
  final Future<void> Function() onRefresh;
  const _IpoList({required this.ipos, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (ipos.isEmpty) {
      return const EmptyState(
          message: 'No IPOs at this time', icon: Icons.rocket_launch_outlined);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ipos.length,
        itemBuilder: (_, i) => _IpoCard(ipo: ipos[i]),
      ),
    );
  }
}

class _IpoCard extends StatelessWidget {
  final IpoModel ipo;
  const _IpoCard({required this.ipo});

  Color get _typeColor {
    switch (ipo.type.toLowerCase()) {
      case 'fpo': return AppColors.accent;
      case 'mutual fund': return AppColors.purple;
      case 'debenture': return AppColors.orange;
      default: return AppColors.primary;
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
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.rocket_launch_rounded,
                    color: _typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ipo.companyName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Row(
                      children: [
                        Text(ipo.symbol,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 6),
                        SectorBadge(ipo.sector),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _typeColor.withOpacity(0.3)),
                    ),
                    child: Text(ipo.type,
                        style: TextStyle(
                            color: _typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(ipo.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem('Price', 'Rs. ${ipo.sharePrice.toStringAsFixed(0)}'),
                _infoItem('Units', formatLarge(ipo.totalUnits.toDouble())),
                _infoItem('Opens', ipo.openDate),
                _infoItem('Closes', ipo.closeDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
        ],
      );
}
