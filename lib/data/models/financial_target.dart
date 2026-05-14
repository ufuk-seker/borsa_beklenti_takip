class FinancialTarget {
  final String? id;
  final String companyId;
  final int year;
  
  final double? sales;
  final double? salesGrowth; // %
  
  final double? ebitda;
  final double? ebitdaMargin; // %
  final double? ebitdaGrowth; // %
  
  final double? investment;
  final double? investmentGrowth; // %
  
  final String? notes;

  FinancialTarget({
    this.id,
    required this.companyId,
    required this.year,
    this.sales,
    this.salesGrowth,
    this.ebitda,
    this.ebitdaMargin,
    this.ebitdaGrowth,
    this.investment,
    this.investmentGrowth,
    this.notes,
  });

  factory FinancialTarget.fromMap(Map<String, dynamic> map) {
    return FinancialTarget(
      id: map['id'],
      companyId: map['company_id'],
      year: map['year'],
      sales: map['sales']?.toDouble(),
      salesGrowth: map['sales_growth']?.toDouble(),
      ebitda: map['ebitda']?.toDouble(),
      ebitdaMargin: map['ebitda_margin']?.toDouble(),
      ebitdaGrowth: map['ebitda_growth']?.toDouble(),
      investment: map['investment']?.toDouble(),
      investmentGrowth: map['investment_growth']?.toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company_id': companyId,
      'year': year,
      'sales': sales,
      'sales_growth': salesGrowth,
      'ebitda': ebitda,
      'ebitda_margin': ebitdaMargin,
      'ebitda_growth': ebitdaGrowth,
      'investment': investment,
      'investment_growth': investmentGrowth,
      'notes': notes,
    };
  }
}
