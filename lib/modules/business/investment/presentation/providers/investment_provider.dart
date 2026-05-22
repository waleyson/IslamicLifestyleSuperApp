import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/business/investment/data/models/investment_model.dart';

final investmentProvider =
    AsyncNotifierProvider<InvestmentNotifier, List<InvestmentAsset>>(
  InvestmentNotifier.new,
);

class InvestmentNotifier extends AsyncNotifier<List<InvestmentAsset>> {
  @override
  FutureOr<List<InvestmentAsset>> build() async {
    // Initial mock Shariah-compliant investments
    return [
      InvestmentAsset(
        id: '1',
        name: 'SPSPS Global Sukuk ETF',
        category: 'Sukuk',
        amountInvested: 5000.0,
        currentValue: 5240.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
        emoji: '📈',
      ),
      InvestmentAsset(
        id: '2',
        name: 'Wahed FTSE USA Shariah ETF',
        category: 'Equity',
        amountInvested: 3000.0,
        currentValue: 3480.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 60)),
        emoji: '💼',
      ),
      InvestmentAsset(
        id: '3',
        name: 'Halal London Real Estate REIT',
        category: 'Real Estate',
        amountInvested: 10000.0,
        currentValue: 10850.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 120)),
        emoji: '🏢',
      ),
    ];
  }

  Future<void> addInvestment(InvestmentAsset asset) async {
    final current = state.value ?? [];
    state = AsyncData([...current, asset]);
  }

  Future<void> updateCurrentValue(String id, double newCurrentValue) async {
    final current = state.value ?? [];
    final updated = current.map((asset) {
      if (asset.id == id) {
        return asset.copyWith(currentValue: newCurrentValue);
      }
      return asset;
    }).toList();
    state = AsyncData(updated);
  }
}
