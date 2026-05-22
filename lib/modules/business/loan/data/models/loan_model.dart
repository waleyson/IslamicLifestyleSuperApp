enum LoanType { borrowed, lent }

class LoanModel {
  final String id;
  final String personName;
  final LoanType type;
  final double amount;
  final double repaidAmount;
  final DateTime dueDate;
  final String notes;

  const LoanModel({
    required this.id,
    required this.personName,
    required this.type,
    required this.amount,
    required this.repaidAmount,
    required this.dueDate,
    required this.notes,
  });

  double get remainingAmount => (amount - repaidAmount).clamp(0.0, double.infinity);
  bool get isSettled => remainingAmount <= 0;

  LoanModel copyWith({
    double? repaidAmount,
  }) {
    return LoanModel(
      id: id,
      personName: personName,
      type: type,
      amount: amount,
      repaidAmount: repaidAmount ?? this.repaidAmount,
      dueDate: dueDate,
      notes: notes,
    );
  }
}
