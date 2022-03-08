import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:pdf_reader/api/pdf_api.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SecondRoute extends StatefulWidget {
  final dynamic formData;
  final dynamic file;

  const SecondRoute({Key? key, this.formData, this.file}) : super(key: key);

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  dynamic pdfFile = '';
  dynamic res = '';
  bool isLoadingPdf = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    loadPdf();
    //getStoragePermission();
  }

  getStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        //Permission.camera,
      ].request();
    }
    //print('status===>$status'); // it should print PermissionStatus.granted
  }

  loadPdf() async {

    //print('loadPdf===>');
    pdfFile = await PDFApi.loadNetwork(widget.formData['url']);

    print('status===>$pdfFile');
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //loadPdf();
    final ButtonStyle style =
        TextButton.styleFrom(primary: Theme.of(context).colorScheme.onPrimary);
    var date = DateTime.now().millisecondsSinceEpoch.toString();
    var shouldAbsorb = isLoadingPdf ? true : false;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget.formData['description']),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
                          fileName: widget.formData['title'] + date);
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
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                              builder: (context) => SecondRoute(
                                formData: widget.formData,
                                file: widget.file,
                              )));
                          isLoadingPdf = false;
                        });
                        //Navigator.pop(context);
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
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _buildPdfViewer(pdfFile.path)),
    );
  }

  Widget _buildPdfViewer(String path) => PDFView(
        filePath: path,
        autoSpacing: true,
        enableSwipe: true,
        pageSnap: true,
        nightMode: false,
        onRender: (_pages) {
          print('_pages===>$_pages');
        },
        onError: ((e) => {print('e===>$e')}),
      );
}

Future openFile({required String url, String? fileName}) async {
  final file = await downloadFile(url, fileName!);

  print('file==>$file');
  if (file == null) return;
  Fluttertoast.showToast(
    msg: '$fileName Downloaded', // message
    toastLength: Toast.LENGTH_SHORT, // length
    gravity: ToastGravity.BOTTOM, // location
    // duration
  );
  final _result = await OpenFile.open(file.path);
  //print('_result==>$_result');
  dynamic res = _result.message;
  //print('res==>$res');
  return res;
}

Future<File?> downloadFile(String url, String name) async {
  String fileName = name.replaceAll(' ', '');
  //print('fileName==>$fileName');
  //String fileName2 = fileName1.replaceAll('-', '');
  //final appStorage = await getApplicationDocumentsDirectory();
  //storage/emulated/0/Download/
  //final file = File('${appStorage.path}/$fileName.pdf');
  //final file = File('D:\\Private\\$fileName.pdf');
  final file = File('/storage/emulated/0/Download/$fileName.pdf');

  //print('file==>$file');
  var encoded = Uri.encodeFull(url);
  //final encodedUrl = encoded.replaceAll('http', 'https');
  print('encoded==>$encoded');
  //print('encodedUrl==>$encodedUrl');
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
