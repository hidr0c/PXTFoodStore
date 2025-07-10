// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodie/constant/app_color.dart';
import 'add_food_screen.dart';

class FoodManageScreen extends StatefulWidget {
  const FoodManageScreen({super.key});

  @override
  State<FoodManageScreen> createState() => _FoodManageScreenState();
}

class _FoodManageScreenState extends State<FoodManageScreen> {
  String selectedCategory = "Chicken";

  // Hàm xóa món ăn
  Future<void> _deleteFood(String foodId) async {
    await FirebaseFirestore.instance.collection('foods').doc(foodId).delete();
    if (!mounted) return; // Ensure context is valid before using it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa món ăn!')),
    );
  }

  // Lấy danh sách món ăn từ Firestore theo loại đã chọn
  Stream<QuerySnapshot> _getFoodItems() {
    return FirebaseFirestore.instance
        .collection('foods')
        .where('category', isEqualTo: selectedCategory)
        .snapshots();
  }

  bool isFoodLocked(int quantity, int maxQuantity) {
    return quantity != 0;
  }

  Future<void> _addFillQuantity(String foodId, int currentMaxQuantity) async {
    final TextEditingController fillController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Thêm số lượng fill"),
          content: TextField(
            controller: fillController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Nhập số lượng muốn thêm",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final int fillAmount = int.tryParse(fillController.text) ?? 0;

                if (fillAmount > 0) {
                  await FirebaseFirestore.instance
                      .collection('foods')
                      .doc(foodId)
                      .update({
                    'maxQuantity': currentMaxQuantity + fillAmount,
                    'quantity': fillAmount,
                  });
                  if (!mounted) {
                    return; // Ensure context is valid before using it
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã cập nhật số lượng thành công!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  if (!mounted) {
                    return; // Ensure context is valid before using it
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số lượng không hợp lệ')),
                  );
                }
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đồ ăn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFoodScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCategorySlider(),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFoodItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Không có món ăn trong danh mục này."),
                    );
                  }

                  final foodItems = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: foodItems.length,
                    itemBuilder: (context, index) {
                      final food = foodItems[index];
                      final quantity = food['quantity'] ?? 0;
                      final maxQuantity = food['maxQuantity'] ?? 0;
                      return _buildFoodItem(food, quantity, maxQuantity);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySlider() {
    List<String> categories = ["Chicken", "Burger", "Drinks", "Other", "Pizza"];
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selectedCategory == category
                    ? Colors.orange[300]
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedCategory == category
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: selectedCategory == category
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget hiển thị mỗi món ăn
  Widget _buildFoodItem(
      QueryDocumentSnapshot food, int quantity, int maxQuantity) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  food['imageUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      food['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Số lượng: $quantity/$maxQuantity",
                      style: TextStyle(
                        color: isFoodLocked(quantity, maxQuantity)
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isFoodLocked(quantity, maxQuantity))
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () =>
                              _addFillQuantity(food.id, maxQuantity),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          child: const Text("Thêm số lượng",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${food['price']} VNĐ",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFood(food.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
