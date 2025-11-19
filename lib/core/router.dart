import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Gate + Start
import '../features/gate/splash_screen.dart';
import '../features/auth/start_screen.dart'; // ✅ chemin correct

// Auth
import '../features/auth/login_screen.dart';
import '../features/auth/user_register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/pro/pro_register_screen.dart';

// Home (client)
import '../features/home/home_screen.dart';

// Bookings & provider (hérités)
import '../features/providers/provider_details_screen.dart';
import '../features/bookings/booking_flow_screen.dart';
import '../features/bookings/booking_details_screen.dart';

import '../features/bookings/my_bookings_screen.dart';

// Adopt
import '../features/adopt/adopt_create_screen.dart';


// Pro
import '../features/pro/pro_shell.dart';
import '../features/pro/pro_home_screen.dart';
import '../features/pro/pro_services_screen.dart';
import '../features/pro/pro_provider_agenda_screen.dart';
import '../features/pro/pro_availability_screen.dart';
import '../features/pro/pro_appointments_screen.dart';
import '../features/petshop/pro_petshop_home_screen.dart';
import '../features/petshop/petshop_products_screen.dart';
import '../features/petshop/petshop_product_edit_screen.dart';
import '../features/petshop/petshop_orders_screen.dart';
import '../features/petshop/petshop_list_screen.dart';
import '../features/petshop/petshop_products_user_screen.dart';
import '../features/pro/pro_daycare_home_screen.dart';
import '../features/pro/pro_settings_screen.dart';
import '../features/pro/pro_patients_screen.dart';

import '../features/admin/admin_hub_screen.dart';
import '../features/admin/admin_pages.dart';

// Map
import '../features/map/nearby_vets_map_screen.dart';
import '../features/map/provider_map_screen.dart';

// Vets
import '../features/vets/vets_list_screen.dart';
import '../features/vets/vet_details_screen.dart';

// Admin & states
import '../features/pro/pro_application_submitted_screen.dart';
import '../features/pro/pro_application_rejected_screen.dart';

// Profile
import '../features/profile/user_settings_screen.dart';

