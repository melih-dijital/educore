/// Floor Management Screen
/// Adım 2: Kat tanımlama ekranı

import 'package:flutter/material.dart';
import '../../models/duty_planner_models.dart';
import '../../theme/duty_planner_theme.dart';

/// Kat yönetimi ekranı
class FloorManagementScreen extends StatefulWidget {
  final List<Floor> floors;
  final Function(List<Floor>) onFloorsUpdated;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FloorManagementScreen({
    super.key,
    required this.floors,
    required this.onFloorsUpdated,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<FloorManagementScreen> createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> {
  final TextEditingController _floorNameController = TextEditingController();

  @override
  void dispose() {
    _floorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = DutyPlannerTheme.screenPadding(context);
    final maxWidth = DutyPlannerTheme.maxContentWidth(context);

    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              _buildHeader(),
              const SizedBox(height: 24),

              // Kat ekleme formu
              _buildAddFloorCard(),
              const SizedBox(height: 16),

              // Varsayılan katlar butonu
              if (widget.floors.isEmpty)
                OutlinedButton.icon(
                  onPressed: _addDefaultFloors,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Örnek Katları Ekle (1-4. Kat)'),
                ),
              const SizedBox(height: 16),

              // Kat listesi
              _buildFloorList(),
              const SizedBox(height: 24),

              // Navigasyon butonları
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text('Geri'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.floors.isNotEmpty
                          ? widget.onNext
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Devam Et'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DutyPlannerColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.layers,
                color: DutyPlannerColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adım 2: Kat Tanımlama',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nöbet tutulacak katları tanımlayın',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFloorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _floorNameController,
                decoration: const InputDecoration(
                  labelText: 'Kat Adı',
                  hintText: 'örn: 1. Kat, Zemin Kat',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
                onSubmitted: (_) => _addFloor(),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _addFloor,
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorList() {
    if (widget.floors.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.layers_clear,
                size: 48,
                color: DutyPlannerColors.textHint,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz kat eklenmedi',
                style: TextStyle(color: DutyPlannerColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: DutyPlannerColors.tableHeader,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.layers,
                  color: DutyPlannerColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tanımlı Katlar (${widget.floors.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DutyPlannerColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Sürükle-bırak listesi
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.floors.length,
            onReorder: _reorderFloors,
            itemBuilder: (context, index) {
              final floor = widget.floors[index];
              return ListTile(
                key: ValueKey(floor.id),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DutyPlannerColors.primaryLight.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${floor.order}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: DutyPlannerColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(floor.name),
                subtitle: Text('Sıra: ${floor.order}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editFloor(floor),
                      icon: const Icon(Icons.edit_outlined),
                      color: DutyPlannerColors.primary,
                    ),
                    IconButton(
                      onPressed: () => _deleteFloor(floor),
                      icon: const Icon(Icons.delete_outline),
                      color: DutyPlannerColors.error,
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: DutyPlannerColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addFloor() {
    final name = _floorNameController.text.trim();
    if (name.isEmpty) return;

    final newFloor = Floor.create(name, widget.floors.length + 1);
    widget.onFloorsUpdated([...widget.floors, newFloor]);
    _floorNameController.clear();
  }

  void _addDefaultFloors() {
    final defaultFloors = [
      Floor.create('Zemin Kat', 1),
      Floor.create('1. Kat', 2),
      Floor.create('2. Kat', 3),
      Floor.create('3. Kat', 4),
    ];
    widget.onFloorsUpdated(defaultFloors);
  }

  void _reorderFloors(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final floors = List<Floor>.from(widget.floors);
    final floor = floors.removeAt(oldIndex);
    floors.insert(newIndex, floor);

    // Sıra numaralarını güncelle
    final updatedFloors = floors.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key + 1);
    }).toList();

    widget.onFloorsUpdated(updatedFloors);
  }

  void _editFloor(Floor floor) {
    final controller = TextEditingController(text: floor.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katı Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Kat Adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final updatedFloors = widget.floors.map((f) {
                  if (f.id == floor.id) {
                    return f.copyWith(name: controller.text.trim());
                  }
                  return f;
                }).toList();
                widget.onFloorsUpdated(updatedFloors);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deleteFloor(Floor floor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katı Sil'),
        content: Text(
          '"${floor.name}" katını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedFloors = widget.floors
                  .where((f) => f.id != floor.id)
                  .toList();
              // Sıra numaralarını güncelle
              final reorderedFloors = updatedFloors.asMap().entries.map((
                entry,
              ) {
                return entry.value.copyWith(order: entry.key + 1);
              }).toList();
              widget.onFloorsUpdated(reorderedFloors);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DutyPlannerColors.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
