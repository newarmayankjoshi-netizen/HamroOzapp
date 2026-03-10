import 'package:flutter/material.dart';
import '../ui/listing_card.dart';
import 'listing_detail.dart';

class ListingsHome extends StatelessWidget {
  const ListingsHome({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(8, (i) => {
          'id': 'itm_$i',
          'title': 'Cozy room in City ${i + 1}',
          'subtitle': 'Suburb • 2 guests',
          'image': 'assets/marketplace.png',
          'price': '\$${50 + i * 10}/wk'
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListingCard(
              id: item['id']!,
              title: item['title']!,
              subtitle: item['subtitle']!,
              imageUrl: item['image']!,
              price: item['price']!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetail(
                    id: item['id']!,
                    title: item['title']!,
                    imageUrl: item['image']!,
                    price: item['price']!,
                  ),
                ),
              ),
              onFavorite: () {},
            );
          },
        ),
      ),
    );
  }
}
