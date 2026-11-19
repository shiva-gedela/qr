import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants.dart';
import '../../models/social_post_model.dart';
import '../../services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _eventTagController = TextEditingController();
  final _eventTitleController = TextEditingController();
  String? _pickedImagePath;
  String _presetImage = 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80';
  bool _isPosting = false;

  final List<String> _samplePresets = [
    'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80',
    'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&q=80',
    'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
    'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80',
  ];

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedImagePath = picked.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  void _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPosting = true);

    final newPost = SocialPostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'You',
      userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80',
      eventTitle: _eventTitleController.text.trim().isNotEmpty ? _eventTitleController.text.trim() : 'Celebration Moments',
      eventTag: _eventTagController.text.trim().isNotEmpty ? _eventTagController.text.trim() : '#QRouteXMoments',
      caption: _captionController.text.trim(),
      imageUrl: _pickedImagePath ?? _presetImage,
      likesCount: 1,
      isLiked: true,
      comments: [],
      createdAt: DateTime.now(),
    );

    await ApiService.createSocialPost(newPost);

    if (!mounted) return;
    setState(() => _isPosting = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Share Celebration Moment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview & Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(_presetImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.35),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, color: Colors.white, size: 36),
                            SizedBox(height: 6),
                            Text('Tap to Pick Photo from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sample Presets row
              const Text('Or select photo preset:', style: TextStyle(fontSize: 12, color: AppConstants.textMuted)),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _samplePresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final img = _samplePresets[idx];
                    final isSelected = _presetImage == img && _pickedImagePath == null;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _presetImage = img;
                        _pickedImagePath = null;
                      }),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.transparent, width: 2),
                          image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Event Title
              TextFormField(
                controller: _eventTitleController,
                decoration: const InputDecoration(
                  labelText: 'Event / Celebration Name',
                  hintText: 'e.g. Maya & Arjun Wedding Reception',
                  prefixIcon: Icon(Icons.celebration),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Hashtag
              TextFormField(
                controller: _eventTagController,
                decoration: const InputDecoration(
                  labelText: 'Hashtag',
                  hintText: '#MayaWedsArjun',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Caption
              TextFormField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption & Celebration Story',
                  hintText: 'Share your favorite memory, congratulatory note, or heartfelt wishes...',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter caption' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isPosting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(
                  _isPosting ? 'Sharing Moment...' : 'Share with Celebration Feed',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _isPosting ? null : _submitPost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
