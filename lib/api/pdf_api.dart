import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

import 'dart:io';
import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PDFApi {
  static Future getPdf() async {
    final Uri url = Uri.parse("https://tvetpapers.co.za/getData.php");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get data from server');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }
  static Future<Map<String, dynamic>> checkUser(String username, String password) async {
    final apiUrl = Uri.parse("https://low-cal-boost.000webhostapp.com/checkUser.php");
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      final data = json.decode(response.body);
      return data;
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return data;
      // } else {
      //   throw Exception('Failed to login user.');
      // }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to login user.');
    }
  }
  static Future<Map<String, dynamic>> registerUser(BuildContext context,String username, String password, String selectedSubscription) async {
    final apiUrl = Uri.parse("https://low-cal-boost.000webhostapp.com/register.php");
    final headers = {'Content-Type': 'application/json'};
    print(selectedSubscription);
    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
          'type': selectedSubscription,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 409) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to register user.');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to register user.');
    }
  }
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final apiUrl = Uri.parse("https://low-cal-boost.000webhostapp.com/login.php");
    final headers = {'Content-Type': 'application/json'};
    print('username: $username');
    print('password: $password');
    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to login user.');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to login user.');
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
