import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PDFApi {
  static Future getPdf() async {
    var url = "https://oshan263.000webhostapp.com/getData.php";
    final response = await http.get(Uri.parse(url));
    var data1 = jsonDecode(response.body);
    return data1;
  }
  static Future<File> loadNetwork(String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    return _storeFile(url, bytes);
  }
  static Future<File> _storeFile(String url, List<int> bytes) async {
    final filename = basename(url);
    final dir = await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
