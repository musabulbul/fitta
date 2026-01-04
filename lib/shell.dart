import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'features/exercises/views/exercises_page.dart';
import 'features/measurements/views/measurements_page.dart';
import 'features/profile/views/profile_page.dart';
import 'features/weight/views/weight_page.dart';

class FittaShell extends StatefulWidget {
  const FittaShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<FittaShell> createState() => _FittaShellState();
}

class _FittaShellState extends State<FittaShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    ExercisesPage(),
    WeightPage(),
    MeasurementsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex.clamp(0, _pages.length - 1).toInt();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flame_fill),
            label: 'Egzersiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Kilo',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_pie_fill),
            label: 'Ölçüler',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
