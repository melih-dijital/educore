/// Room Config Screen
/// Sınav salonu yapılandırma ekranı - Her salon için ayrı sıra düzeni

import 'package:flutter/material.dart';
import '../../models/butterfly_exam_models.dart';
import '../../models/school_models.dart';
import '../../services/room_db_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Salon yapılandırma ekranı
class RoomConfigScreen extends StatefulWidget {
  final List<ExamRoom> rooms;
  final String examName;
  final Function(List<ExamRoom>) onRoomsChanged;
  final Function(String) onExamNameChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RoomConfigScreen({
    super.key,
    required this.rooms,
    required this.examName,
    required this.onRoomsChanged,
    required this.onExamNameChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<RoomConfigScreen> createState() => _RoomConfigScreenState();
}

class _RoomConfigScreenState extends State<RoomConfigScreen> {
  final _examNameController = TextEditingController();
  final _roomDbService = RoomDbService();

  @override
  void initState() {
    super.initState();
    _examNameController.text = widget.examName;
  }

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  int get _totalCapacity {
    return widget.rooms.fold(0, (sum, room) => sum + room.capacity);
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
              _buildHeader(),
              const SizedBox(height: 24),

              // Sınav adı
              _buildExamNameField(),
              const SizedBox(height: 16),

              // Yeni salon ekle butonu
              _buildAddRoomButton(),
              const SizedBox(height: 16),

              // Mevcut salonlar (her biri düzenlenebilir)
              ...widget.rooms.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRoomCard(entry.key, entry.value),
                );
              }),

              if (widget.rooms.isEmpty) _buildEmptyState(),

              const SizedBox(height: 24),

