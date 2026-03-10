import 'package:flutter/material.dart';

class ListingDetail extends StatelessWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final String? price;

  const ListingDetail({super.key, required this.id, required this.title, this.imageUrl, this.price});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          if (imageUrl != null)
            Image(
              image: imageUrl!.startsWith('http') ? NetworkImage(imageUrl!) : AssetImage(imageUrl!) as ImageProvider,
              fit: BoxFit.cover,
              height: 260,
              width: double.infinity,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('This is a placeholder listing detail. Replace with real data.'),
              ],
            ),
          )
        ],
      ),
    );
  }
}
