import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/nepse_api_service.dart';
import '../widgets/common_widgets.dart';
import 'stock_list_screen.dart';
import 'ipo_screen.dart';
import 'right_share_screen.dart';
import 'bonus_screen.dart';
import 'promoter_screen.dart';
import 'floorsheet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _api = NepseApiService();
  MarketSummary? _summary;
  List<StockModel> _topMovers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getMarketSummary(),
      _api.getLiveStocks(),
    ]);
    setState(() {
      _summary = results[0] as MarketSummary;
      final stocks = results[1] as List<StockModel>;
      stocks.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
      _topMovers = stocks.take(6).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeContent(),
      const StockListScreen(),
      const IpoScreen(),
      const FloorsheetScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart_rounded),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rocket_launch_outlined),
              activeIcon: Icon(Icons.rocket_launch_rounded),
              label: 'Issues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Floorsheet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppColors.bg,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.candlestick_chart_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEPSE Tracker',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Text('Nepal Stock Exchange',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const ShimmerCard(height: 160)
                : MarketIndexCard(summary: _summary),
          ),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Top Movers Today',
              subtitle: 'Highest % change',
              action: TextButton(
                onPressed: () {},
                child: const Text('See all',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const ShimmerCard(height: 200)
                : _buildTopMovers(),
          ),
          SliverToBoxAdapter(child: _buildEventCards()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('IPO / FPO', Icons.rocket_launch_rounded, AppColors.primary,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IpoScreen()))),
      _QuickAction('Right Share', Icons.account_balance_rounded, AppColors.accent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RightShareScreen()))),
      _QuickAction('Bonus', Icons.card_giftcard_rounded, AppColors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BonusScreen()))),
      _QuickAction('Promoter', Icons.lock_open_rounded, AppColors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoterScreen()))),
      _QuickAction('Floorsheet', Icons.receipt_long_rounded, AppColors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FloorsheetScreen()))),
      _QuickAction('Market', Icons.bar_chart_rounded, const Color(0xFFEC4899),
          () {}),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: actions.map((a) => _buildActionTile(a)).toList(),
      ),
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: action.color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 22),
            const SizedBox(height: 5),
            Text(action.label,
                style: TextStyle(
                    color: action.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMovers() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _topMovers.length,
        itemBuilder: (_, i) {
          final s = _topMovers[i];
          return Container(
            width: 150,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.symbol,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    ChangeChip(change: s.change, percent: s.changePercent),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatPrice(s.ltp),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  s.companyName,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Vol: ${formatLarge(s.volume.toDouble())}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCards() {
    return Column(
      children: [
        SectionHeader(
          title: 'Upcoming Events',
          subtitle: 'IPO, Bonus, Right Share deadlines',
        ),
        _EventCard(
          icon: Icons.rocket_launch_rounded,
          color: AppColors.primary,
          title: 'Yambaling Hydropower IPO',
          subtitle: 'Closes: 22 Baishakh 2082',
          tag: 'IPO OPEN',
          tagColor: AppColors.green,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const IpoScreen())),
        ),
        _EventCard(
          icon: Icons.account_balance_rounded,
          color: AppColors.accent,
          title: 'United Ajod Insurance Right Share',
          subtitle: 'Ratio: 100:10 | Closes: 16 Baishakh',
          tag: 'RIGHT SHARE',
          tagColor: AppColors.accent,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RightShareScreen())),
        ),
        _EventCard(
          icon: Icons.lock_open_rounded,
          color: AppColors.orange,
          title: 'City Hotel Ltd Promoter Unlock',
          subtitle: '2.72 Cr shares unlock on 5 Jestha',
          tag: 'PROMOTER',
          tagColor: AppColors.orange,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PromoterScreen())),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _EventCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final VoidCallback onTap;

  const _EventCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tag,
                  style: TextStyle(
                      color: tagColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
