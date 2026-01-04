import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitta/core/utils/body_fat_calculator.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final _heightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  String _gender = 'male';
  double? _result;
  String? _error;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    _neckCtrl.dispose();
    _hipCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _error = null;
      _result = null;
    });

    final height = double.tryParse(_heightCtrl.text.trim());
    final waist = double.tryParse(_waistCtrl.text.trim());
    final neck = double.tryParse(_neckCtrl.text.trim());
    final hip = double.tryParse(_hipCtrl.text.trim());

    if (height == null || height <= 0 || waist == null || waist <= 0) {
      setState(() => _error = 'Lutfen boy ve bel degerlerini girin.');
      return;
    }
    if (neck == null || neck <= 0) {
      setState(() => _error = 'Lutfen boyun degerini girin.');
      return;
    }
    if (_gender == 'female' && (hip == null || hip <= 0)) {
      setState(() => _error = 'Kadinlar icin kalca degeri gereklidir.');
      return;
    }

    final result = calculateBodyFat(
      gender: _gender,
      height: height,
      waist: waist,
      hip: _gender == 'female' ? hip : null,
      neck: neck,
    );

    if (result == null) {
      setState(() => _error = 'Degerleri kontrol edin ve tekrar deneyin.');
      return;
    }

    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const FittaAppBar(title: 'Fitta'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Misafir Modu',
            style: theme.textTheme.headlineSmall,
          ),
          AppSpacing.vSm,
          Text(
            'Hesap olusturmadan kullanabileceginiz araclar.',
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.vMd,
          FittaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vucut Yag Orani', style: theme.textTheme.titleMedium),
                AppSpacing.vSm,
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Cinsiyet'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Erkek')),
                    DropdownMenuItem(value: 'female', child: Text('Kadin')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _gender = value);
                  },
                ),
                AppSpacing.vSm,
                TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Boy (cm)'),
                ),
                AppSpacing.vSm,
                TextField(
                  controller: _waistCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bel (cm)'),
                ),
                AppSpacing.vSm,
                TextField(
                  controller: _neckCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Boyun (cm)'),
                ),
                if (_gender == 'female') ...[
                  AppSpacing.vSm,
                  TextField(
                    controller: _hipCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kalca (cm)'),
                  ),
                ],
                AppSpacing.vMd,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _calculate,
                    child: const Text('Hesapla'),
                  ),
                ),
                if (_result != null || _error != null) ...[
                  AppSpacing.vSm,
                  if (_result != null)
                    Text(
                      'Tahmini yag orani: %${_result!.toStringAsFixed(1)}',
                      style: theme.textTheme.titleSmall,
                    )
                  else
                    Text(
                      _error ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ],
            ),
          ),
          AppSpacing.vMd,
          OutlinedButton.icon(
            icon: const Icon(CupertinoIcons.person_crop_circle),
            label: const Text('Giris yap / Kayit ol'),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }
}
