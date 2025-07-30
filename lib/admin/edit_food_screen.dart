// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditFoodScreen extends StatefulWidget {
  final String foodId;
  final Map<String, dynamic> foodData;

  const EditFoodScreen({
    super.key,
    required this.foodId,
    required this.foodData,
  });

  @override
  State<EditFoodScreen> createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends State<EditFoodScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _maxQuantityController;

  String? _selectedCategory;
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị từ foodData
    _nameController = TextEditingController(text: widget.foodData['name']);
    _descriptionController =
        TextEditingController(text: widget.foodData['description']);
    _priceController =
        TextEditingController(text: widget.foodData['price'].toString());
    _quantityController =
        TextEditingController(text: widget.foodData['quantity'].toString());
    _maxQuantityController =
        TextEditingController(text: widget.foodData['maxQuantity'].toString());
    _selectedCategory = widget.foodData['category'];
    _imageUrl = widget.foodData['imageUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _maxQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chọn hình ảnh')),
        );
      }
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/dxn6dtumd/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'pxtfoodstore'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      }
      return null;
    } catch (e) {
      print('Lỗi khi tải ảnh lên: $e');
      return null;
    }
  }

  Future<void> _updateFood() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _maxQuantityController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _imageUrl;

      if (_imageFile != null) {
        // Nếu có ảnh mới được chọn, tải lên Cloudinary
        imageUrl = await _uploadImageToCloudinary(_imageFile!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải lên hình ảnh!')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Cập nhật thông tin món ăn vào Firestore
      await _firestore.collection('foods').doc(widget.foodId).update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'quantity': int.parse(_quantityController.text),
        'maxQuantity': int.parse(_maxQuantityController.text),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật món ăn thành công!')),
      );
      Navigator.pop(
          context, true); // Trả về true để biết là đã cập nhật thành công
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text('Chỉnh sửa món ăn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin món ăn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ảnh món ăn
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _imageFile == null && _imageUrl == null
                              ? const Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tên món ăn
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên món ăn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon:
                            Icon(Icons.fastfood, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mô tả
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.description,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Giá
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Giá (VNĐ)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.attach_money,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Số lượng hiện tại và tối đa
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: 'Số lượng hiện tại',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.production_quantity_limits,
                                  color: AppTheme.primaryColor),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: AppTheme.primaryColor),
                                onPressed: () {
                                  int max = int.tryParse(
                                          _maxQuantityController.text) ??
                                      0;
                                  int current =
                                      int.tryParse(_quantityController.text) ??
                                          0;
                                  if (current < max) {
                                    setState(() {
                                      _quantityController.text =
                                          (current + 1).toString();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxQuantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: 'Số lượng tối đa',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.inventory,
                                  color: AppTheme.primaryColor),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: AppTheme.primaryColor),
                                onPressed: () {
                                  int current =
                                      int.tryParse(_quantityController.text) ??
                                          0;
                                  int max = int.tryParse(
                                          _maxQuantityController.text) ??
                                      0;
                                  if (current <= max) {
                                    setState(() {
                                      _maxQuantityController.text =
                                          (max + 1).toString();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Danh mục
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon:
                            Icon(Icons.category, color: AppTheme.primaryColor),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pizza',
                          child: Text('Pizza'),
                        ),
                        DropdownMenuItem(
                          value: 'Burger',
                          child: Text('Burger'),
                        ),
                        DropdownMenuItem(
                          value: 'Chicken',
                          child: Text('Gà'),
                        ),
                        DropdownMenuItem(
                          value: 'Drinks',
                          child: Text('Đồ uống'),
                        ),
                        DropdownMenuItem(
                          value: 'Others',
                          child: Text('Khác'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Nút cập nhật
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          int current =
                              int.tryParse(_quantityController.text) ?? 0;
                          int max =
                              int.tryParse(_maxQuantityController.text) ?? 0;
                          if (_nameController.text.isNotEmpty &&
                              _descriptionController.text.isNotEmpty &&
                              _priceController.text.isNotEmpty &&
                              _quantityController.text.isNotEmpty &&
                              _maxQuantityController.text.isNotEmpty &&
                              current <= max) {
                            _updateFood();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Vui lòng nhập thông tin hợp lệ!')),
                            );
                          }
                        },
                        child: const Text(
                          'CẬP NHẬT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
