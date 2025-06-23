import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// todo: firebase storage => cloudinary
class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedCategory;
  File? _imageFile;
  String? _imageUrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // final FirebaseStorage _storage = FirebaseStorage.instance;

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

  // Future<String?> _uploadImage(File image) async {
  //   try {
  //     String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //     Reference storageRef = _storage.ref().child("foods/$fileName.jpg");
  //
  //     UploadTask uploadTask = storageRef.putFile(image);
  //     TaskSnapshot snapshot = await uploadTask;
  //
  //     Lấy URL của hình ảnh sau khi tải lên thành công
  //     String downloadUrl = await snapshot.ref.getDownloadURL();
  //     return downloadUrl;
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Không thể tải lên hình ảnh: $e')),
  //     );
  //     return null;
  //   }
  // }

  Future<String?> _uploadImage(File image) async {
    try {
      // Thông tin Cloudinary
      const String cloudName = "dbzvxli5e";
      const String apiKey = "934527959255681";
      const String uploadPreset = "foodie";

      // Tạo URL API
      final String apiUrl =
          "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      // Tạo form data để tải lên hình ảnh
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString()
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      // Gửi yêu cầu tải lên
      final response = await request.send();

      if (response.statusCode == 200) {
        // Lấy URL từ kết quả trả về
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);
        return responseData['secure_url'];
      } else {
        throw Exception(
            'Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải lên hình ảnh: $e')),
        );
      }
      return null;
    }
  }

  // Hàm để thêm món ăn vào Firestore
  Future<void> _addFood() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = _priceController.text.trim(); // Kiểm tra các trường thông tin
    if (name.isEmpty ||
        description.isEmpty ||
        price.isEmpty ||
        _imageFile == null ||
        _selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Vui lòng điền tất cả các trường và chọn hình ảnh')),
        );
      }
      return;
    }

    // Tải hình ảnh lên Firebase Storage và lấy URL
    _imageUrl = await _uploadImage(_imageFile!);

    if (_imageUrl != null) {
      // Thêm món ăn mới vào Firestore
      await _firestore.collection('foods').add({
        'name': name,
        'description': description,
        'price': int.parse(price),
        'imageUrl': _imageUrl,
        'category': _selectedCategory,
        'quantity': 0,
        'maxQuantity': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm món ăn thành công!')),
        );
      }

      // Reset các trường thông tin sau khi thêm thành công
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _imageFile = null;
        _selectedCategory = null;
      });
    }
  }

  // Hàm lấy danh mục từ Firestore
  Future<List<String>> _getCategories() async {
    QuerySnapshot snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) => doc['name'].toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm món ăn mới',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món ăn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá (VNĐ)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Chọn hình ảnh'),
                  ),
                  const SizedBox(width: 16),
                  _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Text('Chưa chọn hình ảnh'),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<String>>(
                future: _getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Chọn danh mục',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    items: snapshot.data!.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addFood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      const Text('Thêm món ăn', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
