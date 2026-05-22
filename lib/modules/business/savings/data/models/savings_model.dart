class SavingsGoal {
  final String id;
  final String name;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final String currency;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    this.currency = 'USD',
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  SavingsGoal copyWith({double? currentAmount}) => SavingsGoal(
        id: id,
        name: name,
        emoji: emoji,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        currency: currency,
      );
}
