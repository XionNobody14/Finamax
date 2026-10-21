import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finamax/main.dart';
import 'package:finamax/providers/auth_provider.dart';
import 'package:finamax/providers/finance_provider.dart';
import 'package:finamax/providers/spending_budget_provider.dart';
import 'package:finamax/models/user_profile.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserProfile? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFinanceProvider extends ChangeNotifier implements FinanceProvider {
  @override
  UserProfile? get profile => null;

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FinamaX App smoke test - renders correctly with dependency injection', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider();
    final mockFinance = MockFinanceProvider();
    final budgetProvider = SpendingBudgetProvider();

    await tester.pumpWidget(
      FinamaXApp(
        authProvider: mockAuth,
        financeProvider: mockFinance,
        spendingBudgetProvider: budgetProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FinamaXApp), findsOneWidget);
  });
}
