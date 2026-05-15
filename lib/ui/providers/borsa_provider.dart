import 'package:flutter/material.dart';
import '../../core/services/excel_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';
import '../../data/models/quarterly_actual.dart';

class BorsaProvider extends ChangeNotifier {
  List<Company> _companies = [];
  List<FinancialTarget> _targets = [];
  List<QuarterlyActual> _actuals = [];
  int _selectedYear = 2026;
  bool _isLoading = false;

  List<Company> get companies => _companies;
  List<FinancialTarget> get targets => _targets;
  List<QuarterlyActual> get actuals => _actuals;
  int get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;

  final List<int> _availableYears = [2024, 2025, 2026, 2027, 2028, 2029, 2030];
  List<int> get availableYears => _availableYears;

  BorsaProvider() {
    refreshData();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _companies = await SupabaseService.getCompanies();
      _targets = await SupabaseService.getFinancialTargets();
      _actuals = await SupabaseService.getQuarterlyActuals();
    } catch (e) {
      debugPrint("Supabase Veri Çekme Hatası: $e");
      print("CRITICAL: Supabase Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCompany(Company company, FinancialTarget target) async {
    try {
      await SupabaseService.saveCompany(company);
      // Get the company again to ensure we have the UUID
      final freshCompanies = await SupabaseService.getCompanies();
      final dbCompany = freshCompanies.firstWhere((c) => c.ticker == company.ticker);
      
      final newTarget = FinancialTarget(
        companyId: dbCompany.id,
        year: target.year,
        sales: target.sales,
        salesGrowth: target.salesGrowth,
        ebitda: target.ebitda,
        ebitdaGrowth: target.ebitdaGrowth,
        ebitdaMargin: target.ebitdaMargin,
      );
      await SupabaseService.saveFinancialTarget(newTarget);
      await refreshData();
    } catch (e) {
      debugPrint("Şirket Ekleme Hatası: $e");
    }
  }

  Future<void> updateTarget(FinancialTarget target) async {
    try {
      await SupabaseService.saveFinancialTarget(target);
      await refreshData();
    } catch (e) {
      debugPrint("Hedef Güncelleme Hatası: $e");
    }
  }

  Future<void> addActual(QuarterlyActual actual) async {
    try {
      await SupabaseService.saveQuarterlyActual(actual);
      await refreshData();
    } catch (e) {
      debugPrint("Veri Ekleme Hatası: $e");
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await SupabaseService.deleteCompany(id);
      await refreshData();
    } catch (e) {
      debugPrint("Şirket Silme Hatası: $e");
    }
  }

  Future<void> deleteQuarterlyActual(String companyId, int year, int quarter) async {
    try {
      await SupabaseService.deleteQuarterlyActual(companyId, year, quarter);
      await refreshData();
    } catch (e) {
      debugPrint("Veri Silme Hatası: $e");
    }
  }

  Future<void> exportToExcel() async {
    await ExcelService.exportToExcel(
      companies: _companies,
      targets: _targets,
      actuals: _actuals,
    );
  }

  Future<void> importFromExcel({bool withBackup = false}) async {
    if (withBackup) {
      await exportToExcel();
      // Brief delay to ensure export starts/completes before picker opens
      await Future.delayed(const Duration(milliseconds: 800));
    }

    final data = await ExcelService.importFromExcel();
    if (data != null) {
      _isLoading = true;
      notifyListeners();
      
      try {
        final importedCompanies = List<Company>.from(data['companies']!);
        final importedTargets = List<FinancialTarget>.from(data['targets']!);
        final importedActuals = List<QuarterlyActual>.from(data['actuals']!);

        for (var c in importedCompanies) {
          await SupabaseService.saveCompany(c);
        }
        
        // 1. Build a map of Old ID -> Ticker from the imported companies
        final excelIdToTicker = { for (var c in importedCompanies) c.id : c.ticker };
        
        for (var c in importedCompanies) {
          await SupabaseService.saveCompany(c);
        }
        
        // 2. Re-fetch to get correct New UUIDs from Supabase
        final dbCompanies = await SupabaseService.getCompanies();
        final tickerToNewId = { for (var c in dbCompanies) c.ticker : c.id };
        
        for (var t in importedTargets) {
          // Resolve: Excel ID -> Ticker -> New UUID
          final ticker = excelIdToTicker[t.companyId] ?? t.companyId; 
          final realId = tickerToNewId[ticker];
          
          print("Hedef Eşleştirme: Girdi=${t.companyId} (Ticker=$ticker) -> Sonuç=$realId");
          if (realId != null) {
            await SupabaseService.saveFinancialTarget(FinancialTarget(
              companyId: realId,
              year: t.year,
              sales: t.sales,
              salesGrowth: t.salesGrowth,
              ebitda: t.ebitda,
              ebitdaGrowth: t.ebitdaGrowth,
              ebitdaMargin: t.ebitdaMargin,
            ));
          }
        }
        for (var a in importedActuals) {
          final ticker = excelIdToTicker[a.companyId] ?? a.companyId;
          final realId = tickerToNewId[ticker];
          
          print("Gerçekleşen Eşleştirme: Girdi=${a.companyId} (Ticker=$ticker) -> Sonuç=$realId");
          if (realId != null) {
            await SupabaseService.saveQuarterlyActual(QuarterlyActual(
              companyId: realId,
              year: a.year,
              quarter: a.quarter,
              sales: a.sales,
              ebitda: a.ebitda,
              investment: a.investment,
              addedBy: a.addedBy,
            ));
          }
        }
      } catch (e) {
        debugPrint("Excel Import Kritik Hata: $e");
        // Log to console so user can see it in terminal
        print("CRITICAL: Supabase Import Error: $e");
      }
      
      await refreshData();
    }
  }

  double getProgress(String companyId, int year, String metric) {
    final target = _targets.firstWhere(
      (t) => t.companyId == companyId && t.year == year,
      orElse: () => FinancialTarget(companyId: companyId, year: year),
    );

    final companyActuals = _actuals.where(
      (a) => a.companyId == companyId && a.year == year,
    );

    if (companyActuals.isEmpty) return 0.0;

    double currentTotal = 0;
    double targetValue = 0;

    if (companyActuals.isNotEmpty) {
      // Find the latest quarter data since it's cumulative
      final latestActual = companyActuals.reduce((curr, next) => curr.quarter > next.quarter ? curr : next);
      
      if (metric == 'sales') {
        currentTotal = latestActual.sales;
        targetValue = target.sales ?? 1.0;
      } else if (metric == 'ebitda') {
        currentTotal = latestActual.ebitda;
        targetValue = target.ebitda ?? 1.0;
      }
    } else {
      targetValue = 1.0;
    }

    if (targetValue == 0) return 0.0;
    double progress = currentTotal / targetValue;
    return progress > 1.0 ? 1.0 : progress;
  }
}
