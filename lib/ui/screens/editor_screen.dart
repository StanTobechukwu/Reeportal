import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'preview_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '/models/document/page_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});  // super parameter usage 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReportApp',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const ReportEditorScreen(),
        '/signature': (_) => SignatureCaptureScreen(),  // no const here
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/preview') {
          final pages = settings.arguments as List<PageData>;
          return MaterialPageRoute(builder: (_) => PreviewScreen(pages: pages));
        }
        return null;
      },
    );
  }
}

enum FormType { plain, template }

/*class PageData {
  quill.QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final List<File> inlineImages;
  final List<File> blankPageImages;
  Uint8List? signature;
  String? name;
  String? credentials;

  PageData()
      : controller = quill.QuillController.basic(),
        scrollController = ScrollController(),
        focusNode = FocusNode(),
        inlineImages = [],
        blankPageImages = [];
}*/

class ReportEditorScreen extends StatefulWidget {
   /// If non-null, we'll load this existing document for editing.
  final String? documentId;

  const ReportEditorScreen({
    Key? key,
    this.documentId,               // ← newly added optional parameter
  }) : super(key: key);

  @override
  _ReportEditorScreenState createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends State<ReportEditorScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FormType _formType = FormType.plain;
  List<String> _categoryNames = [];
  List<Map<String, dynamic>> _templates = [];
  List<PageData> _pages = [];
  int _currentPage = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
  _pages = [PageData()];
    _loadTemplates().whenComplete(() => setState(() => _loading = false));
  }

  Future<void> _loadTemplates() async {
    final snap = await _db.collection('templates').orderBy('createdAt', descending: true).get();
    _templates = snap.docs.map((d) => d.data()).toList();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    } else {
      setState(() {
        _pages.add(PageData());
        _currentPage = _pages.length - 1;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  Future<void> _selectFormType() async {
    final choice = await showModalBottomSheet<FormType>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: FormType.values.map((type) {
          return ListTile(
            title: Text(type == FormType.plain ? 'Plain Form' : 'Previous Template'),
            onTap: () => Navigator.pop(context, type),
          );
        }).toList(),
      ),
    );
    if (choice != null) {
      setState(() => _formType = choice);
      if (choice == FormType.plain) {
        _promptCategories();
      } else {
        _pickTemplate();
      }
    }
  }

  Future<void> _promptCategories() async {
    final ctrl = TextEditingController();
    final list = await showDialog<List<String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter categories (comma separated)'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.split(',').map((s) => s.trim()).toList()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (list != null) setState(() => _categoryNames = list);
  }

  Future<void> _pickTemplate() async {
    final pick = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select Template'),
        children: _templates.map((t) {
          return SimpleDialogOption(
            child: Text(t['name'] ?? 'Template'),
            onPressed: () => Navigator.pop(context, t),
          );
        }).toList(),
      ),
    );
    if (pick != null && pick['delta'] != null) {
      final json = List<Map<String, dynamic>>.from(pick['delta']);
      final doc = quill.Document.fromJson(json);
      setState(() {
        final p = _pages[_currentPage];
        p.controller = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    }
  }

  Future<void> _addInlineImage() async {
    final images = _pages[_currentPage].inlineImages;
    if (images.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 4 images; moving to next page')));
      _nextPage();
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => images.add(File(picked.path)));
  }

  Future<void> _addBlankImages() async {
    final files = await _picker.pickMultiImage();
    if (files != null) {
      final list = _pages[_currentPage].blankPageImages;
      for (var f in files) {
        if (list.length < 9) list.add(File(f.path));
      }
      setState(() {});
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Done'),
          content: const Text('Images added to blank page'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  Future<void> _addSignature() async {
    final sig = await Navigator.pushNamed(context, '/signature') as Uint8List?;
    if (sig != null) setState(() => _pages[_currentPage].signature = sig);
  }

  Future<void> _addNameCred() async {
    final nameCtrl = TextEditingController(text: _pages[_currentPage].name);
    final credCtrl = TextEditingController(text: _pages[_currentPage].credentials);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Name & Credentials'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: credCtrl, decoration: const InputDecoration(labelText: 'Credentials')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _pages[_currentPage].name = nameCtrl.text;
                _pages[_currentPage].credentials = credCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (_formType == FormType.plain && _categoryNames.isNotEmpty) {
      await _db.collection('templates').add({
        'name': 'Template ${DateTime.now()}',
        'categories': _categoryNames,
        'delta': _pages.map((p) => p.controller.document.toDelta().toJson()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved')));
    }
  }

  void _preview() {
    Navigator.pushNamed(context, '/preview', arguments: _pages);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final page = _pages[_currentPage];
    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${_currentPage + 1}/${_pages.length}'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: _selectFormType),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _nextPage),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: quill.QuillEditor(
                    controller: page.controller,
                    scrollController: page.scrollController,
                    focusNode: page.focusNode,
                    config: quill.QuillEditorConfig(
                      placeholder: 'Write report here...',
                      scrollable: true,
                      autoFocus: true,
                      showCursor: true,
                      expands: true,
                      padding: const EdgeInsets.all(12),
                      embedBuilders: kIsWeb
                          ? FlutterQuillEmbeds.editorWebBuilders()
                          : FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),
                ),
                if (page.inlineImages.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: page.inlineImages
                          .map((f) => Padding(padding: const EdgeInsets.all(4), child: Image.file(f)))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (page.blankPageImages.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: page.blankPageImages
                    .map((f) => Padding(padding: const EdgeInsets.all(4), child: Image.file(f)))
                    .toList(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.brush), onPressed: _addSignature, tooltip: 'Add Signature'),
              IconButton(icon: const Icon(Icons.image), onPressed: _addInlineImage, tooltip: 'Add Inline Image'),
              IconButton(icon: const Icon(Icons.photo), onPressed: _addBlankImages, tooltip: 'Add Blank Page Images'),
              IconButton(icon: const Icon(Icons.person), onPressed: _addNameCred, tooltip: 'Add Name/Credentials'),
              IconButton(icon: const Icon(Icons.preview), onPressed: _preview, tooltip: 'Preview'),
              IconButton(icon: const Icon(Icons.save_alt), onPressed: _saveTemplate, tooltip: 'Save Template'),
            ],
          ),
        ),
      ),
    );
  }
}

class SignatureCaptureScreen extends StatefulWidget {
  SignatureCaptureScreen({Key? key}) : super(key: key);

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Signature')),
      body: Column(
        children: [
          Expanded(child: Signature(controller: _controller, backgroundColor: Colors.grey[200]!)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(onPressed: () => _controller.clear(), child: const Text('Clear')),
              ElevatedButton(
                onPressed: () async {
                  if (_controller.isNotEmpty) {
                    final bytes = await _controller.toPngBytes();
                    if (bytes != null) Navigator.pop(context, bytes);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a signature')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
