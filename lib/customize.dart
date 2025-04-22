import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'SessionManager.dart';
import 'UserInfo.dart';
import 'homePage.dart';

class CustomizeScreen extends StatefulWidget {
  final String username;

  CustomizeScreen({required this.username});

  @override
  _CustomizeScreenState createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  final UserInfo userInfo = UserInfo();
  bool isLoading = true;
  String? selectedAvatar;
  String? selectedBackground;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await userInfo.initialize();

      setState(() {
        selectedAvatar = userInfo.avatarUrl;
        selectedBackground = userInfo.backgroundUrl;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Unable to load user data")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateCustomization(String categoryName, String productName) async {
    try {
      final bool success = await userInfo.updateCustomization(categoryName, productName);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Customization updated successfully")),
        );

        // Update selected items
        if (categoryName.toLowerCase() == "avatar") {
          setState(() {
            selectedAvatar = productName;
          });
        } else if (categoryName.toLowerCase() == "background") {
          setState(() {
            selectedBackground = productName;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update customization")),
        );
      }
    } catch (e) {
      print("Error updating customization: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String _getAvatarAssetPath(String avatarName) {
    print(avatarName);
    return 'assets/images/avatar/${avatarName.toLowerCase()}.png';
  }

  String _getBackgroundAssetPath(String backgroundName) {
    print(backgroundName);
    return 'assets/images/background/${backgroundName.toLowerCase()}.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9D0514),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Customize Your Profile",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 5),
            ),
            SizedBox(height: 30),

            // Preview section
            _buildPreviewSection(),

            SizedBox(height: 30),

            // Avatars section
            Text(
              "Avatars",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            _buildProductGrid("avatar"),

            SizedBox(height: 30),

            // Backgrounds section
            Text(
              "Backgrounds",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            _buildProductGrid("background"),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        image: selectedBackground != null
            ? DecorationImage(
          image: AssetImage(_getBackgroundAssetPath(selectedBackground!)),
          fit: BoxFit.cover,
          opacity: 0.7,
        )
            : null,
      ),
      child: Column(
        children: [
          Text(
            "Preview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              //shape: BoxShape.circle,
              color: Colors.white,
              image: selectedAvatar != null
                  ? DecorationImage(
                image: AssetImage(_getAvatarAssetPath(selectedAvatar!)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: selectedAvatar == null
                ? Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          SizedBox(height: 8),
          Text(
            widget.username,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on, color: Colors.yellow),
              SizedBox(width: 4),
              Text(
                "${userInfo.coins}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(String categoryType) {
    // Filter products by category
    final products = userInfo.ownedProducts.where(
            (product) => product['categoryName'].toString().toLowerCase() == categoryType.toLowerCase()
    ).toList();

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No ${categoryType}s available. Visit the shop to purchase!",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final productName = product['productUrl'];
        final isSelected = (categoryType.toLowerCase() == "avatar" && selectedAvatar == productName) ||
            (categoryType.toLowerCase() == "background" && selectedBackground == productName);

        return GestureDetector(
          onTap: () {
            _updateCustomization(categoryType, productName);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: categoryType.toLowerCase() == "avatar"
                      ? Image.asset(
                    _getAvatarAssetPath(productName),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading avatar: $error");
                      return Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white70,
                      );
                    },
                  )
                      : Image.asset(
                    _getBackgroundAssetPath(productName),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading background: $error");
                      return Icon(
                        Icons.wallpaper,
                        size: 50,
                        color: Colors.white70,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}