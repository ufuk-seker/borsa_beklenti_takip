import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_theme.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';
import '../../data/models/quarterly_actual.dart';
import '../providers/borsa_provider.dart';
import '../widgets/target_entry_form.dart';
import '../widgets/actual_entry_form.dart';
import 'package:provider/provider.dart';

class CompanyDetailScreen extends StatelessWidget {
  final Company company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    final provider = Provider.of<BorsaProvider>(context);
    final target = provider.targets.firstWhere(
      (t) => t.companyId == company.id && t.year == provider.selectedYear,
      orElse: () => FinancialTarget(companyId: company.id, year: provider.selectedYear),
    );

    final companyActuals = provider.actuals
        .where((a) => a.companyId == company.id && a.year == provider.selectedYear)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("${company.ticker} Analiz"),
        backgroundColor: AppTheme.darkBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppTheme.accentGreen),
            tooltip: "Hedefleri Güncelle",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: TargetEntryForm(
                    company: company,
                    existingTarget: target,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, provider.selectedYear),
            const SizedBox(height: 32),
            isMobile ? 
            Column(
              children: [
                _buildChartSection(context, companyActuals, target, isMobile),
                const SizedBox(height: 32),
                _buildMetricsSidebar(context, target),
              ],
            ) :
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildChartSection(context, companyActuals, target, isMobile),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: _buildMetricsSidebar(context, target),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (target.notes != null && target.notes!.isNotEmpty) ...[
              _buildNotesSection(context, target.notes!),
              const SizedBox(height: 32),
            ],
            _buildQuarterlyTable(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(company.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text("${company.sector ?? 'Genel'} Sektörü | $year Performans Takibi", style: const TextStyle(color: AppTheme.textDim)),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, List<QuarterlyActual> companyActuals, FinancialTarget target, bool isMobile) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textDim.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile ?
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Performans Trendi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Container(
                    height: 38,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppTheme.accentGreen,
                      unselectedLabelColor: AppTheme.textDim,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: "Satış"),
                        Tab(text: "FAVÖK"),
                      ],
                    ),
                  ),
                ],
              ) :
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Performans Trendi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    height: 38,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppTheme.accentGreen,
                      unselectedLabelColor: AppTheme.textDim,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: "Satış"),
                        Tab(text: "FAVÖK"),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLineChart(context, 'sales', AppTheme.accentGreen, companyActuals, target),
                  _buildLineChart(context, 'ebitda', AppTheme.accentBlue, companyActuals, target),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, String metric, Color color, List<QuarterlyActual> companyActuals, FinancialTarget target) {
    final provider = Provider.of<BorsaProvider>(context);
    final year = provider.selectedYear;
    final companyActuals = provider.actuals.where((a) => a.companyId == company.id && a.year == year).toList();
    final target = provider.targets.firstWhere((t) => t.companyId == company.id && t.year == year, orElse: () => FinancialTarget(companyId: company.id, year: year));
    
    final targetValue = (metric == 'sales' ? target.sales : target.ebitda) ?? 0;

    List<FlSpot> actualSpots = [const FlSpot(0, 0)]; // Start from (0,0)
    for (var a in companyActuals) {
      double val = (metric == 'sales' ? a.sales : a.ebitda);
      actualSpots.add(FlSpot(a.quarter.toDouble(), val));
    }
    actualSpots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 4,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.textDim.withOpacity(0.05), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: AppTheme.textDim.withOpacity(0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Q1", style: TextStyle(color: AppTheme.textDim, fontSize: 10)));
                  case 2: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Q2", style: TextStyle(color: AppTheme.textDim, fontSize: 10)));
                  case 3: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Q3", style: TextStyle(color: AppTheme.textDim, fontSize: 10)));
                  case 4: return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Q4", style: TextStyle(color: AppTheme.textDim, fontSize: 10)));
                }
                return const Text("");
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Target Line (0 to 4)
          LineChartBarData(
            spots: [const FlSpot(0, 0), FlSpot(4, targetValue)],
            isCurved: false,
            color: AppTheme.textDim.withOpacity(0.15),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Actual Line
          if (actualSpots.length > 1)
            LineChartBarData(
              spots: actualSpots,
              isCurved: true,
              color: color,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsSidebar(BuildContext context, dynamic target) {
    final provider = Provider.of<BorsaProvider>(context);
    final year = provider.selectedYear;
    final salesProgress = provider.getProgress(company.id, year, 'sales');
    final ebitdaProgress = provider.getProgress(company.id, year, 'ebitda');

    return Column(
      children: [
        _buildStatTile(
          "Yıllık Satış Hedefi", 
          target.sales?.toStringAsFixed(0) ?? "0", 
          Icons.leaderboard, 
          progress: salesProgress, 
          progressColor: AppTheme.accentGreen,
          subtitle: "Hedef Büyüme: %${target.salesGrowth?.toStringAsFixed(1) ?? '0'}"
        ),
        const SizedBox(height: 16),
        _buildStatTile(
          "Hedef FAVÖK", 
          target.ebitda?.toStringAsFixed(0) ?? "0", 
          Icons.pie_chart, 
          progress: ebitdaProgress, 
          progressColor: AppTheme.accentBlue,
          subtitle: "Hedef Büyüme: %${target.ebitdaGrowth?.toStringAsFixed(1) ?? '0'}"
        ),
        const SizedBox(height: 16),
        _buildStatTile("Beklenen Marj", "%${target.ebitdaMargin?.toStringAsFixed(1) ?? "0"}", Icons.percent),
        if (target.investment != null && target.investment != 0) ...[
          const SizedBox(height: 16),
          _buildStatTile(
            "Hedef Yatırım", 
            target.investment?.toStringAsFixed(0) ?? "0", 
            Icons.account_balance_wallet,
            progressColor: AppTheme.accentBlue,
            subtitle: "Yıllık Planlanan",
          ),
        ],
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, {double? progress, Color? progressColor, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textDim.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: progressColor ?? AppTheme.accentGreen, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.accentGreen, fontWeight: FontWeight.w500)),
          ],
          if (progress != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Yıllık İlerleme", style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                Text("%${(progress * 100).toStringAsFixed(1)}", style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.darkBg,
                color: progressColor,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuarterlyTable(BuildContext context, BorsaProvider provider) {
    final year = provider.selectedYear;
    final companyActuals = provider.actuals.where((a) => a.companyId == company.id && a.year == year).toList();
    final isMobile = MediaQuery.of(context).size.width < 750;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Çeyreklik Gerçekleşmeler", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text("(Kümülatif - ${provider.selectedYear})", style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: isMobile ? 600 : (MediaQuery.of(context).size.width > 1200 ? 1100 : MediaQuery.of(context).size.width - 100),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1),
                  4: FixedColumnWidth(100),
                },
                children: [
                  const TableRow(
                    children: [
                      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Dönem", style: TextStyle(color: AppTheme.textDim))),
                      Text("Satış", style: TextStyle(color: AppTheme.textDim)),
                      Text("FAVÖK", style: TextStyle(color: AppTheme.textDim)),
                      Text("Marj", style: TextStyle(color: AppTheme.textDim)),
                      Text("", style: TextStyle(color: AppTheme.textDim)),
                    ],
                  ),
                  ...[1, 2, 3, 4].map((q) {
                    final actual = companyActuals.cast<dynamic>().firstWhere((a) => a.quarter == q, orElse: () => null);
                    final margin = (actual != null && actual.sales != 0) ? (actual.ebitda / actual.sales * 100).toStringAsFixed(1) : "0";
                    
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Tooltip(
                            message: actual?.addedBy != null ? "Girişi Yapan: ${actual!.addedBy}" : "Bilinmiyor",
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${provider.selectedYear} Q$q", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                                if (actual?.addedBy != null)
                                  Text(actual!.addedBy!, style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                              ],
                            ),
                          ),
                        ),
                        Text(actual?.sales?.toStringAsFixed(0) ?? "-", style: const TextStyle(color: AppTheme.textMain)),
                        Text(actual?.ebitda?.toStringAsFixed(0) ?? "-", style: const TextStyle(color: AppTheme.textMain)),
                        Text("%$margin", style: const TextStyle(color: AppTheme.textDim)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(actual == null ? Icons.add_circle_outline : Icons.edit, size: 18, color: AppTheme.accentGreen),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                    child: ActualEntryForm(
                                      company: company,
                                      existingActual: actual is QuarterlyActual ? actual : null,
                                      initialQuarter: q,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (actual != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppTheme.surface,
                                      title: const Text("Veriyi Sil"),
                                      content: Text("${provider.selectedYear} Q$q verisini silmek istediğinize emin misiniz?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
                                        ElevatedButton(
                                          onPressed: () {
                                            provider.deleteQuarterlyActual(company.id, provider.selectedYear, q);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                          child: const Text("Sil"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String p1, String p2, String p3, String p4) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(p1)),
        Text(p2),
        Text(p3),
        Text(p4),
        const SizedBox(),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface,
            AppTheme.accentGreen.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 12),
              Text("Analist Notları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notes,
            style: const TextStyle(color: AppTheme.textMain, height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
