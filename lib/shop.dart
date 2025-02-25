import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      backgroundColor: Color(0xFF9D0514),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ShopItem(title: 'Card Skin 1', price: '100 Coins'),
            ShopItem(title: 'Card Skin 2', price: '150 Coins'),
            ShopItem(title: 'Avatar 1', price: '200 Coins'),
            ShopItem(title: 'Avatar 2', price: '250 Coins'),
            ShopItem(title: 'Special Effect', price: '300 Coins'),
          ],
        ),
      ),
    );
  }
}

class ShopItem extends StatelessWidget {
  final String title;
  final String price;

  const ShopItem({required this.title, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: ElevatedButton(
          onPressed: () {}, // Add functionality later
          child: Text('Buy'),
        ),
      ),
    );
  }
}
