class Company {
  final String id;
  final String name;
  final String ticker;
  final String? sector;

  Company({
    required this.id,
    required this.name,
    required this.ticker,
    this.sector,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      ticker: map['ticker'],
      sector: map['sector'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ticker': ticker,
      'sector': sector,
    };
  }
}
