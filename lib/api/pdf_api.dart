import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

import 'dart:io';
import 'dart:io' show Platform;
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
    if (Platform.isWindows) {
      final filename2 = basename(url);
      String fileName = filename2.replaceAll(' ', '');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}\\$fileName');
      final dirs = await file.writeAsBytes(bytes, flush: true);
      return file;
    } else {
      final filename = basename(url);
      //String fileName = filename2.replaceAll(' ', '');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      final dirs = await file.writeAsBytes(bytes, flush: true);
      return file;
    }
  }
  static Future openFile({required String url, String? fileName}) async {
    //print('url==>$url');
    //print('fileName==>$fileName');
    final file = await downloadFile(url, fileName!);


    if (file == null) return;
    if (!Platform.isWindows) {
      Fluttertoast.showToast(
        msg: '$fileName Downloaded', // message
        toastLength: Toast.LENGTH_SHORT, // length
        gravity: ToastGravity.BOTTOM, // location
        // duration
      );
    }

    final _result = await OpenFile.open(file.path);
    //print('_result==>$_result');
    dynamic res = _result.message;
    //print('res==>$res');
    return res;
  }

  static Future<File?> downloadFile(String url, String name) async {
    final File file;
    String fileName1 = name.replaceAll(' ', '');
    String fileName2 = fileName1.replaceAll('-', '');
    if (Platform.isWindows) {
      final appStorage = await getApplicationDocumentsDirectory();
      file = File('${appStorage.path}\\$fileName2.pdf');
    } else {
      file = File('/storage/emulated/0/Download/$fileName2.pdf');
    }
    var encoded = Uri.encodeFull(url);
    try {
      final response = await Dio().get(encoded,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            receiveTimeout: 0,
          ));

      final ref = file.openSync(mode: FileMode.write);
      ref.writeFromSync(response.data);
      await ref.close();

      return file;
    } catch (e) {
      return null;
    }
  }
}
