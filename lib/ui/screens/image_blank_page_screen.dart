import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageBlankPageScreen extends StatefulWidget {
  const ImageBlankPageScreen({Key? key}) : super(key: key);

  @override
  State<ImageBlankPageScreen> createState() => _ImageBlankPageScreenState();
}

class _ImageBlankPageScreenState extends State<ImageBlankPageScreen> {
  final List<String> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_images.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 9 images allowed")),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      final extension = pickedFile.path.split('.').last;
      final dataUri = 'data:image/$extension;base64,$base64Str';
      setState(() {
        _images.add(dataUri);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blank Page Images")),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: List.generate(9, (index) {
                if (index < _images.length) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.memory(
                      base64Decode(
                        _images[index].replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), ''),
                      ),
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  );
                }
              }),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo),
            label: const Text("Add Image"),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


