import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Data for a single page of the report.
class PageData {
  QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final List<File> inlineImages;
  final List<File> blankPageImages;
  Uint8List? signature;
  String? name;
  String? credentials;

  PageData()
      : controller = QuillController.basic(),
        scrollController = ScrollController(),
        focusNode = FocusNode(),
        inlineImages = [],
        blankPageImages = [];
}
