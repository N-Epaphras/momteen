import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocalReferralsPage extends StatelessWidget {
  const LocalReferralsPage({super.key});

  final List<Map<String, String>> hospitals = const [
    {
      "name": "Kabale Regional Referral Hospital",
      "location": "Makanga Hill, Kabale Municipality",
      "contact": "+256 766304836",
    },
    {
      "name": "Rugarama Hospital",
      "location": "Rugarama Hill, Kabale",
      "contact": "+256 708103717",
    },
    {
      "name": "Rushoroza Hospital",
      "location": "Rushoroza Hill, Kabale",
      "contact": "+256 774 555666",
    },
    {
      "name": "Kamukira Health Center IV",
      "location": "Central Division, Kabale",
      "contact": "N/A",
    },
    {
      "name": "Maziba Health Center IV",
      "location": "Maziba Sub-county, Kabale",
      "contact": "N/A",
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Local Health Referrals")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hospitals.length,
        itemBuilder: (context, index) {
          final hospital = hospitals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: Text(
                hospital["name"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(hospital["location"]!),
                    ],
                  ),
                ],
              ),
              trailing: hospital["contact"] != "N/A"
                  ? IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () {
                        _makePhoneCall(
                          hospital["contact"]!.replaceAll(' ', ''),
                        );
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
