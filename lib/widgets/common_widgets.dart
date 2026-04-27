import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ── Number Formatters ─────────────────────────────────────────────────────────
String formatPrice(double v) => NumberFormat('#,##0.00').format(v);
String formatLarge(double v) {
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
  if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
  return NumberFormat('#,##0').format(v);
}

// ── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'open':
        bg = AppColors.greenBg; fg = AppColors.green;
      case 'upcoming':
        bg = AppColors.orangeBg; fg = AppColors.orange;
      case 'closed':
      case 'locked':
        bg = AppColors.redBg; fg = AppColors.red;
      case 'allotted':
      case 'distributed':
        bg = AppColors.purpleBg; fg = AppColors.purple;
      case 'on sale':
      case 'unlocking soon':
        bg = const Color(0xFF0A2E1E); fg = AppColors.green;
      case 'announced':
        bg = AppColors.orangeBg; fg = AppColors.orange;
      case 'approved':
        bg = const Color(0xFF0D1F3C); fg = AppColors.primary;
      default:
        bg = AppColors.cardBorder; fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Sector Badge ─────────────────────────────────────────────────────────────
class SectorBadge extends StatelessWidget {
  final String sector;
  const SectorBadge(this.sector, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        sector,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    );
  }
}

// ── Change Chip (for stock price change) ─────────────────────────────────────
class ChangeChip extends StatelessWidget {
  final double change;
  final double percent;
  const ChangeChip({super.key, required this.change, required this.percent});

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUp ? AppColors.greenBg : AppColors.redBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: isUp ? AppColors.green : AppColors.red,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              color: isUp ? AppColors.green : AppColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Market Index Card ─────────────────────────────────────────────────────────
class MarketIndexCard extends StatelessWidget {
  final MarketSummary? summary;
  const MarketIndexCard({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const ShimmerCard(height: 130);
    final s = summary!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: s.isPositive
              ? [const Color(0xFF0D2818), const Color(0xFF1A3A28)]
              : [const Color(0xFF2D0A0A), const Color(0xFF3D1515)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: s.isPositive
              ? AppColors.green.withOpacity(0.3)
              : AppColors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEPSE Index',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(s.nepseIndex),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        s.isPositive ? Icons.trending_up : Icons.trending_down,
                        color: s.isPositive ? AppColors.green : AppColors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${s.isPositive ? '+' : ''}${s.change.toStringAsFixed(2)} '
                        '(${s.changePercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: s.isPositive ? AppColors.green : AppColors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: s.isMarketOpen
                      ? AppColors.green.withOpacity(0.2)
                      : AppColors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: s.isMarketOpen ? AppColors.green : AppColors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.isMarketOpen ? AppColors.green : AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.isMarketOpen ? 'LIVE' : 'CLOSED',
                      style: TextStyle(
                        color: s.isMarketOpen ? AppColors.green : AppColors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('Turnover', formatLarge(s.totalTurnover)),
              _statItem('Transactions', formatLarge(s.totalTransactions.toDouble())),
              _statItem('Traded Shares', formatLarge(s.totalTradedShares.toDouble())),
              _statItem('Scrips', s.totalScrips.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      );
}

// ── Shimmer Loading Card ──────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardBorder,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
