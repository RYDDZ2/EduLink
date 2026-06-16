import 'package:flutter/material.dart';

import '../models/study_hub_model.dart';
import '../models/user_model.dart';
import '../services/study_hub_service.dart';

class CreateStudyHubSheet extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback onCreated;

  const CreateStudyHubSheet({
    super.key,
    required this.currentUser,
    required this.onCreated,
  });

  @override
  State<CreateStudyHubSheet> createState() => _CreateStudyHubSheetState();
}

class _CreateStudyHubSheetState extends State<CreateStudyHubSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _selectedTags = <String>{};

  final _availableTags = [
    'STEM',
    'Sains',
    'Bahasa',
    'Matematika',
    'Coding',
    'Seni',
    'Sejarah',
    'Olahraga',
    'Musik',
    'Bisnis',
    'UTS',
    'UAS',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createHub() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul hub tidak boleh kosong')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong')),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 tag')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await StudyHubService.createStudyHub(
        creatorId: widget.currentUser.id,
        creatorName: widget.currentUser.name,
        creatorInitials: widget.currentUser.initials,
        creatorAvatarColor: '#E1F5EE',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study Hub berhasil dibuat!')),
        );
        widget.onCreated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buat Study Hub Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title Input
            const Text(
              'Judul Hub *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Contoh: AP Calculus BC - Integration',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description Input
            const Text(
              'Deskripsi *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Jelaskan tujuan dan cakupan hub ini',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // Tags Selection
            const Text(
              'Tag (Pilih minimal 1) *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createHub,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Buat Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditStudyHubSheet extends StatefulWidget {
  final StudyHub hub;
  final AppUser currentUser;
  final VoidCallback onUpdated;

  const EditStudyHubSheet({
    super.key,
    required this.hub,
    required this.currentUser,
    required this.onUpdated,
  });

  @override
  State<EditStudyHubSheet> createState() => _EditStudyHubSheetState();
}

class _EditStudyHubSheetState extends State<EditStudyHubSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Set<String> _selectedTags;

  final _availableTags = [
    'STEM',
    'Sains',
    'Bahasa',
    'Matematika',
    'Coding',
    'Seni',
    'Sejarah',
    'Olahraga',
    'Musik',
    'Bisnis',
    'UTS',
    'UAS',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.hub.title);
    _descriptionController =
        TextEditingController(text: widget.hub.description);
    _selectedTags = Set.from(widget.hub.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateHub() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul hub tidak boleh kosong')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong')),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 tag')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await StudyHubService.updateStudyHub(
        widget.hub.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study Hub berhasil diperbarui!')),
        );
        widget.onUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Study Hub',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title Input
            const Text(
              'Judul Hub *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description Input
            const Text(
              'Deskripsi *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // Tags Selection
            const Text(
              'Tag (Pilih minimal 1) *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Update Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateHub,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
