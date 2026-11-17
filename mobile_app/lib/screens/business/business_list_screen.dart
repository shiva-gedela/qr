import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../../services/api_service.dart';
import 'business_detail_screen.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({Key? key}) : super(key: key);

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  late Future<List<BusinessModel>> _bizFuture;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  void _loadBusinesses() {
    setState(() {
      _bizFuture = ApiService.getBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadBusinesses(),
        child: FutureBuilder<List<BusinessModel>>(
          future: _bizFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading businesses: ${snapshot.error}'));
            }

            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.storefront_outlined, size: 64, color: AppConstants.textMuted),
                      SizedBox(height: 16),
                      Text('No Business Profiles Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Create your digital business profile on EventConnect QR to share catalogs, WhatsApp & directions.'),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final b = list[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.business, color: AppConstants.primaryColor),
                    ),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (b.tagline.isNotEmpty) Text(b.tagline, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${b.city} • ${b.phone}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b)));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
