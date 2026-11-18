import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../../services/api_service.dart';

class VendorAddScreen extends StatefulWidget {
  const VendorAddScreen({Key? key}) : super(key: key);

  @override
  State<VendorAddScreen> createState() => _VendorAddScreenState();
}

class _VendorAddScreenState extends State<VendorAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bengaluru');
  final _stateController = TextEditingController(text: 'Karnataka');
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();

  // 2 Sample Services
  final _service1NameCtrl = TextEditingController();
  final _service1PriceCtrl = TextEditingController();
  final _service2NameCtrl = TextEditingController();
  final _service2PriceCtrl = TextEditingController();

  String _selectedCategory = 'catering';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'code': 'catering', 'name': 'Catering & Food', 'emoji': '🍽️'},
    {'code': 'photography', 'name': 'Photography & Video', 'emoji': '📸'},
    {'code': 'decoration', 'name': 'Decoration & Florals', 'emoji': '🎨'},
    {'code': 'dj', 'name': 'DJ, Sound & Lights', 'emoji': '🎵'},
    {'code': 'venue', 'name': 'Banquets & Venues', 'emoji': '🏰'},
    {'code': 'makeup', 'name': 'Bridal Makeup & Hair', 'emoji': '💄'},
    {'code': 'planner', 'name': 'Event Planners', 'emoji': '📋'},
    {'code': 'bakery', 'name': 'Custom Cakes & Treats', 'emoji': '🎂'},
    {'code': 'other', 'name': 'Other Event Services', 'emoji': '💼'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _service1NameCtrl.dispose();
    _service1PriceCtrl.dispose();
    _service2NameCtrl.dispose();
    _service2PriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final List<BusinessServiceModel> services = [];
      if (_service1NameCtrl.text.trim().isNotEmpty) {
        services.add(
          BusinessServiceModel(
            id: 1,
            name: _service1NameCtrl.text.trim(),
            description: 'Speciality service package',
            priceDisplay: _service1PriceCtrl.text.trim().isNotEmpty ? _service1PriceCtrl.text.trim() : null,
            isAvailable: true,
          ),
        );
      }
      if (_service2NameCtrl.text.trim().isNotEmpty) {
        services.add(
          BusinessServiceModel(
            id: 2,
            name: _service2NameCtrl.text.trim(),
            description: 'Premium service package',
            priceDisplay: _service2PriceCtrl.text.trim().isNotEmpty ? _service2PriceCtrl.text.trim() : null,
            isAvailable: true,
          ),
        );
      }

      final created = await ApiService.createBusiness(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        tagline: _taglineController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Bengaluru',
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : 'Karnataka',
        description: _descriptionController.text.trim(),
        services: services,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vendor "${created.name}" registered successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );

      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding vendor: $e'), backgroundColor: AppConstants.dangerColor),
      );
    }
  }

  String _getCategoryEmoji(String code) {
    final cat = _categories.firstWhere((c) => c['code'] == code, orElse: () => {'emoji': '💼'});
    return cat['emoji']!;
  }

  String _getCategoryName(String code) {
    final cat = _categories.firstWhere((c) => c['code'] == code, orElse: () => {'name': 'Vendor'});
    return cat['name']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Event Vendor Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppConstants.passvantaCardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppConstants.primaryColor.withOpacity(0.25), blurRadius: 12),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppConstants.accentColor, width: 2),
                      ),
                      child: Center(
                        child: Text(_getCategoryEmoji(_selectedCategory), style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Vendor Showcase & Direct Contact',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Showcase your services, catalog, pricing, and QR code to hosts.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Section 1: Business Details ──
              _buildSectionCard(
                title: '1. Vendor & Service Category',
                icon: Icons.storefront,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business / Vendor Name *',
                      hintText: 'e.g. Royal Feast Banquets & Catering',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter vendor business name' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  const Text('Select Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['code'];
                      return ChoiceChip(
                        avatar: Text(cat['emoji']!),
                        label: Text(cat['name']!),
                        selected: isSelected,
                        selectedColor: AppConstants.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppConstants.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = cat['code']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Tagline / Specialty',
                      hintText: 'e.g. 5-Star Multi-Cuisine Banquets & Live Counters',
                      prefixIcon: Icon(Icons.stars),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'About Your Services & Experience',
                      hintText: 'Describe your specialties, hygiene standards, awards, and event portfolio...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Section 2: Contact & Location ──
              _buildSectionCard(
                title: '2. Contact & City Location',
                icon: Icons.contact_phone,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: '+91 98450 12345',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Number',
                            hintText: 'Same as phone',
                            prefixIcon: Icon(Icons.chat),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            hintText: 'e.g. Bengaluru',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            hintText: 'Karnataka',
                            prefixIcon: Icon(Icons.map),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address / Area',
                      hintText: 'e.g. #42, 100 Feet Road, Indiranagar',
                      prefixIcon: Icon(Icons.place),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      hintText: 'info@yourbrand.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Website / Portfolio Link (Optional)',
                      hintText: 'https://instagram.com/yourhandle',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Section 3: Pricing & Featured Packages ──
              _buildSectionCard(
                title: '3. Starting Rate & Key Offerings',
                icon: Icons.currency_rupee,
                children: [
                  TextFormField(
                    controller: _startingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Starting Price / Rate Display',
                      hintText: 'e.g. Starting from ₹550 / plate or ₹30,000 / day',
                      prefixIcon: Icon(Icons.sell),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  const Text('Featured Packages (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _service1NameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Package 1 Name',
                            hintText: 'e.g. Silver Buffet',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _service1PriceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            hintText: '₹550 / plate',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _service2NameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Package 2 Name',
                            hintText: 'e.g. Royal Gold Feast',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _service2PriceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            hintText: '₹850 / plate',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Live Preview Card ──
              const Text('Live Vendor Card Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppConstants.purpleSurface,
                          child: Text(_getCategoryEmoji(_selectedCategory), style: const TextStyle(fontSize: 26)),
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
                                      _nameController.text.trim().isNotEmpty
                                          ? _nameController.text.trim()
                                          : 'Your Business / Vendor Name',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Color(0xFF0284C7), size: 16),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _taglineController.text.trim().isNotEmpty
                                    ? _taglineController.text.trim()
                                    : 'Specialized Service Tagline',
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
                                      _getCategoryName(_selectedCategory),
                                      style: const TextStyle(color: AppConstants.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '📍 ${_cityController.text.trim().isNotEmpty ? _cityController.text.trim() : "City"}',
                                    style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_startingPriceController.text.trim().isNotEmpty) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Starting Rate:', style: TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                          Text(
                            _startingPriceController.text.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit Button ──
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle, size: 22),
                label: Text(
                  _isSubmitting ? 'Registering Vendor...' : 'Save & Register Vendor Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _isSubmitting ? null : _submitVendor,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
