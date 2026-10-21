import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'services/storage_service.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/spending_budget_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización oficial de Firebase para Android, iOS y Web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final storageService = StorageService();
  await storageService.init();

  final firestoreService = FirestoreService();
  final authService = AuthService(firestoreService: firestoreService);

  runApp(
    FinamaXApp(
      storageService: storageService,
      firestoreService: firestoreService,
      authService: authService,
    ),
  );
}

class FinamaXApp extends StatelessWidget {
  final StorageService? storageService;
  final FirestoreService? firestoreService;
  final AuthService? authService;
  final AuthProvider? authProvider;
  final FinanceProvider? financeProvider;
  final SpendingBudgetProvider? spendingBudgetProvider;

  const FinamaXApp({
    super.key,
    this.storageService,
    this.firestoreService,
    this.authService,
    this.authProvider,
    this.financeProvider,
    this.spendingBudgetProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (authProvider != null)
          ChangeNotifierProvider.value(value: authProvider!)
        else
          ChangeNotifierProvider(
            create: (_) {
              final firestore = firestoreService ?? FirestoreService();
              final auth = authService ?? AuthService(firestoreService: firestore);
              return AuthProvider(auth, firestore);
            },
          ),
        if (financeProvider != null)
          ChangeNotifierProvider.value(value: financeProvider!)
        else
          ChangeNotifierProvider(
            create: (_) {
              final storage = storageService ?? StorageService();
              final firestore = firestoreService ?? FirestoreService();
              return FinanceProvider(
                storageService: storage,
                firestoreService: firestore,
              );
            },
          ),
        if (spendingBudgetProvider != null)
          ChangeNotifierProvider.value(value: spendingBudgetProvider!)
        else
          ChangeNotifierProvider(create: (_) => SpendingBudgetProvider()),
      ],
      child: MaterialApp(
        title: 'FinamaX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightOrganicTheme,
        home: const AppRootGate(),
      ),
    );
  }
}

class AppRootGate extends StatefulWidget {
  const AppRootGate({super.key});

  @override
  State<AppRootGate> createState() => _AppRootGateState();
}

class _AppRootGateState extends State<AppRootGate> {
  String? _loadedUserId;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: AppColors.forestGreen, size: 48),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppColors.forestGreen),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated && auth.currentUser != null) {
      final currentUserId = auth.currentUser!.id;
      if (_loadedUserId != currentUserId) {
        _loadedUserId = currentUserId;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await finance.loadData(auth.currentUser!);
          budget.updateReport(finance);
        });
      }
      return const MainNavigationScreen();
    }

    _loadedUserId = null;
    return const AuthScreen();
  }
}