              // Navigasyon
              _buildNavigationButtons(),
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
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.meeting_room,
                color: Colors.indigo,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adım 3: Salonları Tanımlayın',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.rooms.length} salon, toplam $_totalCapacity koltuk',
                    style: const TextStyle(
                      color: DutyPlannerColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamNameField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sınav Adı',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _examNameController,
              decoration: const InputDecoration(
                hintText: 'Örn: 1. Dönem 2. Yazılı',
                border: OutlineInputBorder(),
              ),
              onChanged: widget.onExamNameChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRoomButton() {
    return Row(
      children: [
        // Yeni Salon Ekle
        Expanded(
          child: Card(
            color: Colors.green.withValues(alpha: 0.1),
            child: InkWell(
              onTap: _addNewRoom,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Colors.green, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Yeni Salon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Kayıtlı Salonlardan Seç
        Expanded(
          child: Card(
            color: Colors.indigo.withValues(alpha: 0.1),
            child: InkWell(
              onTap: _showImportRoomsDialog,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, color: Colors.indigo, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Kayıtlı Salonlar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(int index, ExamRoom room) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: Numara, Salon adı, düzenle (kalem) ve sil butonları
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.indigo, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    room.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                  onPressed: () => _showEditRoomNameDialog(index, room.name),
                  tooltip: 'Adı Düzenle',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: DutyPlannerColors.error,
                  ),
                  onPressed: () => _removeRoom(index),
                  tooltip: 'Salonu Sil',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Açılır/kapanır bölüm: Boyut ayarları ve önizleme
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${room.rowCount} × ${room.columnCount} = ${room.capacity} koltuk',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing: const Icon(
                  Icons.tune,
                  size: 20,
                  color: Colors.indigo,
                ),
                children: [
                  // Sıra ve sütun ayarları
                  Row(
                    children: [
                      Expanded(
                        child: _buildCounterWithSlider(
                          label: 'Sıra (Ön-Arka)',
                          value: room.rowCount,
                          min: 1,
                          max: 15,
                          onChanged: (value) => _updateRoomRows(index, value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCounterWithSlider(
                          label: 'Sütun (Yan Yana)',
                          value: room.columnCount,
                          min: 1,
                          max: 12,
                          onChanged: (value) =>
                              _updateRoomColumns(index, value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Görsel önizleme
                  _buildRoomPreview(room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomNameDialog(int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salon Adını Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Salon Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateRoomName(index, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterWithSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DutyPlannerColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _buildRoomPreview(ExamRoom room) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DutyPlannerColors.tableHeader,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DutyPlannerColors.tableBorder),
      ),
      child: Column(
        children: [
          // Tahta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'TAHTA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: List.generate(room.rowCount.clamp(1, 10), (row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(room.columnCount.clamp(1, 10), (col) {
                    return Container(
                      width: 22,
                      height: 18,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.indigo.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Kapasite
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${room.rowCount} × ${room.columnCount} = ${room.capacity} koltuk',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.meeting_room, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Henüz salon eklenmedi',
                style: TextStyle(color: DutyPlannerColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yukarıdaki butona tıklayarak salon ekleyin',
                style: TextStyle(
                  fontSize: 12,
                  color: DutyPlannerColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
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
            onPressed: widget.rooms.isNotEmpty ? widget.onNext : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Dağıtıma Geç'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addNewRoom() {
    final newRoom = ExamRoom(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Salon ${widget.rooms.length + 1}',
      rowCount: 5,
      columnCount: 6,
    );
    widget.onRoomsChanged([...widget.rooms, newRoom]);
  }

  void _updateRoomName(int index, String name) {
    final updatedRooms = List<ExamRoom>.from(widget.rooms);
    final room = updatedRooms[index];
    updatedRooms[index] = ExamRoom(
      id: room.id,
      name: name,
      rowCount: room.rowCount,
      columnCount: room.columnCount,
    );
    widget.onRoomsChanged(updatedRooms);
  }

  void _updateRoomRows(int index, int rows) {
    final updatedRooms = List<ExamRoom>.from(widget.rooms);
    final room = updatedRooms[index];
    updatedRooms[index] = ExamRoom(
      id: room.id,
      name: room.name,
      rowCount: rows,
      columnCount: room.columnCount,
    );
    widget.onRoomsChanged(updatedRooms);
  }

  void _updateRoomColumns(int index, int columns) {
    final updatedRooms = List<ExamRoom>.from(widget.rooms);
    final room = updatedRooms[index];
    updatedRooms[index] = ExamRoom(
      id: room.id,
      name: room.name,
      rowCount: room.rowCount,
      columnCount: columns,
    );
    widget.onRoomsChanged(updatedRooms);
  }

  void _removeRoom(int index) {
    final updatedRooms = List<ExamRoom>.from(widget.rooms);
    updatedRooms.removeAt(index);
    widget.onRoomsChanged(updatedRooms);
  }

  /// Kayıtlı salonlardan seçim dialogu
  Future<void> _showImportRoomsDialog() async {
    // Mevcut salonları yükle
    final savedRooms = await _roomDbService.getRooms();

    if (!mounted) return;

    if (savedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayıtlı salon bulunamadı. Önce Okul Yönetimi > Salonlar bölümünden salon ekleyin.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mevcut eklenen salonların ID'lerini al (zaten eklenmiş olanları işaretlememek için)
    final existingIds = widget.rooms.map((r) => r.id).toSet();

    // Seçili salonları takip et
    final selectedRooms = <SchoolRoom>{};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.meeting_room, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text('Kayıtlı Salonlar'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedRooms.length} seçili',
                    style: const TextStyle(fontSize: 12, color: Colors.indigo),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: savedRooms.length,
                itemBuilder: (context, index) {
                  final room = savedRooms[index];
                  final isAlreadyAdded = existingIds.contains(room.id);
                  final isSelected = selectedRooms.contains(room);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isAlreadyAdded
                        ? Colors.grey.shade100
                        : isSelected
                        ? Colors.indigo.withValues(alpha: 0.1)
                        : null,
                    child: CheckboxListTile(
                      value: isSelected || isAlreadyAdded,
                      onChanged: isAlreadyAdded
                          ? null
                          : (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedRooms.add(room);
                                } else {
                                  selectedRooms.remove(room);
                                }
                              });
                            },
                      title: Text(
                        room.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isAlreadyAdded ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        '${room.rowCount} × ${room.columnCount} = ${room.capacity} koltuk'
                        '${isAlreadyAdded ? ' (zaten ekli)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAlreadyAdded ? Colors.grey : Colors.indigo,
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAlreadyAdded
                              ? Colors.grey.shade200
                              : Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event_seat,
                          color: isAlreadyAdded ? Colors.grey : Colors.indigo,
                        ),
                      ),
                      activeColor: Colors.indigo,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: selectedRooms.isEmpty
                    ? null
                    : () {
                        // Seçili salonları ExamRoom'a dönüştür ve ekle
                        final newRooms = selectedRooms.map((schoolRoom) {
                          return ExamRoom(
                            id: schoolRoom.id,
                            name: schoolRoom.name,
                            rowCount: schoolRoom.rowCount,
                            columnCount: schoolRoom.columnCount,
                          );
                        }).toList();

                        widget.onRoomsChanged([...widget.rooms, ...newRooms]);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newRooms.length} salon eklendi'),
                            backgroundColor: DutyPlannerColors.success,
                          ),
                        );
                      },
                icon: const Icon(Icons.add),
                label: Text('${selectedRooms.length} Salon Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }
}
