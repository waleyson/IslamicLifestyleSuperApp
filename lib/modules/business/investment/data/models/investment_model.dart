class InvestmentAsset {
  final String id;
  final String name;
  final String category; // 'Sukuk', 'Equity', 'Real Estate'
  final double amountInvested;
  final double currentValue;
  final DateTime purchaseDate;
  final String emoji;

  const InvestmentAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.amountInvested,
    required this.currentValue,
    required this.purchaseDate,
    required this.emoji,
  });

  double get returnAmount => currentValue - amountInvested;
  double get returnPercentage => amountInvested > 0 ? (returnAmount / amountInvested) * 100 : 0.0;

  InvestmentAsset copyWith({
    double? currentValue,
  }) {
    return InvestmentAsset(
      id: id,
      name: name,
      category: category,
      amountInvested: amountInvested,
      currentValue: currentValue ?? this.currentValue,
      purchaseDate: purchaseDate,
      emoji: emoji,
    );
  }
}
