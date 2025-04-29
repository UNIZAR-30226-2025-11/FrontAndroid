import 'package:flutter/material.dart';
import 'package:flutter_example/statistics.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'SessionManager.dart';
import 'editProfile.dart';
import 'homePage.dart';
import 'login.dart';
import 'userInfo.dart';  // Import UserInfo class
import 'customize.dart';  // Import Customize screen
import 'friends.dart';    // Import Friends screen

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
  final UserInfo userInfo = UserInfo();  // Create UserInfo instance

  @override
  void initState() {
    super.initState();
    username = widget.username;
    _initialize();
  }

  Future<void> _initialize() async {
    await userInfo.initialize();  // Initialize UserInfo
    await fetchUserData();
    await fetchShopItems();
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
        userInfo.refreshData();
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
      print(token);
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/shop'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );
      print('res:');
      print(res.statusCode);
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
              url: product['url'],
            ));
          }

          fetchedCategories.add(ShopCategory(
              name: category['name'],
              products: products,
              url: category['url']
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
      print(categoryName);
      print(productName);
      final res = await http.post(
        Uri.parse('http://10.0.2.2:8000/shop'),
        headers: {
          'Cookie': 'access_token=$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'resp': {
            'categoryName': categoryName,
            'productName': productName,
          }
        }),
      );
      print(res.body);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'Item purchased successfully!',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.green, width: 1),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.green,
              onPressed: () {},
            ),
          ),
        );
        setState(() {
        });

        await fetchUserData();
        await fetchShopItems();

      } else if (res.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'Could not complete the purchase',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.red, width: 1),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Could not complete the purchase',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.red, width: 1),
          ),
        ),
      );
    }
  }

  // Método para abrir el drawer de perfil
  void _openProfileDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Info Section
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: userInfo.avatarUrl.isNotEmpty
                              ? DecorationImage(
                            image: AssetImage('assets/images/avatar/${userInfo.avatarUrl}.png'),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: userInfo.avatarUrl.isEmpty
                            ? Icon(Icons.person, size: 40)
                            : null,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo.username,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Icon(Icons.monetization_on, color: Colors.yellow, size: 16),
                              SizedBox(width: 4),
                              Text("${userInfo.coins}"),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Home Button Section
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainScreen()
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Light background for the button
                        borderRadius: BorderRadius.circular(20), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home, color: Colors.black87),
                          SizedBox(width: 6),
                          Text(
                            "Home",
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 30),
              ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text("Statistics"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>StatisticsScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    //_initialize();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Edit profile"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    //_initialize();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.style),
                title: Text("Customize"),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CustomizeScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    print('custome set state');
                    //_initialize();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text("Shop"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ShopScreen(
                          username: userInfo.username,
                        )),
                  );
                  setState(() {
                    //_initialize();
                  });
                },
              ),
              ListTile(
                  leading: Icon(Icons.people),
                  title: Text("Friends"),
                  onTap:(){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FriendsScreen()),
                    );
                    setState(() {
                      //_initialize();
                    });
                  }
              ),
              ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Logout"),
                  onTap: () {
                    _showLogOutBar();
                  }
              ),
            ],
          ),
        );
      },
    );
  }
  // Add logout confirmation method from Statistics screen
  void _showLogOutBar() {
    // First, close the drawer
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text("Are you sure you want to log out?",
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  SessionManager.removeSessionData();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MainScreen()),
                  );
                },
                child: Text("YES", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Text("NO", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF3D0E40),
          duration: Duration(days: 365),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9D0514),
      // Remove the AppBar since we'll add the profile bar in the Stack
      body: Container(
        // Add background image if available
        decoration: userInfo.backgroundUrl.isNotEmpty
            ? BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/${userInfo.backgroundUrl}.png'),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
        )
            : null,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0), // Adjust as needed
              child: userInfo.buildProfileBar(context, _openProfileDrawer),
            ),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 70.0, 16.0, 16.0),
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
                              'assets/images/avatar/${product.url}.png';
                              print(imagePath);
                            } else {
                              imagePath =
                              'assets/images/background/${product.url}.png';
                            }

                            return ShopItemCard(
                              name: product.name,
                              price: product.price,
                              imagePath: imagePath,
                              isBought: product.isBought,
                              onBuy: () => buyItem(category.url, product.url),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopCategory {
  final String name;
  final String url;
  final List<ShopProduct> products;

  ShopCategory({
    required this.name,
    required this.url,
    required this.products,
  });
}

class ShopProduct {
  final String name;
  final int price;
  final bool isBought;
  final String url;

  ShopProduct({
    required this.name,
    required this.price,
    required this.isBought,
    required this.url,
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