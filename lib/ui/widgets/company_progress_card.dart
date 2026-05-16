import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';
import '../providers/borsa_provider.dart';
import '../screens/company_detail_screen.dart';
import 'actual_entry_form.dart';
import 'package:provider/provider.dart';

class CompanyProgressCard extends StatelessWidget {
  final Company company;
  final int rank;

  const CompanyProgressCard({
    super.key, 
    required this.company,
    this.rank = 0,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BorsaProvider>(context);
    final salesProgress = provider.getProgress(company.id, provider.selectedYear, 'sales');
    final ebitdaProgress = provider.getProgress(company.id, provider.selectedYear, 'ebitda');
    final target = provider.targets.firstWhere(
      (t) => t.companyId == company.id && t.year == provider.selectedYear,
      orElse: () => FinancialTarget(companyId: company.id, year: provider.selectedYear),
    );
    final progress = (salesProgress + ebitdaProgress) / 2;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: rank > 0 && rank <= 3 ? [
          BoxShadow(
            color: AppTheme.accentGreen.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: rank > 0 && rank <= 3 
            ? const BorderSide(color: AppTheme.accentGreen, width: 0.5) 
            : BorderSide.none,
        ),
        child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        company.ticker,
                        style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (rank > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rank <= 3 ? Colors.amber.withOpacity(0.2) : AppTheme.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: rank <= 3 ? Colors.amber : AppTheme.accentGreen,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "#$rank",
                          style: TextStyle(
                            color: rank <= 3 ? Colors.amber : AppTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            company.sector ?? 'Genel',
                            style: const TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildTargetMiniInfo("S. Büyüme", "%${target.salesGrowth?.toStringAsFixed(0) ?? '0'}", AppTheme.accentGreen),
                    _buildTargetMiniInfo("F. Büyüme", "%${target.ebitdaGrowth?.toStringAsFixed(0) ?? '0'}", AppTheme.accentBlue),
                    _buildTargetMiniInfo("F. Marj", "%${target.ebitdaMargin?.toStringAsFixed(0) ?? '0'}", Colors.purpleAccent),
                    if ((target.salesGrowth ?? 0) < 0 || (target.ebitdaGrowth ?? 0) < 0)
                      _buildBadge("NEGATIVE", AppTheme.accentRed)
                    else if ((target.salesGrowth ?? 0) > 50 || (target.ebitdaGrowth ?? 0) > 50)
                      _buildBadge("HIGH GROWTH", Colors.deepOrange)
                    else if ((target.salesGrowth ?? 0) < 20 && (target.ebitdaGrowth ?? 0) < 20)
                      _buildBadge("LOW GROWTH", Colors.tealAccent),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCompactProgress("Satış İlerlemesi", salesProgress, AppTheme.accentGreen),
                const SizedBox(height: 12),
                _buildCompactProgress("FAVÖK İlerlemesi", ebitdaProgress, AppTheme.accentBlue),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompanyDetailScreen(company: company),
                          ),
                        );
                      },
                      child: const Text("Detayları Gör"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: ActualEntryForm(company: company),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: AppTheme.textMain,
                      ),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppTheme.textDim),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text("Şirketi Sil"),
                    content: Text("${company.name} şirketini ve tüm verilerini silmek istediğinize emin misiniz?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
                      TextButton(
                        onPressed: () {
                          Provider.of<BorsaProvider>(context, listen: false).deleteCompany(company.id);
                          Navigator.pop(context);
                        },
                        child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCompactProgress(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
            Text("%${(progress * 100).toStringAsFixed(1)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.darkBg,
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetMiniInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
