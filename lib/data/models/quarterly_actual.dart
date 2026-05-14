class QuarterlyActual {
  final String? id;
  final String companyId;
  final int year;
  final int quarter; // 1, 2, 3, 4
  
  final double sales;
  final double ebitda;
  final double? investment;
  final String? addedBy;

  QuarterlyActual({
    this.id,
    required this.companyId,
    required this.year,
    required this.quarter,
    required this.sales,
    required this.ebitda,
    this.investment,
    this.addedBy,
  });

  factory QuarterlyActual.fromMap(Map<String, dynamic> map) {
    return QuarterlyActual(
      id: map['id'],
      companyId: map['company_id'],
      year: map['year'],
      quarter: map['quarter'],
      sales: map['sales'].toDouble(),
      ebitda: map['ebitda'].toDouble(),
      investment: map['investment']?.toDouble(),
      addedBy: map['added_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company_id': companyId,
      'year': year,
      'quarter': quarter,
      'sales': sales,
      'ebitda': ebitda,
      'investment': investment,
      'added_by': addedBy,
    };
  }
}
