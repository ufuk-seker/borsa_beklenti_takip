import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';
import '../providers/borsa_provider.dart';
import '../widgets/company_progress_card.dart';
import '../widgets/target_entry_form.dart';
import 'company_detail_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isGridView = true;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    final provider = Provider.of<BorsaProvider>(context);
    final int currentYear = provider.selectedYear;
    
    // Filter companies to only show those that have targets for the selected year
    List<Company> companies = provider.companies.where((c) {
      return provider.targets.any((t) => t.companyId == c.id && t.year == currentYear);
    }).toList();

    // Apply sorting logic safely
    try {
      companies.sort((a, b) {
        int compare;
        if (_sortColumnIndex == 0) {
          compare = a.ticker.compareTo(b.ticker);
        } else {
          final targetA = provider.targets.firstWhere(
            (t) => t.companyId == a.id && t.year == currentYear, 
            orElse: () => FinancialTarget(companyId: a.id, year: currentYear)
          );
          final targetB = provider.targets.firstWhere(
            (t) => t.companyId == b.id && t.year == currentYear, 
            orElse: () => FinancialTarget(companyId: b.id, year: currentYear)
          );
          
          final salesProgressA = provider.getProgress(a.id, currentYear, 'sales');
          final salesProgressB = provider.getProgress(b.id, currentYear, 'sales');
          final ebitdaProgressA = provider.getProgress(a.id, currentYear, 'ebitda');
          final ebitdaProgressB = provider.getProgress(b.id, currentYear, 'ebitda');

          switch (_sortColumnIndex) {
            case 1: compare = (targetA.sales ?? 0).compareTo(targetB.sales ?? 0); break;
            case 2: compare = (targetA.salesGrowth ?? 0).compareTo(targetB.salesGrowth ?? 0); break;
            case 3: compare = (targetA.ebitda ?? 0).compareTo(targetB.ebitda ?? 0); break;
            case 4: compare = (targetA.ebitdaGrowth ?? 0).compareTo(targetB.ebitdaGrowth ?? 0); break;
            case 5: compare = (targetA.ebitdaMargin ?? 0).compareTo(targetB.ebitdaMargin ?? 0); break;
            case 6: compare = salesProgressA.compareTo(salesProgressB); break;
            case 7: compare = ebitdaProgressA.compareTo(ebitdaProgressB); break;
            default: compare = a.ticker.compareTo(b.ticker);
          }
        }
        return _isAscending ? compare : -compare;
      });
    } catch (e) {
      debugPrint("Sorting error: $e");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Borsa Terminali $currentYear"),
        backgroundColor: AppTheme.darkBg,
        actions: [
          _buildYearSelector(provider),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.accentGreen),
            tooltip: "Excel'e Aktar",
            onPressed: () => provider.exportToExcel(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Verileri Yenile",
            onPressed: () => provider.refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.upload, color: AppTheme.accentBlue),
            tooltip: "Excel'den Al (Güvenli)",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Text("Veri İçe Aktarma"),
                    ],
                  ),
                  content: const Text(
                    "Excel'den veri aktarmak mevcut verilerinizin üzerine yazabilir. "
                    "Devam etmeden önce mevcut verilerinizi yedeklemenizi öneririz.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("İptal"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        provider.importFromExcel(withBackup: true);
                      },
                      child: const Text("Yedek Al ve Devam Et"),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: LinearProgressIndicator(backgroundColor: AppTheme.surface, color: AppTheme.accentGreen),
              ),
            _buildSummarySection(context, companies),
            const SizedBox(height: 40),
            isMobile ? 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hedef Takip Paneli", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: TargetEntryForm(
                              company: Company(id: 'new', name: '', ticker: ''),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Yeni Şirket Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ) :
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Hedef Takip Paneli", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: TargetEntryForm(
                            company: Company(id: 'new', name: '', ticker: ''),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Yeni Şirket Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            const Text("Şirketlerin yıllık hedeflerine olan uzaklığını buradan takip edebilirsiniz.", style: TextStyle(color: AppTheme.textDim)),
            const SizedBox(height: 32),
            _isGridView ? _buildGridView(context, provider, companies) : _buildTableView(context, provider, companies),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, BorsaProvider provider, List<Company> companies) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: companies.length,
      itemBuilder: (context, index) => CompanyProgressCard(company: companies[index]),
    );
  }

  Widget _buildTableView(BuildContext context, BorsaProvider provider, List<Company> companies) {
    final int year = provider.selectedYear;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _isAscending,
          columns: [
            DataColumn(label: const Text("Ticker"), onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("Satış Hedefi"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("Satış Büyüme"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("FAVÖK Hedefi"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("FAVÖK Büyüme"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("Marj"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("Satış İlerleme"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            DataColumn(label: const Text("FAVÖK İlerleme"), numeric: true, onSort: (idx, asc) => setState(() { _sortColumnIndex = idx; _isAscending = asc; })),
            const DataColumn(label: Text("İşlem")),
          ],
          rows: companies.map((c) {
            final target = provider.targets.firstWhere((t) => t.companyId == c.id && t.year == year, orElse: () => FinancialTarget(companyId: c.id, year: year));
            final salesProgress = provider.getProgress(c.id, year, 'sales');
            final ebitdaProgress = provider.getProgress(c.id, year, 'ebitda');

            return DataRow(cells: [
              DataCell(Text(c.ticker, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen))),
              DataCell(Text(target.sales?.toStringAsFixed(0) ?? "-")),
              DataCell(Text("%${target.salesGrowth?.toStringAsFixed(1) ?? "-"}", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w500))),
              DataCell(Text(target.ebitda?.toStringAsFixed(0) ?? "-")),
              DataCell(Text("%${target.ebitdaGrowth?.toStringAsFixed(1) ?? "-"}", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w500))),
              DataCell(Text("%${target.ebitdaMargin?.toStringAsFixed(1) ?? "-"}")),
              DataCell(Text("%${(salesProgress * 100).toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen))),
              DataCell(Text("%${(ebitdaProgress * 100).toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentBlue))),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, size: 20),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CompanyDetailScreen(company: c))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.surface,
                          title: const Text("Şirketi Sil"),
                          content: Text("${c.name} şirketini silmek istediğinize emin misiniz?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
                            TextButton(
                              onPressed: () {
                                provider.deleteCompany(c.id);
                                Navigator.pop(context);
                              },
                              child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildYearSelector(BorsaProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.textDim.withOpacity(0.2)),
      ),
      child: DropdownButton<int>(
        value: provider.selectedYear,
        underline: const SizedBox(),
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
        items: provider.availableYears.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(year.toString()),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) provider.setSelectedYear(val);
        },
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, List<Company> sortedCompanies) {
    final provider = Provider.of<BorsaProvider>(context);
    final year = provider.selectedYear;
    final isMobile = MediaQuery.of(context).size.width < 750;
    
    // Calculate real stats for selected year
    final companiesWithTargets = sortedCompanies;
    
    double avgProgress = 0;
    List<Company> criticalCompanies = [];
    
    if (companiesWithTargets.isNotEmpty) {
      double totalProgress = 0;
      for (var c in companiesWithTargets) {
        final p = provider.getProgress(c.id, year, 'sales');
        totalProgress += p;
        
        // Smarter critical check based on latest quarter
        final companyActuals = provider.actuals.where((a) => a.companyId == c.id && a.year == year).toList();
        if (companyActuals.isNotEmpty) {
          final latestQ = companyActuals.map((a) => a.quarter).reduce((a, b) => a > b ? a : b);
          double threshold = latestQ * 0.18; // ~18% progress expected per quarter minimum
          if (p < threshold) criticalCompanies.add(c);
        }
      }
      avgProgress = totalActualCount(totalProgress, companiesWithTargets.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            children: [
              _buildSummaryCard(context, "Takipteki Şirket", companiesWithTargets.length.toString(), Icons.business, isExpanded: false),
              const SizedBox(height: 12),
              _buildSummaryCard(context, "Ortalama İlerleme", "%${(avgProgress * 100).toStringAsFixed(0)}", Icons.pie_chart, isExpanded: false),
              const SizedBox(height: 12),
              _buildSummaryCard(context, "Kritik Sapma", criticalCompanies.length.toString(), Icons.warning_amber_rounded, color: AppTheme.accentRed, isExpanded: false),
            ],
          )
        else
          Row(
            children: [
              _buildSummaryCard(context, "Takipteki Şirket", companiesWithTargets.length.toString(), Icons.business),
              const SizedBox(width: 16),
              _buildSummaryCard(context, "Ortalama İlerleme", "%${(avgProgress * 100).toStringAsFixed(0)}", Icons.pie_chart),
              const SizedBox(width: 16),
              _buildSummaryCard(context, "Kritik Sapma", criticalCompanies.length.toString(), Icons.warning_amber_rounded, color: AppTheme.accentRed),
            ],
          ),
        if (criticalCompanies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentRed.withOpacity(0.2)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 20),
                    const SizedBox(width: 8),
                    const Text("Kritik Sapma Gösterenler: ", style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                ...criticalCompanies.map((c) => ActionChip(
                  label: Text(c.ticker, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: AppTheme.accentRed.withOpacity(0.2),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CompanyDetailScreen(company: c))),
                )).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double totalActualCount(double total, int count) => count > 0 ? total / count : 0;

  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon, {Color color = AppTheme.accentGreen, bool isExpanded = true}) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textDim.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    return isExpanded ? Expanded(child: card) : card;
  }
}
