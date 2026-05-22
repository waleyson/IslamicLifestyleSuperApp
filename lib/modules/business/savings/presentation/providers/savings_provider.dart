import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/savings_model.dart';

final savingsProvider =
    AsyncNotifierProvider<SavingsNotifier, List<SavingsGoal>>(
  SavingsNotifier.new,
);

class SavingsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  @override
  FutureOr<List<SavingsGoal>> build() async {
    // Mock goals — replace with Hive persistence in future
    return [
      const SavingsGoal(
        id: '1',
        name: 'Hajj Fund',
        emoji: '🕋',
        targetAmount: 8000,
        currentAmount: 3250,
        currency: 'USD',
      ),
      const SavingsGoal(
        id: '2',
        name: 'Zakat Savings',
        emoji: '🤲',
        targetAmount: 2500,
        currentAmount: 2500,
        currency: 'USD',
      ),
      const SavingsGoal(
        id: '3',
        name: 'Islamic School Fees',
        emoji: '📚',
        targetAmount: 5000,
        currentAmount: 1800,
        currency: 'USD',
      ),
      const SavingsGoal(
        id: '4',
        name: 'Emergency Sadaqah',
        emoji: '💰',
        targetAmount: 1000,
        currentAmount: 420,
        currency: 'USD',
      ),
    ];
  }

  Future<void> addContribution(String goalId, double amount) async {
    final current = state.value ?? [];
    final updated = current.map((g) {
      if (g.id == goalId) {
        return g.copyWith(currentAmount: g.currentAmount + amount);
      }
      return g;
    }).toList();
    state = AsyncData(updated);
  }

  Future<void> addGoal(SavingsGoal goal) async {
    final current = state.value ?? [];
    state = AsyncData([...current, goal]);
  }
}
