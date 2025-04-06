import 'package:flutter/material.dart';
import 'package:flutter_example/statistics.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'SessionManager.dart';
import 'editProfile.dart';
import 'login.dart';

class ShopScreen extends StatefulWidget {
  final String username;

  const ShopScreen({Key? key, required this.username}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool isLoading = true;
  int coins = 0;
  List<ShopCategory> categories = [];
  String username = '';

  @override
  void initState() {
    super.initState();
    username = widget.username;
    fetchUserData();
    fetchShopItems();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First ensure we have the username
      if (username.isEmpty) {
        final String? user = await SessionManager.getUsername();
        if (user != null && user.isNotEmpty) {
          username = user;
        } else {
          throw Exception("Username not available");
        }
      }

      // Then fetch the user data
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/user'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Server error: ${res.statusCode}";
        throw Exception(errorMessage);
      }

      setState(() {
        coins = int.parse(data['coins'].toString());
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchShopItems() async {
    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/shop'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );
      print(res);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<ShopCategory> fetchedCategories = [];

        for (var category in data['categories']) {
          List<ShopProduct> products = [];

          for (var product in category['products']) {
            products.add(ShopProduct(
              name: product['name'],
              price: product['price'],
              isBought: product['isBought'],
            ));
          }

          fetchedCategories.add(ShopCategory(
            name: category['name'],
            products: products,
          ));
        }

        setState(() {
          categories = fetchedCategories;
          isLoading = false;
        });
      } else if (res.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Bad request')),
        );
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load shop items");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading shop: ${e.toString()}')),
      );
    }
  }

  Future<void> buyItem(String categoryName, String productName) async {
    try {
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.post(
        Uri.parse('http://10.0.2.2:8000/shop'),
        headers: {
          'Cookie': 'access_token=$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'category-name': categoryName,
          'product-name': productName,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item purchased successfully!')),
        );
        // Refresh data
        fetchUserData();
        fetchShopItems();
      } else if (res.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not complete the purchase')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error buying item: ${e.toString()}')),
      );
    }
  }

  void _openProfileDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Profile Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text("Statistics"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            StatisticsScreen(
                              username: username,
                            )),
                  );
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Edit profile"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditProfileScreen(
                              username: username,
                            )),
                  );
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () {
                    SessionManager.removeSessionData();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9D0514),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9D0514),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: _openProfileDrawer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              username,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.monetization_on, color: Colors.yellow, size: 24),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: category.products.length,
                  itemBuilder: (context, productIndex) {
                    final product = category.products[productIndex];

                    // Determine image path based on category
                    String imagePath;
                    if (category.name.toLowerCase().contains('avatar')) {
                      imagePath =
                      'assets/images/avatares/${product.name}.png';
                    } else {
                      imagePath =
                      'assets/images/backgrounds/${product.name}.png';
                    }

                    return ShopItemCard(
                      name: product.name,
                      price: product.price,
                      imagePath: imagePath,
                      isBought: product.isBought,
                      onBuy: () => buyItem(category.name, product.name),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ShopCategory {
  final String name;
  final List<ShopProduct> products;

  ShopCategory({
    required this.name,
    required this.products,
  });
}

class ShopProduct {
  final String name;
  final int price;
  final bool isBought;

  ShopProduct({
    required this.name,
    required this.price,
    required this.isBought,
  });
}

class ShopItemCard extends StatelessWidget {
  final String name;
  final int price;
  final String imagePath;
  final bool isBought;
  final VoidCallback onBuy;

  const ShopItemCard({
    Key? key,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.isBought,
    required this.onBuy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('$price'),
                      ],
                    ),
                    isBought
                        ? const Chip(
                      label: Text('Owned'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                      padding: EdgeInsets.all(0),
                    )
                        : ElevatedButton(
                      onPressed: onBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D0514),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(60, 30),
                      ),
                      child: const Text('Buy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
