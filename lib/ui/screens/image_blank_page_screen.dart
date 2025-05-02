

// lib/ui/screens/image_blank_page_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; 
class ImageBlankPageScreen extends StatefulWidget {
const ImageBlankPageScreen({Key? key}) : super(key: key);
@override
_ImageBlankPageScreenState createState() => _ImageBlankPageScreenState();
}

class _ImageBlankPageScreenState extends State {
final List _paths = [];

Future _pickImage() async {
if (_paths.length >= 9) return;
final file = await ImagePicker().pickImage(source: ImageSource.gallery);
if (file != null) setState(() => _paths.add(file.path));
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Blank Page Images')),
body: GridView.count(
crossAxisCount: 3,
children: [
..._paths.map((p) => Padding(
padding: const EdgeInsets.all(4),
child: Image.file(File(p), fit: BoxFit.cover),
)),
if (_paths.length < 9)
IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _pickImage),
],
),
bottomNavigationBar: Padding(
padding: const EdgeInsets.all(8),
child: ElevatedButton(
onPressed: () => Navigator.pop(context, _paths),
child: const Text('Done'),
),
),
);
}
}
