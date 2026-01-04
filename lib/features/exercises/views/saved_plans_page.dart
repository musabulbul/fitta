import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import '../controllers/workout_plan_template_controller.dart';
import '../data/exercise_repository.dart';
import '../data/workout_plan_template_repository.dart';
import '../models/workout_plan_template.dart';
import 'edit_saved_plan_page.dart';

class SavedPlansPage extends StatelessWidget {
  const SavedPlansPage({super.key, this.userId, this.clientName});

  final String? userId;
  final String? clientName;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final targetUserId = userId ?? currentUserId;
    final isAssignmentContext = currentUserId != targetUserId;
    final controller = _provideController(targetUserId);
    final title = clientName?.isNotEmpty == true
        ? '${clientName} • Kayıtlı Planlar'
        : 'Kayıtlı Planlar';

    return Scaffold(
      appBar: FittaAppBar(title: title),
      body: isAssignmentContext
          ? StreamBuilder<List<WorkoutPlanTemplate>>(
              stream: WorkoutPlanTemplateRepository().watchPlanTemplates(currentUserId),
              builder: (context, snapshot) {
                final trainerTemplates = snapshot.data ?? const <WorkoutPlanTemplate>[];
                return _buildBody(
                  context: context,
                  controller: controller,
                  trainerTemplates: trainerTemplates,
                  currentUserId: currentUserId,
                  targetUserId: targetUserId,
                  isAssignmentContext: isAssignmentContext,
                );
              },
            )
          : _buildBody(
              context: context,
              controller: controller,
              trainerTemplates: const <WorkoutPlanTemplate>[],
              currentUserId: currentUserId,
              targetUserId: targetUserId,
              isAssignmentContext: isAssignmentContext,
            ),
      floatingActionButton: isAssignmentContext
          ? null
          : FloatingActionButton(
              onPressed: () => Get.to(() => const EditSavedPlanPage()),
              child: const Icon(CupertinoIcons.add),
            ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required WorkoutPlanTemplateController controller,
    required List<WorkoutPlanTemplate> trainerTemplates,
    required String currentUserId,
    required String targetUserId,
    required bool isAssignmentContext,
  }) {
    return Obx(() {
      final clientTemplates = controller.templates.toList(growable: false);
      final sections = <_PlanSection>[
        if (isAssignmentContext)
          _PlanSection(
            title: clientName?.isNotEmpty == true
                ? '${clientName} Planları'
                : 'Danışanın Planları',
            ownerUserId: targetUserId,
            templates: clientTemplates,
          ),
        _PlanSection(
          title: isAssignmentContext ? 'Antrenör Planları' : '',
          ownerUserId: isAssignmentContext ? currentUserId : targetUserId,
          templates: isAssignmentContext ? trainerTemplates : clientTemplates,
        ),
      ];

      final hasPlans = sections.any((section) => section.templates.isNotEmpty);
      if (!hasPlans) {
        return _buildEmptyState(isAssignmentContext: isAssignmentContext);
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in sections)
            ..._buildSection(
              context: context,
              controller: controller,
              section: section,
              currentUserId: currentUserId,
              isAssignmentContext: isAssignmentContext,
            ),
        ],
      );
    });
  }

  Widget _buildEmptyState({required bool isAssignmentContext}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.square_list, size: 48, color: Colors.grey),
          AppSpacing.vSm,
          Text(
            isAssignmentContext
                ? 'Henüz kayıtlı plan bulunamadı.'
                : 'Henüz kayıtlı planınız yok.',
          ),
          if (!isAssignmentContext) ...[
            AppSpacing.vSm,
            FilledButton.icon(
              onPressed: () => Get.to(() => const EditSavedPlanPage()),
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Yeni Plan Oluştur'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSection({
    required BuildContext context,
    required WorkoutPlanTemplateController controller,
    required _PlanSection section,
    required String currentUserId,
    required bool isAssignmentContext,
  }) {
    if (section.templates.isEmpty) return const [];

    final widgets = <Widget>[];
    if (section.title.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
    }

    for (final plan in section.templates) {
      final assignedDays = _assignedDaysForPlan(controller.dayAssignments, plan.id);
      final assignedLabels = assignedDays
          .map((day) => ExerciseRepository.weekDayLabels[day] ?? day.toUpperCase())
          .join(', ');
      final canManageTemplate = plan.ownerUserId.isNotEmpty
          ? plan.ownerUserId == currentUserId
          : section.ownerUserId == currentUserId;
      final onTap = isAssignmentContext
          ? () => _openAssignDaysSheet(
                context: context,
                controller: controller,
                plan: plan,
                assignedDays: assignedDays,
              )
          : (canManageTemplate
              ? () => Get.to(() => EditSavedPlanPage(template: plan))
              : null);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FittaCard(
            child: ListTile(
              title: Text(plan.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${plan.exercises.length} egzersiz'),
                  Text(
                    assignedLabels.isEmpty ? 'Günler: -' : 'Günler: $assignedLabels',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              onTap: onTap,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.calendar),
                    tooltip: 'Gün ata',
                    onPressed: () => _openAssignDaysSheet(
                      context: context,
                      controller: controller,
                      plan: plan,
                      assignedDays: assignedDays,
                    ),
                  ),
                  if (!isAssignmentContext && canManageTemplate)
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash),
                      onPressed: () => _confirmDeletePlan(
                        context: context,
                        controller: controller,
                        plan: plan,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _confirmDeletePlan({
    required BuildContext context,
    required WorkoutPlanTemplateController controller,
    required WorkoutPlanTemplate plan,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan silinsin mi?'),
        content: Text('"${plan.name}" planını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await controller.deleteTemplate(plan.id);
    }
  }

  List<String> _assignedDaysForPlan(
    Map<String, String?> assignments,
    String planId,
  ) {
    return ExerciseRepository.weekDayKeys
        .where((day) => assignments[day] == planId)
        .toList(growable: false);
  }

  Future<void> _openAssignDaysSheet({
    required BuildContext context,
    required WorkoutPlanTemplateController controller,
    required WorkoutPlanTemplate plan,
    required List<String> assignedDays,
  }) async {
    final selected = {...assignedDays};
    final result = await showModalBottomSheet<List<String>>(
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
                  Text('Hangi günlere atalım?', style: Theme.of(context).textTheme.titleMedium),
                  AppSpacing.vSm,
                  Wrap(
                    spacing: 8,
                    children: ExerciseRepository.weekDayKeys.map((day) {
                      final label = ExerciseRepository.weekDayLabels[day] ?? day.toUpperCase();
                      final isSelected = selected.contains(day);
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selected.add(day);
                            } else {
                              selected.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.vMd,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(selected.toList()),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    final added = result.where((day) => !assignedDays.contains(day)).toList();
    final removed = assignedDays.where((day) => !result.contains(day)).toList();
    if (added.isEmpty && removed.isEmpty) return;

    try {
      if (added.isNotEmpty) {
        await controller.exerciseRepository.savePlanForDays(
          userId: controller.userId,
          dayKeys: added,
          exercises: plan.exercises,
          planName: plan.name,
          templateId: plan.id,
        );
      }
      if (removed.isNotEmpty) {
        await controller.exerciseRepository.clearPlanForDays(
          userId: controller.userId,
          dayKeys: removed,
        );
      }
      for (final day in added) {
        controller.dayAssignments[day] = plan.id;
      }
      for (final day in removed) {
        if (controller.dayAssignments[day] == plan.id) {
          controller.dayAssignments[day] = null;
        }
      }
      controller.dayAssignments.refresh();
      controller.templates.refresh();
      Get.snackbar('Başarılı', 'Gün atamaları güncellendi', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', 'Gün ataması güncellenemedi: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  WorkoutPlanTemplateController _provideController(String userId) {
    if (Get.isRegistered<WorkoutPlanTemplateController>()) {
      final existing = Get.find<WorkoutPlanTemplateController>();
      if (existing.userId == userId) return existing;
      Get.delete<WorkoutPlanTemplateController>();
    }
    return Get.put(
      WorkoutPlanTemplateController(
        repository: WorkoutPlanTemplateRepository(),
        exerciseRepository: ExerciseRepository(),
        userId: userId,
      ),
    );
  }
}

class _PlanSection {
  const _PlanSection({
    required this.title,
    required this.ownerUserId,
    required this.templates,
  });

  final String title;
  final String ownerUserId;
  final List<WorkoutPlanTemplate> templates;
}
