import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'edit_plan_page.dart';
import 'saved_plans_page.dart';
import 'exercise_history_page.dart';
import '../controllers/exercise_controller.dart';
import '../data/exercise_repository.dart';
import '../models/planned_exercise.dart';
import '../models/set_log.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodayWorkoutPage extends StatefulWidget {
  const TodayWorkoutPage({
    super.key,
    this.userId,
    this.clientName,
    this.readOnly = false,
    this.onBackToProfile,
  });

  final String? userId;
  final String? clientName;
  final bool readOnly;
  final VoidCallback? onBackToProfile;

  @override
  State<TodayWorkoutPage> createState() => _TodayWorkoutPageState();
}

class _TodayWorkoutPageState extends State<TodayWorkoutPage> {
  late final ExerciseController controller;
  String? get _controllerTag =>
      widget.userId == null ? null : 'exercise-${widget.userId}';

  String get _activeUserId =>
      widget.userId ?? FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    controller = _provideController();
  }

  ExerciseController _provideController() {
    final userId = _activeUserId;
    final tag = _controllerTag;
    if (tag != null) {
      if (Get.isRegistered<ExerciseController>(tag: tag)) {
        return Get.find<ExerciseController>(tag: tag);
      }
      final ctrl = ExerciseController(
        repository: ExerciseRepository(),
        userId: userId,
      );
      return Get.put(ctrl, tag: tag);
    }
    if (Get.isRegistered<ExerciseController>()) {
      return Get.find<ExerciseController>();
    }
    final ctrl = ExerciseController(
      repository: ExerciseRepository(),
      userId: userId,
    );
    return Get.put(ctrl);
  }

  @override
  void dispose() {
    final tag = _controllerTag;
    if (tag != null && Get.isRegistered<ExerciseController>(tag: tag)) {
      Get.delete<ExerciseController>(tag: tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.clientName?.isNotEmpty == true
        ? '${widget.clientName} • Bugünkü Antrenman'
        : 'Bugünkü Antrenman';
    final actions = <Widget>[];
    if (!widget.readOnly) {
      actions.add(
        IconButton(
          icon: const Icon(CupertinoIcons.pencil),
          tooltip: 'Gün Planı Düzenle',
          onPressed: () => Get.to(() => EditPlanPage(userId: _activeUserId)),
        ),
      );
      actions.add(
        IconButton(
          icon: const Icon(CupertinoIcons.square_list),
          tooltip: 'Kayıtlı Planlar',
          onPressed: () => Get.to(
            () => SavedPlansPage(
              userId: _activeUserId,
              clientName: widget.clientName,
            ),
          ),
        ),
      );
    }
    if (widget.onBackToProfile != null) {
      actions.add(
        TextButton(
          onPressed: widget.onBackToProfile,
          child: const Text('Profilim'),
        ),
      );
    }
    return Scaffold(
      appBar: FittaAppBar(
        title: title,
        actions: actions.isEmpty ? null : actions,
      ),
      body: Column(
        children: [
          _DaySelector(controller: controller),
          Obx(() {
            final total = controller.todayPlan.length;
            final completed = controller.todayPlan
                .where((plan) => controller.savedExercises[plan.exerciseId] == true)
                .length;
            final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text('Gün ilerlemesi: $completed/$total'),
                      const Spacer(),
                      Text('${(progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(value: progress),
                ),
                AppSpacing.vSm,
              ],
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.todayPlan.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.todayPlan.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.square_list, size: 48),
                      AppSpacing.vSm,
                      const Text('Seçili gün için plan bulunamadı.'),
                      AppSpacing.vSm,
                      FilledButton(
                        onPressed: () => controller.loadPlanForSelectedDay(),
                        child: const Text('Yenile'),
                      ),
                    ],
                  ),
                );
              }

              final completedPlans = controller.todayPlan
                  .where((p) => controller.savedExercises[p.exerciseId] == true)
                  .toList(growable: false);
              final activePlans = controller.todayPlan
                  .where((p) => controller.savedExercises[p.exerciseId] != true)
                  .toList(growable: false);
              final itemCount =
                  activePlans.length + (completedPlans.isNotEmpty ? 1 : 0);

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index < activePlans.length) {
                    final plan = activePlans[index];
                    final logs = controller.logsByExerciseId[plan.exerciseId] ?? const [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkoutCard(
                        plan: plan,
                        logs: logs,
                        controller: controller,
                        userId: _activeUserId,
                        readOnly: widget.readOnly,
                      ),
                    );
                  }

                  return _CompletedSection(
                    plans: completedPlans,
                    controller: controller,
                    userId: _activeUserId,
                    readOnly: widget.readOnly,
                  );
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.controller});

  final ExerciseController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDayKey.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: ExerciseRepository.weekDayKeys.map((day) {
            final label = ExerciseRepository.weekDayLabels[day] ?? day.toUpperCase();
            final isSelected = day == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => controller.changeDay(day),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

enum _WorkoutMenuAction { move, remove }

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.plans,
    required this.controller,
    required this.userId,
    required this.readOnly,
  });

  final List<PlannedExercise> plans;
  final ExerciseController controller;
  final String userId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Tamamlanan çalışmalar', style: theme.textTheme.titleMedium),
        ),
        ...plans.map((plan) {
          final logs = controller.logsByExerciseId[plan.exerciseId] ?? const [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WorkoutCard(
              plan: plan,
              logs: logs,
              controller: controller,
              userId: userId,
              readOnly: readOnly,
            ),
          );
        }),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.plan,
    required this.logs,
    required this.controller,
    required this.userId,
    required this.readOnly,
  });

  final PlannedExercise plan;
  final List<SetLog> logs;
  final ExerciseController controller;
  final String userId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = controller.savedExercises[plan.exerciseId] == true;
    final fadedColor = saved ? Colors.green : null;
    final cardColor =
        saved ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.08) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              key: ValueKey(
                'workout-${plan.exerciseId}-${saved ? 'saved' : 'open'}',
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!readOnly)
                    _SaveExerciseButton(
                      controller: controller,
                      plan: plan,
                      compact: true,
                      readOnly: readOnly,
                    ),
                  if (!readOnly)
                    PopupMenuButton<_WorkoutMenuAction>(
                      icon: const Icon(CupertinoIcons.ellipsis_vertical),
                      onSelected: (action) => _handleMenuAction(context, action),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _WorkoutMenuAction.move,
                          child: Text('Günü değiştir'),
                        ),
                        PopupMenuItem(
                          value: _WorkoutMenuAction.remove,
                          child: Text('Plandan çıkar'),
                        ),
                      ],
                    ),
                  const Icon(CupertinoIcons.chevron_down),
                ],
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(color: fadedColor),
                  ),
                  AppSpacing.vXs,
                  Text(
                      '${plan.category} • ${plan.sets} x ${plan.type == 'time' ? (plan.seconds ?? plan.reps) : plan.reps}${plan.type == 'time' ? ' sn' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: fadedColor)),
                  AppSpacing.vXs,
                  Text(
                    'Bugün plan: ${_plannedValue(plan)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: fadedColor),
                  ),
                ],
              ),
              children: [
                AppSpacing.vSm,
                if ((plan.description ?? '').isNotEmpty) ...[
                  Text(plan.description!, style: theme.textTheme.bodySmall),
                  AppSpacing.vSm,
                ],
                ...List.generate(plan.sets, (i) {
                  final setNo = i + 1;
                  final existing = logs.firstWhere(
                    (log) => log.setNo == setNo,
                    orElse: () => SetLog(
                      setNo: setNo,
                      reps: plan.reps,
                      weight: plan.weight,
                      seconds: plan.seconds,
                    ),
                  );
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == plan.sets - 1 ? 0 : 10),
                    child: _SetRow(
                      plan: plan,
                      setLog: existing,
                      readOnly: readOnly,
                      onChanged: (reps, weight, seconds) => controller.updateSetLog(
                        exerciseId: plan.exerciseId,
                        setNo: setNo,
                        reps: reps,
                        weight: weight,
                        seconds: seconds,
                      ),
                    ),
                  );
                }),
                AppSpacing.vMd,
                _NextWeightField(
                  type: plan.type,
                  initialValue: controller.nextWeights[plan.exerciseId] ??
                      (plan.type == 'time'
                          ? plan.seconds?.toDouble()
                          : plan.nextWeight ?? plan.weight),
                  onChanged: (value) => controller.updateNextWeight(plan.exerciseId, value),
                  readOnly: readOnly,
                ),
                AppSpacing.vSm,
                if (!readOnly) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _SaveExerciseButton(
                      controller: controller,
                      plan: plan,
                      compact: false,
                      readOnly: readOnly,
                    ),
                  ),
                  AppSpacing.vSm,
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Get.to(
                      () => ExerciseHistoryPage(
                        exerciseId: plan.exerciseId,
                        exerciseName: plan.name,
                        userId: userId,
                      ),
                    ),
                    icon: const Icon(CupertinoIcons.time),
                    label: const Text('Geçmişi gör'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Obx(() {
          final saved = controller.savedExercises[plan.exerciseId] ?? false;
          if (!saved) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Kaydedildi',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          );
        }),
      ],
    );
  }

  String _plannedValue(PlannedExercise plan) {
    switch (plan.type) {
      case 'time':
        return '${plan.seconds ?? 0} sn';
      case 'weight':
        return '${plan.weight?.toStringAsFixed(1) ?? '--'} kg';
      default:
        return '${plan.reps} tekrar';
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _WorkoutMenuAction action,
  ) async {
    switch (action) {
      case _WorkoutMenuAction.move:
        final targetDay = await _selectTargetDay(context);
        if (targetDay != null && targetDay != controller.selectedDayKey.value) {
          await controller.moveExerciseToDay(plan, targetDay);
        }
        break;
      case _WorkoutMenuAction.remove:
        await controller.removeExerciseFromToday(plan.exerciseId);
        break;
    }
  }

  Future<String?> _selectTargetDay(BuildContext context) async {
    final current = controller.selectedDayKey.value;
    final firstOtherDay =
        ExerciseRepository.weekDayKeys.firstWhere((d) => d != current, orElse: () => current);
    String selected = firstOtherDay;
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hangi güne taşıyalım?', style: Theme.of(context).textTheme.titleMedium),
                  AppSpacing.vSm,
                  Wrap(
                    spacing: 8,
                    children: ExerciseRepository.weekDayKeys.map((day) {
                      final label = ExerciseRepository.weekDayLabels[day] ?? day.toUpperCase();
                      final isSelected = day == selected;
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selected = day),
                      );
                    }).toList(),
                  ),
                  AppSpacing.vMd,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected == current
                          ? null
                          : () => Navigator.of(context).pop(selected),
                      child: const Text('Taşı'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SaveExerciseButton extends StatelessWidget {
  const _SaveExerciseButton({
    required this.controller,
    required this.plan,
    required this.compact,
    required this.readOnly,
  });

  final ExerciseController controller;
  final PlannedExercise plan;
  final bool compact;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (readOnly) return const SizedBox.shrink();
    return Obx(() {
      final saving = controller.savingExercises[plan.exerciseId] ?? false;
      final saved = controller.savedExercises[plan.exerciseId] ?? false;
      final colorScheme = Theme.of(context).colorScheme;
      final label = saving
          ? 'Kaydediliyor...'
          : saved
              ? 'Güncelle'
              : 'Kaydet';
      final icon = saving
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: compact ? colorScheme.primary : colorScheme.onPrimary,
              ),
            )
          : Icon(
              saved ? CupertinoIcons.pencil : CupertinoIcons.check_mark_circled,
              size: 16,
            );

      if (compact) {
        return TextButton.icon(
          onPressed: saving ? null : () => controller.saveExercise(plan.exerciseId),
          icon: icon,
          label: Text(label),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 36),
          ),
        );
      }

      return FilledButton.icon(
        onPressed: saving ? null : () => controller.saveExercise(plan.exerciseId),
        icon: icon,
        label: Text(label),
      );
    });
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    required this.plan,
    required this.setLog,
    required this.onChanged,
    required this.readOnly,
  });

  final PlannedExercise plan;
  final SetLog setLog;
  final void Function(int reps, double? weight, int? seconds) onChanged;
  final bool readOnly;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final TextEditingController secondsController;

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController(
        text: widget.setLog.weight?.toStringAsFixed(1) ?? '');
    repsController = TextEditingController(text: widget.setLog.reps.toString());
    secondsController = TextEditingController(
        text: widget.setLog.seconds?.toString() ?? '');
  }

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    secondsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.setLog != oldWidget.setLog) {
      _updateController(weightController, widget.setLog.weight, isWeight: true);
      _updateController(repsController, widget.setLog.reps);
      _updateController(secondsController, widget.setLog.seconds);
    }
  }

  void _updateController(TextEditingController controller, num? value,
      {bool isWeight = false}) {
    if (value == null) {
      if (controller.text.isNotEmpty) {
        controller.text = '';
      }
      return;
    }

    final currentVal = num.tryParse(controller.text);
    if (currentVal == value) return;

    final newText =
        isWeight ? (value as double).toStringAsFixed(1) : value.toString();
    if (controller.text != newText) {
      controller.text = newText;
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set ${widget.setLog.setNo}',
            style: Theme.of(context).textTheme.bodySmall),
        AppSpacing.vXs,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(
                    'reps-${widget.plan.exerciseId}-${widget.setLog.setNo}'),
                controller: widget.plan.type == 'time'
                    ? secondsController
                    : repsController,
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
                decoration: InputDecoration(
                  labelText: widget.plan.type == 'time' ? 'Süre (sn)' : 'Tekrar',
                ),
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        final parsed = int.tryParse(value) ?? 0;
                        final weight = widget.plan.type == 'time'
                            ? widget.setLog.weight
                            : double.tryParse(weightController.text);
                        final seconds = widget.plan.type == 'time'
                            ? parsed
                            : widget.setLog.seconds;
                        final reps =
                            widget.plan.type == 'time' ? widget.setLog.reps : parsed;
                        widget.onChanged(reps, weight, seconds);
                      },
              ),
            ),
            AppSpacing.hSm,
            Expanded(
              child: TextFormField(
                key: ValueKey(
                    'weight-${widget.plan.exerciseId}-${widget.setLog.setNo}'),
                controller: weightController,
                keyboardType: TextInputType.number,
                enabled: !widget.readOnly,
                decoration: InputDecoration(
                  labelText:
                      widget.plan.type == 'time' ? 'Notlar' : 'Ağırlık (kg)',
                ),
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        final weight = double.tryParse(value);
                        final seconds = widget.plan.type == 'time'
                            ? int.tryParse(secondsController.text)
                            : widget.setLog.seconds;
                        final reps = widget.plan.type == 'time'
                            ? widget.setLog.reps
                            : int.tryParse(repsController.text) ?? 0;
                        widget.onChanged(reps, weight, seconds);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NextWeightField extends StatefulWidget {
  const _NextWeightField({
    required this.initialValue,
    required this.onChanged,
    required this.type,
    required this.readOnly,
  });

  final double? initialValue;
  final String type;
  final void Function(double?) onChanged;
  final bool readOnly;

  @override
  State<_NextWeightField> createState() => _NextWeightFieldState();
}

class _NextWeightFieldState extends State<_NextWeightField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    final isTime = widget.type == 'time';
    controller = TextEditingController(
      text: widget.initialValue != null
          ? widget.initialValue!.toStringAsFixed(isTime ? 0 : 1)
          : '',
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NextWeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _updateController();
    }
  }

  void _updateController() {
    final value = widget.initialValue;
    if (value == null) {
      if (controller.text.isNotEmpty) {
        controller.text = '';
      }
      return;
    }

    final currentVal = double.tryParse(controller.text);
    if (currentVal == value) return;

    final isTime = widget.type == 'time';
    final newText = value.toStringAsFixed(isTime ? 0 : 1);

    if (controller.text != newText) {
      controller.text = newText;
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTime = widget.type == 'time';
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      enabled: !widget.readOnly,
      decoration: InputDecoration(
        labelText: isTime
            ? 'Sonraki seans için süre (sn)'
            : 'Sonraki seans için ağırlık',
        hintText: isTime ? 'Örn: 60' : 'Örn: 35',
      ),
      onChanged:
          widget.readOnly ? null : (value) => widget.onChanged(double.tryParse(value)),
    );
  }
}
