import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider createExternalFileImageProvider(String path) {
  return FileImage(File(path));
}