// Guards
import 'role_guard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/gate',
    routes: <RouteBase>[
      // -------- Gate / Start --------
      GoRoute(path: '/gate', builder: (_, _) => const RoleGateScreen()),
      GoRoute(
        path: '/start/user',
        builder: (_, _) => const StartScreen(variant: StartVariant.user),
      ),
      GoRoute(
        path: '/start/pro',
        builder: (_, _) => const StartScreen(variant: StartVariant.pro),
      ),

      // -------- Aliases & redirects utiles --------
      // ancien liens "vets" -> nouvelle route "explore/vets"
      GoRoute(path: '/vets', redirect: (_, _) => '/explore/vets'),
      GoRoute(
        path: '/vets/:id',
        redirect: (ctx, st) => '/explore/vets/${st.pathParameters['id']}',
      ),
      // ancien "/pro/pending" -> canonical
      GoRoute(
        path: '/pro/pending',
        redirect: (_, _) => '/pro/application/submitted',
      ),
      // racine pro -> home
      GoRoute(path: '/pro', redirect: (_, _) => '/pro/home'),

 GoRoute(
  path: '/booking-details',
  builder: (_, state) => BookingDetailsScreen(
    booking: (state.extra as Map<String, dynamic>?) ?? <String, dynamic>{},
  ),
),


      // -------- Admin --------
GoRoute(path: '/admin/hub', builder: (_, _) => const AdminHubScreen()),
GoRoute(path: '/admin/dashboard', redirect: (_, _) => '/admin/hub'),
GoRoute(path: '/admin/users', builder: (_, _) => const AdminUsersPage()),
GoRoute(path: '/admin/pros', builder:  (_, _) => const AdminProsApprovedPage()),
GoRoute(path: '/admin/applications', builder: (_, _) => const AdminApplicationsPage()),
GoRoute(path: '/admin/commissions', builder: (_, _) => const AdminCommissionsPage()),

      // -------- Auth --------
      GoRoute(
        path: '/auth/login',
        builder: (ctx, st) =>
            AuthLoginScreen(asRole: st.uri.queryParameters['as'] ?? 'user'),
      ),
      GoRoute(
        path: '/auth/register/user',
        name: 'registerUser',
        builder: (context, state) => const UserRegisterScreen(),
      ),
      GoRoute(
        path: '/auth/register/pro',
        name: 'registerPro',
        builder: (context, state) => const ProRegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (ctx, st) => ForgotPasswordScreen(
          asRole: st.uri.queryParameters['as'] ?? 'user',
        ),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (ctx, st) =>
            OtpScreen(asRole: st.uri.queryParameters['as'] ?? 'user'),
      ),

      // -------- States d’application PRO --------
      GoRoute(
        path: '/pro/application/submitted',
        builder: (_, _) => const ProApplicationSubmittedScreen(),
      ),
      GoRoute(
        path: '/pro/application/rejected',
        builder: (_, _) => const ProApplicationRejectedScreen(),
      ),

      // -------- Onboarding pet --------
      GoRoute(
        path: '/onboard/pet',
        builder: (_, _) => const _Placeholder(title: 'Onboarding Pet'),
      ),




      // -------- Home (client) --------
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/me/bookings',
        builder: (_, _) => const MyBookingsScreen(),
      ),

      // -------- Profil / Settings (user) --------
      GoRoute(
        path: '/settings',
        builder: (_, _) => const UserSettingsScreen(),
      ),

      // -------- Hérités (provider & booking) --------
      GoRoute(
        path: '/provider/:id',
        builder: (ctx, st) =>
            ProviderDetailsScreen(providerId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:providerId/:serviceId',
        builder: (ctx, st) => BookingFlowScreen(
          providerId: st.pathParameters['providerId']!,
          serviceId: st.pathParameters['serviceId']!,
        ),
      ),

      // -------- Map --------
      GoRoute(
        path: '/maps/provider',
        builder: (ctx, state) {
          final m = (state.extra ?? {}) as Map;
          return ProviderMapScreen(
            displayName: (m['displayName'] ?? 'Vétérinaire').toString(),
            address: (m['address'] ?? '').toString(),
            mapsUrl: (m['mapsUrl'] ?? '').toString(),
          );
        },
      ),
      GoRoute(
        path: '/maps/nearby',
        builder: (ctx, state) => const NearbyVetsMapScreen(),
      ),

      // -------- Nouveau flow Vet (liste → détail) --------
      GoRoute(path: '/explore/vets', builder: (_, _) => const VetListScreen()),
      GoRoute(
        path: '/explore/vets/:id',
        builder: (ctx, st) =>
            VetDetailsScreen(providerId: st.pathParameters['id']!),
      ),

      // -------- Flow Petshop (liste → produits) --------
      GoRoute(
        path: '/explore/petshop',
        builder: (_, _) => const PetshopListScreen(),
      ),
      GoRoute(
        path: '/explore/petshop/:id',
        builder: (ctx, st) => PetshopProductsUserScreen(
          providerId: st.pathParameters['id']!,
        ),
      ),

      // -------- Garderie / Petshop --------
      GoRoute(
        path: '/daycare/home',
        builder: (ctx, st) => const DaycareHomeScreen(),
      ),
      GoRoute(
        path: '/petshop/home',
        builder: (ctx, st) => const PetshopHomeScreen(),
      ),
      GoRoute(
        path: '/petshop/products',
        builder: (ctx, st) => const PetshopProductsScreen(),
      ),
      GoRoute(
        path: '/petshop/products/new',
        builder: (ctx, st) => const PetshopProductEditScreen(),
      ),
      GoRoute(
        path: '/petshop/products/:id',
        builder: (ctx, st) => PetshopProductEditScreen(
          productId: st.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/petshop/orders',
        builder: (ctx, st) => const PetshopOrdersScreen(),
      ),
      GoRoute(
        path: '/petshop/orders/:id',
        builder: (ctx, st) => const PetshopOrdersScreen(), // TODO: Create order details screen
      ),

      GoRoute(
        path: '/adopt/new',
        builder: (ctx, st) => const AdoptCreateScreen(),
      ),

      

      // -------- PRO (protégé + shell) --------
      ShellRoute(
        builder: (context, state, child) => RequireRole(
          roles: const ['PRO', 'ADMIN'],
          child: ProShell(child: child),
        ),
        routes: [
          GoRoute(path: '/pro/home', builder: (_, _) => const ProHomeScreen()),
          GoRoute(
            path: '/pro/agenda',
            builder: (_, _) => const ProviderAgendaScreen(),
          ),
          GoRoute(
            path: '/pro/services',
            builder: (_, _) => const ProServicesScreen(),
          ),
          GoRoute(
            path: '/pro/availability',
            builder: (_, _) => const ProAvailabilityScreen(),
          ),
          GoRoute(
            path: '/pro/appointments',
            builder: (_, _) => const ProAppointmentsScreen(),
          ),
          GoRoute(
            path: '/pro/patients',
            builder: (_, _) => const ProPatientsScreen(),
          ),
          // ✅ Settings passe sous le shell (protégé, back stack propre)
          GoRoute(
            path: '/pro/settings',
            builder: (ctx, st) => const ProSettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, st) => const _NotFoundPage(),
    debugLogDiagnostics: false,
  );
});

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SizedBox.shrink(),
    );
  }
}


class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page introuvable')));
  }
}
