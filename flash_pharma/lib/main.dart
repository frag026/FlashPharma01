import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/pharmacy_register_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/send_otp_screen.dart';
import 'screens/auth/verify_otp_screen.dart';

// Patient screens
import 'screens/patient/home_screen.dart';
import 'screens/patient/cart_screen.dart';
import 'screens/patient/checkout_screen.dart';
import 'screens/patient/order_success_screen.dart';
import 'screens/patient/pharmacy_detail_screen.dart';
import 'screens/patient/pharmacy_map_screen.dart';
import 'screens/patient/nearby_pharmacies_screen.dart';
import 'screens/patient/order_tracking_screen.dart';
import 'screens/patient/my_orders_screen.dart';
import 'screens/patient/upload_prescription_screen.dart';

// Pharmacy screens
import 'screens/pharmacy/pharmacy_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FlashPharmaApp());
}

class FlashPharmaApp extends StatelessWidget {
  const FlashPharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Flash Pharma',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case '/login':
        return _slide(const LoginScreen());
      case '/register':
        return _slide(const RegisterScreen());
      case '/signup':
        return _slide(const SignupScreen());
      case '/pharmacy-register':
        return _slide(const PharmacyRegisterScreen());
      case '/send-otp':
        return _slide(const SendOtpScreen());
      case '/verify-otp':
        final args = settings.arguments;
        String phone = '';
        String? name;
        if (args is String) {
          phone = args;
        } else if (args is Map) {
          phone = args['phone'] as String;
          name = args['name'] as String?;
        }
        return _slide(VerifyOtpScreen(phone: phone, name: name));

      // Patient
      case '/home':
        return _slide(const HomeScreen());
      case '/cart':
        return _slide(const CartScreen());
      case '/checkout':
        return _slide(const CheckoutScreen());
      case '/order-success':
        return _slide(const OrderSuccessScreen());
      case '/nearby-pharmacies':
        return _slide(const NearbyPharmaciesScreen());
      case '/my-orders':
        return _slide(const MyOrdersScreen());
      case '/upload-prescription':
        return _slide(const UploadPrescriptionScreen());
      case '/pharmacy-map':
        return _slide(const PharmacyMapScreen());

      case '/pharmacy-detail':
        final pharmacyId = settings.arguments as String;
        return _slide(PharmacyDetailScreen(pharmacyId: pharmacyId));

      case '/order-tracking':
        final orderId = settings.arguments as String;
        return _slide(OrderTrackingScreen(orderId: orderId));

      // Pharmacy
      case '/pharmacy-home':
        return _slide(const PharmacyHomeScreen());

      default:
        return _slide(const LoginScreen());
    }
  }

  static Route<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_pharmacy_rounded,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
              SizedBox(height: 16),
              Text(
                'Flash Pharma',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.primaryGreen),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    if (authProvider.role == AppConstants.rolePharmacy) {
      return const PharmacyHomeScreen();
    }

    return const HomeScreen();
  }
}
