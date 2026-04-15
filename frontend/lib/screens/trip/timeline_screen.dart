import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/trip.dart';
import '../../models/memory.dart';
import '../../providers/memories_provider.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  final Trip trip;
  
  const TimelineScreen({Key? key, required this.trip}) : super(key: key);

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _filter = 'All';
  int? _currentUserId;

  final List<String> _filters = ['All', 'Photos', 'Notes', 'Mine'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = json.decode(userDataStr);
      setState(() => _currentUserId = userData['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider(widget.trip.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Memories', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: memoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (memories) {
                // Apply filters
                var filtered = memories;
                if (_filter == 'Photos') {
                  filtered = memories.where((m) => m.memoryType == 'photo').toList();
                } else if (_filter == 'Notes') {
                  filtered = memories.where((m) => m.memoryType == 'note').toList();
                } else if (_filter == 'Mine' && _currentUserId != null) {
                  filtered = memories.where((m) => m.addedBy == _currentUserId).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text("No memories found."));
                }

                return _buildTimeline(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isSelected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _filter = f);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.background,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeline(List<Memory> memories) {
    // Group memories by date
    final grouped = <String, List<Memory>>{};
    for (var m in memories) {
      final date = m.createdAt;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(m);
    }
    
    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final dayMemories = grouped[dateStr]!;
        
        DateTime parsedDate = DateTime.parse(dateStr);
        String displayDate = DateFormat('EEEE, MMM d, yyyy').format(parsedDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider(color: AppColors.textMuted.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(displayDate, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: AppColors.textMuted.withOpacity(0.3))),
                ],
              ),
            ),
            ...dayMemories.map((m) => _buildMemoryCard(m)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.pinTitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(memory.pinTitle!, style: AppTypography.heading.copyWith(fontSize: 14))),
                ],
              ),
            ),
          if (memory.memoryType == 'photo' && memory.content != null && memory.content!.isNotEmpty)
            ClipRRect(
              borderRadius: memory.pinTitle == null 
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.zero,
              child: CachedNetworkImage(
                imageUrl: memory.content!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          if (memory.memoryType == 'note' && memory.content != null && memory.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.accent, width: 4))
                ),
                child: Text(
                  '"\${memory.content!}"',
                  style: AppTypography.body.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          if (memory.caption != null && memory.caption!.isNotEmpty && memory.memoryType == 'photo')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(memory.caption!, style: AppTypography.body),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(memory.addedByName[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Text(memory.addedByName, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(DateFormat('hh:mm a').format(memory.createdAt), style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
