import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the active tab index in MainLayout
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setTab(int index) {
    state = index;
  }
}
