import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/business/loan/data/models/loan_model.dart';

final loanProvider =
    AsyncNotifierProvider<LoanNotifier, List<LoanModel>>(
  LoanNotifier.new,
);

class LoanNotifier extends AsyncNotifier<List<LoanModel>> {
  @override
  FutureOr<List<LoanModel>> build() async {
    // Initial mock Qard Al-Hasan interest-free loans
    return [
      LoanModel(
        id: '1',
        personName: 'Brother Ahmed',
        type: LoanType.lent,
        amount: 500.0,
        repaidAmount: 200.0,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        notes: 'Help with grocery startup costs.',
      ),
      LoanModel(
        id: '2',
        personName: 'Uncle Yusuf',
        type: LoanType.borrowed,
        amount: 1000.0,
        repaidAmount: 500.0,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        notes: 'Benevolent loan to repair car.',
      ),
      LoanModel(
        id: '3',
        personName: 'Sister Fatimah',
        type: LoanType.lent,
        amount: 300.0,
        repaidAmount: 300.0,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        notes: 'School books purchase aid.',
      ),
    ];
  }

  Future<void> addLoan(LoanModel loan) async {
    final current = state.value ?? [];
    state = AsyncData([...current, loan]);
  }

  Future<void> recordRepayment(String id, double amount) async {
    final current = state.value ?? [];
    final updated = current.map((loan) {
      if (loan.id == id) {
        final newRepaid = (loan.repaidAmount + amount).clamp(0.0, loan.amount);
        return loan.copyWith(repaidAmount: newRepaid);
      }
      return loan;
    }).toList();
    state = AsyncData(updated);
  }

  Future<void> deleteLoan(String id) async {
    final current = state.value ?? [];
    final updated = current.where((l) => l.id != id).toList();
    state = AsyncData(updated);
  }
}
