import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf_reader/page/pdf_view.dart';

import 'api/pdf_api.dart';
import 'widget/search_widget.dart';

void main() {
  runApp(const MyApp());
}

class BookList {
  final String title;
  final String url;

  const BookList(this.title, this.url);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'List of Books'),
      // routes: {
      //   '/second': (_) => SecondRoute(
      //     formData: data,
      //   )
      // },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int number = 0;
  dynamic list = [];
  List duplicateItems = [];
  var items = [];
  String query = '';
  bool isLoading = false;
  bool isLoadingPdf = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    _loadData();
  }

  void filterSearchResults(String query) {
    List dummySearchList = [];
    dummySearchList.addAll(duplicateItems);
    if (query.isNotEmpty) {
      List dummyListData = [];
      dummySearchList.forEach((item) {
        final titleLower = item['description'].toLowerCase();
        final queryLower = query.toLowerCase();
        if (titleLower.contains(queryLower)) {
          dummyListData.add(item);
        }
      });
      setState(() {
        items.clear();
        items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        items.clear();
        items.addAll(duplicateItems);
      });
    }
  }

  void _loadData() async {
    dynamic file = await PDFApi.getPdf();
    setState(() {
      list = file;
      List tempArray = [];
      list.forEach((el) => {tempArray.add(el)});
      duplicateItems = tempArray;
      items.addAll(tempArray);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: const Size(double.infinity, 1.0),
            child: isLoadingPdf
                ? const LinearProgressIndicator()
                : const SizedBox(height: 0),
          ),
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildSearch(),
              _buildPdfList(list),
            ],
          ),
        )));
  }

  Widget _buildPdfList(
    dynamic list,
  ) {
    var shouldAbsorb = isLoadingPdf ? true : false;
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 400.0,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, int index) {
                        dynamic url;
                        dynamic file;
                        return AbsorbPointer(
                          absorbing: shouldAbsorb,
                          child: GestureDetector(
                            onTap: () async => {
                              setState(() {
                                isLoadingPdf = true;
                              }),
                              url = items[index]['url'],
                              file = await PDFApi.loadNetwork(url),
                              openPDF(items[index], file),
                            },
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  items[index]['description'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22.0),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  openPDF(items, file) {
    setState(() {
      isLoadingPdf = false;
    });

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SecondRoute(
              formData: items,
              file: file,
            )));
  }

  Widget _buildSearch() => SearchWidget(
        text: query,
        hintText: 'Search books',
        onChanged: (String value) {
          filterSearchResults(value);
        },
      );
}
