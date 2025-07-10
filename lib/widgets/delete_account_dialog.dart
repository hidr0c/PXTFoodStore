import 'package:flutter/material.dart';
import 'package:foodie/constant/app_color.dart';

class DeleteAccountDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteAccountDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'Xóa tài khoản',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
      content: Text(
        'Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text('Xóa', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
