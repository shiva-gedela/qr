import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../models/event_model.dart';

class EventPortfolioScreen extends StatefulWidget {
  final EventModel event;

  const EventPortfolioScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventPortfolioScreen> createState() => _EventPortfolioScreenState();
}

class _EventPortfolioScreenState extends State<EventPortfolioScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _portfolioPhotos = [];
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'code': 'all', 'label': '🌟 All Moments'},
    {'code': 'ceremony', 'label': '💍 Ceremony'},
    {'code': 'reception', 'label': '🎉 Reception'},
    {'code': 'decor', 'label': '✨ Decor'},
    {'code': 'food', 'label': '🍰 Food & Catering'},
    {'code': 'candid', 'label': '📸 Candid'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'portfolio_${widget.event.id}';
    final saved = prefs.getStringList(key);

    List<Map<String, dynamic>> loaded = [];
    if (saved != null && saved.isNotEmpty) {
      for (final item in saved) {
        try {
          loaded.add(Map<String, dynamic>.from(jsonDecode(item)));
        } catch (_) {}
      }
    } else {
      // Load event photos from event model or default portfolio
      if (widget.event.photos.isNotEmpty) {
        loaded = List<Map<String, dynamic>>.from(widget.event.photos);
      } else {
        // Sample curated portfolio photos for showcase
        loaded = [
          {
            'id': 1,
            'url': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80',
            'caption': 'Ceremony Stage & Mandap Floral Setup',
            'category': 'decor',
            'date': widget.event.eventDate,
          },
          {
            'id': 2,
            'url': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&q=80',
            'caption': 'Ring Exchange & Vows',
            'category': 'ceremony',
            'date': widget.event.eventDate,
          },
          {
            'id': 3,
            'url': 'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800&q=80',
            'caption': 'Grand Entrance of Bride & Groom',
            'category': 'reception',
            'date': widget.event.eventDate,
          },
          {
            'id': 4,
            'url': 'https://images.unsplash.com/photo-1555244162-803834f70033?w=800&q=80',
            'caption': 'Royal Buffet & Gourmet Delicacies',
            'category': 'food',
            'date': widget.event.eventDate,
          },
          {
            'id': 5,
            'url': 'https://images.unsplash.com/photo-1532712938310-34cb3982ef74?w=800&q=80',
            'caption': 'Joyful Candid Laughs with Guests',
            'category': 'candid',
            'date': widget.event.eventDate,
          },
        ];
      }
    }

    if (mounted) {
      setState(() => _portfolioPhotos = loaded);
    }
  }

  Future<void> _savePortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'portfolio_${widget.event.id}';
    final toSave = _portfolioPhotos.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(key, toSave);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final captionController = TextEditingController();
      String selectedCat = 'ceremony';

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Add Moment to Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: captionController,
                        decoration: const InputDecoration(
                          labelText: 'Caption / Moment description',
                          hintText: 'e.g. Sangeet dance performance',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedCat,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: _categories.where((c) => c['code'] != 'all').map((c) {
                          return DropdownMenuItem(value: c['code'], child: Text(c['label']!));
                        }).toList(),
                        onChanged: (v) => setDialogState(() => selectedCat = v ?? 'ceremony'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                    onPressed: () {
                      final newPhoto = {
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'url': picked.path,
                        'caption': captionController.text.trim().isEmpty ? 'Event Moment' : captionController.text.trim(),
                        'category': selectedCat,
                        'date': DateTime.now().toString().split(' ')[0],
                      };
                      setState(() {
                        _portfolioPhotos.insert(0, newPhoto);
                      });
                      _savePortfolio();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo added to event portfolio!'), backgroundColor: AppConstants.successColor),
                      );
                    },
                    child: const Text('Add to Portfolio', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _editPhotoCaption(int index) {
    final photo = _portfolioPhotos[index];
    final controller = TextEditingController(text: photo['caption']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Moment Caption', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Caption'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              onPressed: () {
                setState(() {
                  _portfolioPhotos[index]['caption'] = controller.text.trim();
                });
                _savePortfolio();
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Photo?'),
          content: const Text('Are you sure you want to remove this photo from the event portfolio?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                setState(() {
                  _portfolioPhotos.removeAt(index);
                });
                _savePortfolio();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo deleted.')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: AppConstants.dangerColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openLightbox(int index) {
    final photo = _portfolioPhotos[index];
    final url = photo['url'] ?? photo['file_url'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.92),
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: url.startsWith('http')
                            ? Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.white54))
                            : const Icon(Icons.image, size: 100, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          photo['caption'] ?? 'Event Photo',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${(photo['category'] ?? 'General').toString().toUpperCase()}',
                        style: const TextStyle(color: AppConstants.accentColor, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'all'
        ? _portfolioPhotos
        : _portfolioPhotos.where((p) => (p['category'] ?? 'other') == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event Portfolio & Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.event.title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            tooltip: 'Add Photo',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt, color: AppConstants.primaryColor),
                          title: const Text('Take Photo with Camera'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library, color: AppConstants.primaryColor),
                          title: const Text('Choose from Photo Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat['code'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  selectedColor: AppConstants.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat['code']!),
                );
              },
            ),
          ),

          // Portfolio Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 64, color: AppConstants.textMuted),
                          const SizedBox(height: 12),
                          const Text('No photos in this category.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Tap the camera icon above to upload moments.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      final url = item['url'] ?? item['file_url'] ?? '';

                      return GestureDetector(
                        onTap: () => _openLightbox(idx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Photo preview
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    url.startsWith('http')
                                        ? Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: AppConstants.purpleSurface,
                                            child: const Icon(Icons.photo, size: 48, color: AppConstants.primaryColor),
                                          ),
                                    // Category badge
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          (item['category'] ?? 'Event').toString().toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Caption & Menu
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['caption'] ?? 'Moment',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: AppConstants.textMuted),
                                      padding: EdgeInsets.zero,
                                      onSelected: (val) {
                                        if (val == 'edit') _editPhotoCaption(idx);
                                        if (val == 'delete') _deletePhoto(idx);
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit Caption')),
                                        const PopupMenuItem(value: 'delete', child: Text('Delete Photo', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Add Moment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _pickImage(ImageSource.gallery),
      ),
    );
  }
}
