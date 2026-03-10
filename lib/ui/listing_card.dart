import 'package:flutter/material.dart';

class ListingCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ListingCard({super.key, required this.id, required this.title, required this.subtitle, required this.price, this.imageUrl, this.onTap, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Container(
              height: 160,
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Center(child: Icon(Icons.home, size: 48, color: Theme.of(context).colorScheme.primary)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.star, size: 14), SizedBox(width: 4), Text('4.8')]),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
