import 'package:flutter/material.dart';

/// Data model for a section.
class SectionData {
  String name;
  String content;
  List<SectionData> subSections;
  
  SectionData({this.name = '', this.content = '', List<SectionData>? subSections})
      : subSections = subSections ?? [];
}

/// A widget that displays the structured template editor.
class StructuredTemplateEditor extends StatefulWidget {
  final List<SectionData> sections;
  const StructuredTemplateEditor({Key? key, required this.sections}) : super(key: key);

  @override
  State<StructuredTemplateEditor> createState() => _StructuredTemplateEditorState();
}

class _StructuredTemplateEditorState extends State<StructuredTemplateEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.sections
          .asMap()
          .entries
          .map((entry) => SectionEditor(
                section: entry.value,
                level: 1,
                onUpdate: () => setState(() {}),
              ))
          .toList(),
    );
  }
}

/// A widget that lets the user edit a single section.
class SectionEditor extends StatefulWidget {
  final SectionData section;
  final int level;
  final VoidCallback onUpdate;
  const SectionEditor({
    Key? key,
    required this.section,
    required this.level,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<SectionEditor> {
  bool _expanded = true;
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section.name);
    _contentController = TextEditingController(text: widget.section.content);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: _expanded,
      title: Text(
        widget.section.name.isEmpty
            ? "Name this section (Level ${widget.level})"
            : widget.section.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0 * widget.level, right: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Name this section (Level ${widget.level})",
                ),
                onChanged: (val) {
                  widget.section.name = val;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: "Enter content...",
                ),
                onChanged: (val) {
                  widget.section.content = val;
                },
                maxLines: null,
              ),
              const SizedBox(height: 8),
              if (widget.level < 3)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.section.subSections.add(SectionData());
                    });
                    widget.onUpdate();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Subcategory"),
                ),
              Column(
                children: widget.section.subSections
                    .asMap()
                    .entries
                    .map((entry) => SectionEditor(
                          section: entry.value,
                          level: widget.level + 1,
                          onUpdate: () => setState(() {}),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
      onExpansionChanged: (val) {
        setState(() {
          _expanded = val;
        });
      },
    );
  }
}
