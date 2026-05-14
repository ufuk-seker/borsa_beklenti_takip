import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';
import '../../data/models/quarterly_actual.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // Companies
  static Future<List<Company>> getCompanies() async {
    final response = await _client.from('companies').select().order('ticker');
    return response.map((m) => Company(
      id: m['id'],
      ticker: m['ticker'],
      name: m['name'],
      sector: m['sector'],
    )).toList();
  }

  static Future<void> saveCompany(Company company) async {
    await _client.from('companies').upsert({
      'ticker': company.ticker,
      'name': company.name,
      'sector': company.sector,
    }, onConflict: 'ticker');
  }

  static Future<void> deleteCompany(String id) async {
    await _client.from('companies').delete().eq('id', id);
  }

  // Financial Targets
  static Future<List<FinancialTarget>> getFinancialTargets() async {
    final response = await _client.from('financial_targets').select();
    return response.map((m) => FinancialTarget(
      companyId: m['company_id'],
      year: m['year'],
      sales: m['sales']?.toDouble(),
      salesGrowth: m['sales_growth']?.toDouble(),
      ebitda: m['ebitda']?.toDouble(),
      ebitdaGrowth: m['ebitda_growth']?.toDouble(),
      ebitdaMargin: m['ebitda_margin']?.toDouble(),
    )).toList();
  }

  static Future<void> saveFinancialTarget(FinancialTarget target) async {
    await _client.from('financial_targets').upsert({
      'company_id': target.companyId,
      'year': target.year,
      'sales': target.sales,
      'sales_growth': target.salesGrowth,
      'ebitda': target.ebitda,
      'ebitda_growth': target.ebitdaGrowth,
      'ebitda_margin': target.ebitdaMargin,
    }, onConflict: 'company_id, year');
  }

  // Quarterly Actuals
  static Future<List<QuarterlyActual>> getQuarterlyActuals() async {
    final response = await _client.from('quarterly_actuals').select();
    return response.map((m) => QuarterlyActual(
      id: m['id'],
      companyId: m['company_id'],
      year: m['year'],
      quarter: m['quarter'],
      sales: m['sales'].toDouble(),
      ebitda: m['ebitda'].toDouble(),
      investment: m['investment']?.toDouble(),
      addedBy: m['added_by'],
    )).toList();
  }

  static Future<void> saveQuarterlyActual(QuarterlyActual actual) async {
    await _client.from('quarterly_actuals').upsert({
      'company_id': actual.companyId,
      'year': actual.year,
      'quarter': actual.quarter,
      'sales': actual.sales,
      'ebitda': actual.ebitda,
      'investment': actual.investment,
      'added_by': actual.addedBy,
    }, onConflict: 'company_id, year, quarter');
  }

  static Future<void> deleteQuarterlyActual(String companyId, int year, int quarter) async {
    await _client.from('quarterly_actuals')
        .delete()
        .eq('company_id', companyId)
        .eq('year', year)
        .eq('quarter', quarter);
  }
}
