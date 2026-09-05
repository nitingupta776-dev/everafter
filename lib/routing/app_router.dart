import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/data/trip_repository.dart';
import 'package:everafter/screens/collection_screen.dart';
import 'package:everafter/screens/exhibit_screen.dart';
import 'package:everafter/screens/gallery_admin_screen.dart';
import 'package:everafter/screens/idle_screen.dart';
import 'package:everafter/screens/intro_screen.dart';
import 'package:everafter/screens/nfc_trip_experience_screen.dart';
import 'package:everafter/screens/trip_admin_screen.dart';
import 'package:everafter/screens/trip_experience_screen.dart';
import 'package:everafter/screens/taste_of_japan_screen.dart';
import 'package:everafter/state/museum_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  var handledNfcDetectionRevision = 0;
  ref.listen<MuseumState>(museumControllerProvider, (previous, next) {
    refresh.refresh();
  });
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: kIsWeb && Uri.base.path != '/' ? Uri.base.path : '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadePage(state, const IdleScreen()),
      ),
      GoRoute(
        path: '/admin/gallery',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const GalleryAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/trips',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const TripAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/intro/:uid',
        pageBuilder: (context, state) {
          final uid = state.pathParameters['uid']!;
          final artifact = ref.read(tripRepositoryProvider).artifactByUid(uid);
          return _fadePage(state, IntroScreen(artifact: artifact));
        },
      ),
      GoRoute(
        path: '/taste/:slug',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: TripTasteMenuScreen(
            trip: _tripForSlug(state.pathParameters['slug']),
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:slug',
        pageBuilder: (context, state) {
          final routeData = state.extra as TripExperienceRouteData?;
          final trip =
              routeData?.trip ?? _tripForSlug(state.pathParameters['slug']);
          final heroTag = routeData?.heroTag ?? 'trip-route-${trip.slug}';
          return _tripExperiencePage(
            state,
            TripExperienceScreen(
              trip: trip,
              heroTag: heroTag,
              onReturnToGallery: () =>
                  ref.read(museumControllerProvider.notifier).returnToIdle(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/nfc/:slug',
        pageBuilder: (context, state) {
          final trip = _tripForSlug(state.pathParameters['slug']);
          return _nfcExperiencePage(
            state,
            NfcTripExperienceScreen(
              key: ValueKey('nfc-trip-experience-${trip.slug}'),
              trip: trip,
              magnetAssetPath: _nfcMagnetAssetFor(trip),
              onReturnToGallery: () =>
                  ref.read(museumControllerProvider.notifier).returnToIdle(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/exhibit/:uid',
        pageBuilder: (context, state) {
          final uid = state.pathParameters['uid']!;
          final artifact = ref.read(tripRepositoryProvider).artifactByUid(uid);
          return _fadePage(state, ExhibitScreen(artifact: artifact));
        },
      ),
      GoRoute(
        path: '/collection',
        pageBuilder: (context, state) =>
            _fadePage(state, const CollectionScreen()),
      ),
    ],
    redirect: (context, routerState) {
      final museumState = ref.read(museumControllerProvider);
      if (museumState.nfcDetectionRevision <= handledNfcDetectionRevision) {
        return null;
      }
      handledNfcDetectionRevision = museumState.nfcDetectionRevision;
      final selected = museumState.selectedArtifact;
      if (selected == null) {
        return null;
      }
      final trip = _tripForPlace(selected.place);
      final target = trip == null
          ? '/intro/${selected.uid}'
          : '/nfc/${trip.slug}';
      return routerState.matchedLocation == target ? null : target;
    },
    refreshListenable: refresh,
  );
  ref.onDispose(router.dispose);
  return router;
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

TripGalleryItem _tripForSlug(String? slug) {
  final allTrips = TripCatalogStore.instance.allTrips;
  return allTrips.firstWhere(
    (trip) => trip.slug == slug,
    orElse: () => allTrips.first,
  );
}

TripGalleryItem? _tripForPlace(String place) {
  for (final trip in TripCatalogStore.instance.allTrips) {
    if (trip.name == place) {
      return trip;
    }
  }
  return null;
}

String _nfcMagnetAssetFor(TripGalleryItem trip) {
  return switch (trip.slug) {
    'china' => 'assets/images/experience/china-nfc-magnet-reveal.png',
    'hong-kong' => 'assets/images/experience/hong-kong-nfc-magnet-reveal.png',
    'japan' => 'assets/images/experience/japan-nfc-magnet-reveal-fox.png',
    'south-korea' =>
      'assets/images/experience/south-korea-nfc-magnet-reveal-spacious.png',
    'taiwan' =>
      'assets/images/experience/taiwan-nfc-magnet-reveal-bubble-tea.png',
    'vietnam' => 'assets/images/experience/vietnam-nfc-magnet-reveal-lotus.png',
    _ => trip.assetPath,
  };
}

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

CustomTransitionPage<void> _tripExperiencePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 1900),
    reverseTransitionDuration: const Duration(milliseconds: 1050),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final sceneOpacity = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.18, 0.82, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: sceneOpacity, child: child);
    },
  );
}

CustomTransitionPage<void> _nfcExperiencePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 620),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}
