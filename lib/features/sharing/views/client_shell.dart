import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/features/exercises/views/today_workout_page.dart';
import 'package:fitta/features/measurements/views/measurements_page.dart';
import 'package:fitta/features/weight/views/weight_page.dart';
import 'package:fitta/features/auth/auth_gate.dart';
import '../models/client_link.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key, required this.client});

  final ClientLink client;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  late final List<_ClientTab> _tabs;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs();
  }

  List<_ClientTab> _buildTabs() {
    final client = widget.client;
    final name = client.ownerDisplayName.isNotEmpty
        ? client.ownerDisplayName
        : (client.ownerEmail.isNotEmpty ? client.ownerEmail : client.ownerUserId);
    final readOnly = client.role == 'viewer';
    final onBackToProfile = () => Get.offAll(() => const AuthGate());

    final tabs = <_ClientTab>[];

    if (client.shareWorkouts) {
      tabs.add(
        _ClientTab(
          label: 'Antrenman',
          icon: CupertinoIcons.flame_fill,
          page: TodayWorkoutPage(
            userId: client.ownerUserId,
            clientName: name,
            readOnly: readOnly,
            onBackToProfile: onBackToProfile,
          ),
        ),
      );
    } else {
      tabs.add(
        _ClientTab(
          label: 'Antrenman',
          icon: CupertinoIcons.flame_fill,
          page: _AccessDeniedPage(
            title: '$name • Bugünkü Antrenman',
            message: 'Egzersiz bilgileri paylaşılmadı.',
            onBackToProfile: onBackToProfile,
          ),
        ),
      );
    }

    if (client.shareWeight) {
      tabs.add(
        _ClientTab(
          label: 'Kilo',
          icon: CupertinoIcons.chart_bar_alt_fill,
          page: WeightPage(
            userId: client.ownerUserId,
            clientName: name,
            readOnly: readOnly,
            onBackToProfile: onBackToProfile,
          ),
        ),
      );
    }

    if (client.shareMeasurements) {
      tabs.add(
        _ClientTab(
          label: 'Ölçü',
          icon: CupertinoIcons.chart_pie_fill,
          page: MeasurementsPage(
            userId: client.ownerUserId,
            clientName: name,
            readOnly: readOnly,
            onBackToProfile: onBackToProfile,
          ),
        ),
      );
    }

    return tabs;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.map((t) => t.page).toList(growable: false),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ClientTab {
  const _ClientTab({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({
    required this.title,
    required this.message,
    this.onBackToProfile,
  });

  final String title;
  final String message;
  final VoidCallback? onBackToProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FittaAppBar(
        title: title,
        actions: _buildActions(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.lock_shield_fill, size: 48),
              AppSpacing.vSm,
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (onBackToProfile == null) return null;
    return [
      TextButton(
        onPressed: onBackToProfile,
        child: const Text('Profilim'),
      ),
    ];
  }
}
