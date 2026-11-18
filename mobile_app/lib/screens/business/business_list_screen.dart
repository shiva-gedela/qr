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

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Event Vendors & Services', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                const SizedBox(height: 10),

                // Category Chips Scrollable Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterCategories.map((cat) {
                      final isSelected = _selectedCategory == cat['code'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(cat['emoji']!, style: const TextStyle(fontSize: 13)),
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
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final b = filtered[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
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
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Category Emoji Circle
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: AppConstants.purpleSurface,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(b.categoryEmoji, style: const TextStyle(fontSize: 26)),
                                            ),
                                            const SizedBox(width: 14),
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
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: AppConstants.textDark,
                                                          ),
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
                                                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEDE9FE),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          b.categoryTitle,
                                                          style: const TextStyle(
                                                            color: AppConstants.primaryColor,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '📍 ${b.city.isNotEmpty ? b.city : "Bengaluru"}',
                                                        style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (b.description.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            b.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppConstants.textDark, height: 1.4),
                                          ),
                                        ],

                                        const Divider(height: 20),

                                        // Action Buttons Row
                                        Row(
                                          children: [
                                            // Call Button
                                            if (b.phone.isNotEmpty)
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  side: const BorderSide(color: Color(0xFF0284C7)),
                                                ),
                                                icon: const Icon(Icons.call, size: 14, color: Color(0xFF0284C7)),
                                                label: const Text('Call', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                                onPressed: () => _openUrl('tel:${b.phone}'),
                                              ),
                                            if (b.phone.isNotEmpty) const SizedBox(width: 8),

                                            // WhatsApp Button
                                            if (b.whatsapp.isNotEmpty)
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                icon: const Icon(Icons.chat, size: 14),
                                                label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                onPressed: () {
                                                  final msg = 'Hello ${b.name}, I found your vendor profile on QRouteX and would like to inquire about your services.';
                                                  _openUrl('whatsapp://send?phone=${b.whatsapp.replaceAll(RegExp(r'[^0-9+]'), '')}&text=${Uri.encodeComponent(msg)}');
                                                },
                                              ),

                                            const Spacer(),

                                            // View Profile Button
                                            TextButton.icon(
                                              icon: const Icon(Icons.arrow_forward, size: 14, color: AppConstants.primaryColor),
                                              label: const Text('View Profile', style: TextStyle(fontSize: 11, color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b)),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Add Vendor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VendorAddScreen()),
          );
          if (created != null) _loadBusinesses();
        },
      ),
    );
  }
}