import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PDFApi {
  static Future getPdf() async {
    try {
      //var url = "https://oshan263.000webhostapp.com/getData.php";
      final response = await http.get(
        Uri.parse("https://oshan263.000webhostapp.com/getData.php"),
      );

      var data1 = jsonDecode(response.body);
      //print('response===>$data1');
      return data1;
    } catch (e) {
      print('exception===>$e');
    }
  }

  static Future<File> loadNetwork(String url) async {
    //var encoded = Uri.encodeFull(url);
    final response = await http.get(Uri.parse(url));

    final bytes = response.bodyBytes;

    return _storeFile(url, bytes);
  }

  static Future<File> _storeFile(String url, List<int> bytes) async {
    final filename = basename(url);
    //String fileName = filename2.replaceAll(' ', '');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    //final file = File('D:\\download\\$fileName');
    print('file===>$file');
    final dirs = await file.writeAsBytes(bytes, flush: true);
    //print('dirs===>$dirs');

    return file;
  }
}
