import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../../services/api_service.dart';
import 'business_detail_screen.dart';
import 'vendor_add_screen.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({Key? key}) : super(key: key);

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  List<BusinessModel> _allBusinesses = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isGridView = true; // Default to OLX 2-column marketplace grid

  final List<Map<String, String>> _filterCategories = [
    {'code': 'all', 'name': 'All Vendors', 'emoji': '🌟'},
    {'code': 'catering', 'name': 'Catering', 'emoji': '🍽️'},
    {'code': 'photography', 'name': 'Photography', 'emoji': '📸'},
    {'code': 'decoration', 'name': 'Decoration', 'emoji': '🎨'},
    {'code': 'dj', 'name': 'DJ & Sound', 'emoji': '🎵'},
    {'code': 'venue', 'name': 'Venues', 'emoji': '🏰'},
    {'code': 'makeup', 'name': 'Makeup', 'emoji': '💄'},
    {'code': 'planner', 'name': 'Planners', 'emoji': '📋'},
    {'code': 'bakery', 'name': 'Cakes', 'emoji': '🎂'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getBusinesses();
      if (!mounted) return;
      setState(() {
        _allBusinesses = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<BusinessModel> _getFilteredBusinesses() {
    return _allBusinesses.where((b) {
      final matchesCategory = _selectedCategory == 'all' || b.category.toLowerCase() == _selectedCategory.toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          b.name.toLowerCase().contains(query) ||
          b.tagline.toLowerCase().contains(query) ||
          b.city.toLowerCase().contains(query) ||
          b.categoryTitle.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredBusinesses();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Event Vendors & Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to OLX Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadBusinesses,
          ),
          IconButton(
            icon: const Icon(Icons.add_business, color: AppConstants.accentColor, size: 26),
            tooltip: 'Add Vendor',
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorAddScreen()),
              );
              if (created != null) _loadBusinesses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Header Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search vendors, catering, photo, decor...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppConstants.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppConstants.primaryColor, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    filled: true,
                    fillColor: AppConstants.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Chips Scrollable Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterCategories.map((cat) {
                      final isSelected = _selectedCategory == cat['code'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Text(cat['emoji']!, style: const TextStyle(fontSize: 12)),
                          label: Text(cat['name']!),
                          selected: isSelected,
                          selectedColor: AppConstants.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppConstants.textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat['code']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Vendor Cards List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadBusinesses,
                    child: filtered.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(32),
                            children: [
                              const SizedBox(height: 40),
                              const Icon(Icons.storefront_outlined, size: 72, color: AppConstants.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'No Vendors Found in this Category' : 'No Results for "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Be the first to list your catering, photography, decor, or venue services on QRouteX!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: const Icon(Icons.add_business),
                                  label: const Text('Add Your Vendor Profile Now'),
                                  onPressed: () async {
                                    final created = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const VendorAddScreen()),
                                    );
                                    if (created != null) _loadBusinesses();
                                  },
                                ),
                              ),
                            ],
                          )
                        : _isGridView
                            ? _buildOlxGridView(filtered, screenWidth)
                            : _buildListView(filtered),
                  ),
          ),
        ],
      ),
    );
  }

  // ══ OLX 2-COLUMN GRID VIEW (Marketplace Experience) ════════════════════════
  Widget _buildOlxGridView(List<BusinessModel> list, double screenWidth) {
    final crossAxisCount = screenWidth > 550 ? 3 : 2;
    // Responsive aspect ratio to prevent overflow on 320px - 480px devices
    final dynamicAspectRatio = screenWidth < 340
        ? 0.62
        : screenWidth < 380
            ? 0.65
            : 0.68;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: dynamicAspectRatio,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        String startingPrice = 'Contact for Quote';
        if (b.services.isNotEmpty) {
          final p = b.services.first.priceDisplay;
          if (p != null && p.isNotEmpty) startingPrice = 'From $p';
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Thumbnail
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E1065), Color(0xFF4A148C), Color(0xFF5F259F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          image: b.coverImageUrl != null
                              ? DecorationImage(image: NetworkImage(b.coverImageUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: b.coverImageUrl == null
                            ? Center(
                                child: Text(b.categoryEmoji, style: const TextStyle(fontSize: 36)),
                              )
                            : null,
                      ),
                      // Verified badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, size: 10, color: Colors.black),
                              SizedBox(width: 2),
                              Text('PRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Specs & Details (OLX Card style)
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price Highlight
                            Text(
                              startingPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Vendor Name
                            Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Category pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.categoryTitle,
                                style: const TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Location & Contact Quick Icons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 11, color: AppConstants.primaryColor),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    b.city.isNotEmpty ? b.city : 'Bengaluru',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Quick Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (b.phone.isNotEmpty)
                                  InkWell(
                                    onTap: () => _openUrl('tel:${b.phone}'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.call, size: 10, color: Color(0xFF0284C7)),
                                          SizedBox(width: 2),
                                          Text('Call', style: TextStyle(fontSize: 9, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (b.whatsapp.isNotEmpty)
                                  InkWell(
                                    onTap: () => _openUrl('https://wa.me/${b.whatsapp.replaceAll(RegExp(r'\D'), '')}'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.chat, size: 10, color: Color(0xFF16A34A)),
                                          SizedBox(width: 2),
                                          Text('Chat', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══ LIST VIEW MODE ════════════════════════════════════════════════════════
  Widget _buildListView(List<BusinessModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b)),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppConstants.purpleSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(b.categoryEmoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    b.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                                  ),
                                ),
                                if (b.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Color(0xFF0284C7), size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.tagline.isNotEmpty ? b.tagline : b.categoryTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.categoryTitle,
                          style: const TextStyle(color: AppConstants.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📍 ${b.city.isNotEmpty ? b.city : "Bengaluru"}',
                        style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b)),
                          );
                        },
                        child: const Text('Option Details', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
