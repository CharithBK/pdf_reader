import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:pdf_reader/api/pdf_api.dart';

class SecondRoute extends StatefulWidget {
  final dynamic formData;
  final dynamic file;

  const SecondRoute({Key? key, this.formData, this.file}) : super(key: key);

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  dynamic pdfFile;
  dynamic res = '';
  bool isLoadingPdf = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPdf();
  }

  loadPdf() async {
    pdfFile = await PDFApi.loadNetwork(widget.formData['url']);
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        TextButton.styleFrom(primary: Theme.of(context).colorScheme.onPrimary);
    var shouldAbsorb = isLoadingPdf ? true : false;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.formData['description']),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AbsorbPointer(
                absorbing: shouldAbsorb,
                child: TextButton(
                  style: style,
                  onPressed: () {
                    setState(() {
                      isLoadingPdf = true;
                    });
                    openFile(
                        url: widget.formData['url'],
                        fileName:
                            widget.formData['title'] + widget.formData['id']);
                    Fluttertoast.showToast(
                      msg: 'Downloading ${widget.formData['description']} PDF',
                      // message
                      toastLength: Toast.LENGTH_SHORT,
                      // length
                      gravity: ToastGravity.BOTTOM, // location
                      // duration
                    );
                    Future.delayed(const Duration(seconds: 6), () {
                      setState(() {
                        isLoadingPdf = false;
                      });
                      Navigator.pop(context);
                    });
                  },
                  child: const Icon(
                    Icons.arrow_circle_down_sharp,
                    color: Colors.white,
                    size: 25.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: PDFView(
          filePath: widget.file.path,
          onError: ((e) => {print('e===>$e')}),
        ));
  }
}

Future openFile({required String url, String? fileName}) async {
  final file = await downloadFile(url, fileName!);
  if (file == null) return;
  Fluttertoast.showToast(
    msg: '$fileName Downloaded', // message
    toastLength: Toast.LENGTH_SHORT, // length
    gravity: ToastGravity.BOTTOM, // location
    // duration
  );
  final _result = await OpenFile.open(file.path);
  dynamic res = _result.message;
  return res;
}

Future<File?> downloadFile(String url, String name) async {
  String fileName = name.replaceAll(' ', '');
  //String fileName2 = fileName1.replaceAll('-', '');
  final appStorage = await getApplicationDocumentsDirectory();
  //storage/emulated/0/Download/
  //final file = File('${appStorage.path}/$fileName.pdf');
  final file = File('/storage/emulated/0/Download/$fileName.pdf');
  //print('file==>$file');
  var encoded = Uri.encodeFull(url);
  final encodedUrl = encoded.replaceAll('http', 'https');

  try {
    final response = await Dio().get(encodedUrl,
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
