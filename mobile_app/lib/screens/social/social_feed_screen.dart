import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/social_post_model.dart';
import '../../services/api_service.dart';
import 'create_post_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({Key? key}) : super(key: key);

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  List<SocialPostModel> _posts = [];
  bool _isLoading = true;

  final List<Map<String, String>> _storyHighlights = [
    {'name': '💍 Weddings', 'img': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=200&q=80'},
    {'name': '🎂 Birthdays', 'img': 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=200&q=80'},
    {'name': '❤️ Anniversaries', 'img': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=200&q=80'},
    {'name': '🏠 Housewarming', 'img': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=200&q=80'},
    {'name': '🎓 Graduations', 'img': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=200&q=80'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getSocialPosts();
    if (!mounted) return;
    setState(() {
      _posts = list;
      _isLoading = false;
    });
  }

  void _toggleLike(SocialPostModel post) async {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
    });
    await ApiService.toggleLikePost(post.id);
  }

  void _openCommentsModal(SocialPostModel post) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Comments (${post.comments.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: post.comments.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('No comments yet. Be the first to congratulate!', style: TextStyle(color: AppConstants.textMuted)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: post.comments.length,
                            itemBuilder: (context, i) {
                              final c = post.comments[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppConstants.primaryLight.withOpacity(0.2),
                                  child: Text(c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'U'),
                                ),
                                title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(c.text, style: const TextStyle(fontSize: 12, color: AppConstants.textDark)),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          decoration: InputDecoration(
                            hintText: 'Add a congratulatory note...',
                            hintStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppConstants.primaryColor),
                        onPressed: () async {
                          final text = commentCtrl.text.trim();
                          if (text.isEmpty) return;
                          commentCtrl.clear();
                          await ApiService.addPostComment(post.id, text);
                          setModalState(() {
                            post.comments.add(SocialCommentModel(
                              id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                              userName: 'You',
                              text: text,
                              createdAt: DateTime.now(),
                            ));
                          });
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sharePost(SocialPostModel post) async {
    final text = "${post.userName}: ${post.caption}\n\nShared via QRouteX Celebration Moments: https://qroutex.com";
    final uri = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.camera_alt, color: AppConstants.primaryColor, size: 24),
            SizedBox(width: 8),
            Text('Celebration Moments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.textDark)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: AppConstants.primaryColor, size: 26),
            tooltip: 'Share Moment',
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              if (created != null) _loadPosts();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Stories Highlights Row ──
              Container(
                height: 104,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _storyHighlights.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, idx) {
                    final s = _storyHighlights[idx];
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppConstants.primaryGradient,
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(s['img']!),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(s['name']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // ── Feed Posts ──
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No celebration moments yet. Be the first to post!')),
                )
              else
                ..._posts.map((post) => _buildPostCard(post)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(SocialPostModel post) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userAvatar.isNotEmpty
                      ? NetworkImage(post.userAvatar)
                      : null,
                  backgroundColor: AppConstants.purpleSurface,
                  child: post.userAvatar.isEmpty
                      ? Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U')
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (post.eventTitle != null)
                        Text(
                          'Celebrated at ${post.eventTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (post.eventTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: Text(post.eventTag!, style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
          ),

          // Post Photo
          if (post.imageUrl != null)
            GestureDetector(
              onDoubleTap: () => _toggleLike(post),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                ),
              ),
            ),

          // Action Icons Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.redAccent : AppConstants.textDark,
                    size: 26,
                  ),
                  onPressed: () => _toggleLike(post),
                ),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, size: 24),
                  onPressed: () => _openCommentsModal(post),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 24),
                  onPressed: () => _sharePost(post),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 24),
              ],
            ),
          ),

          // Likes Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${post.likesCount} likes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppConstants.textDark, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: '${post.userName} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),

          // View Comments Link
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: GestureDetector(
                onTap: () => _openCommentsModal(post),
                child: Text(
                  'View all ${post.comments.length} comments',
                  style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
