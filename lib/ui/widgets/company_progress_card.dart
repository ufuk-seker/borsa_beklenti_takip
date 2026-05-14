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

  const CompanyProgressCard({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BorsaProvider>(context);
    final salesProgress = provider.getProgress(company.id, provider.selectedYear, 'sales');
    final ebitdaProgress = provider.getProgress(company.id, provider.selectedYear, 'ebitda');
    final progress = (salesProgress + ebitdaProgress) / 2;

    return Card(
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
                    const SizedBox(width: 16),
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
}
