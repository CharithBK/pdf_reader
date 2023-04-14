import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf_reader/page/pdf_view.dart';
import 'package:universal_html/html.dart' as html;
import 'api/pdf_api.dart';
import 'widget/search_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_paypal/flutter_paypal.dart';

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
      title: 'PDF Reader',
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
  bool isWebMobile = false;
  bool _showLogin = true;
  bool isLogged = false;
  String? selectedSubscription = 'trail';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  void toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }
  late Timer _subscriptionTimer;
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
      if (dummySearchList != null) {
        dummySearchList.forEach((item) {
          final titleLower = item['description'].toLowerCase();
          final queryLower = query.toLowerCase();
          if (titleLower.contains(queryLower)) {
            dummyListData.add(item);
          }
        });
      }
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
      if (list != null) {
        list.forEach((el) => {tempArray.add(el)});
      }
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
          actions: [
            Visibility(
              visible: isLogged,
              child: IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () {
                  // setState(() {
                  //   isLogged = false;
                  // });
                  logout();
                },
              ),
            ),
          ],
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _showLogin
                  ? (isLogged ? Container() : _login())
                  : (isLogged ? Container() : _register()),
              Visibility(
                visible: isLogged,
                child: Column(
                  children: [
                    _buildSearch(),
                    _buildPdfList(list),
                  ],
                ),
              ),
            ],
          ),
        )));
  }

  Widget _login() {
    bool isValidEmail(String email) {
      return RegExp(r'^[\w.+-]+@gmail\.com$').hasMatch(email);
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue,
            Color(0xFF102873),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your gmail';
                      }
                      if (!isValidEmail(value)) {
                        return 'Please enter a valid gmail address';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState != null &&
                            _formKey.currentState!.validate()) {
                          try {
                            Map<String, dynamic> response = await PDFApi.login(
                                _emailController.text,
                                _passwordController.text);
                            if (response['status_code'] == 200) {
                              setState(() {
                                // set visibility to true
                                isLogged = true;
                                _subscriptionTimer = Timer.periodic(const Duration(seconds: 10), (Timer t) async {

                                  Map<String, dynamic> response = await PDFApi.login(
                                      _emailController.text,
                                      _passwordController.text);
                                   if(response['status_code'] == 403){
                                     // Subscription has expired, log out the user
                                     logout();
                                   }
                                });
                              });
                            } else {
                              final snackBar = SnackBar(
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                content: AwesomeSnackbarContent(
                                  title: response['status_code'] == 401 ? 'Error!':'Warning!',
                                  message:response['message'],
                                  contentType: response['status_code'] == 401 ? ContentType.failure : ContentType.warning,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);

                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text(response['message'],textAlign: TextAlign.center,),
                              //   ),
                              // );
                            }
                          } catch (error) {
                            setState(() {
                              // set visibility to false
                              isLogged = false;
                            });
                            final snackBar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'Error!',
                                message:error.toString(),
                                contentType: ContentType.failure,
                              ),
                            );

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(snackBar);
                          }
                        }
                      },
                      child: const Text('LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        toggleView();
                      },
                      child: const Text(
                        'Register here',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void logout() {
    // Stop subscription timer
    _subscriptionTimer?.cancel();
    setState(() {
      _emailController.text = '';
      _passwordController.text = '';
      isLogged = false;
    });
  }
  Widget _register() {
    bool isValidEmail(String email) {
      return RegExp(r'^[\w.+-]+@gmail\.com$').hasMatch(email);
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue,
            Color(0xFF102873),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your gmail';
                      }
                      if (!isValidEmail(value)) {
                        return 'Please enter a valid gmail address';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedSubscription,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      labelText: 'Subscription Type',
                      labelStyle: TextStyle(
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a subscription type';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        selectedSubscription = value;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'trail',
                        child: Text('Trail'),
                      ),
                      DropdownMenuItem(
                        value: 'one_week',
                        child: Text('1 week'),
                      ),
                      DropdownMenuItem(
                        value: 'one_month',
                        child: Text('1 month'),
                      ),
                      DropdownMenuItem(
                        value: 'one_year',
                        child: Text('1 year'),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState != null &&
                            _formKey.currentState!.validate()) {
                          processPaypalPayment(selectedSubscription!);
                              // Map<String, dynamic> response =
                              //     await PDFApi.checkUser(
                              //         _emailController.text,
                              //         _passwordController.text);
                              // if(response['status_code'] == 200){
                              //   processPaypalPayment(selectedSubscription!);
                              // } else {
                              //   final snackBar = SnackBar(
                              //     elevation: 0,
                              //     behavior: SnackBarBehavior.floating,
                              //     backgroundColor: Colors.transparent,
                              //     content: AwesomeSnackbarContent(
                              //       title: 'Warning!',
                              //       message:response['message'],
                              //       contentType: ContentType.warning,
                              //     ),
                              //   );
                              //
                              //   ScaffoldMessenger.of(context)
                              //     ..hideCurrentSnackBar()
                              //     ..showSnackBar(snackBar);
                              // }
                        }

                      },
                      child: const Text('REGISTER'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        toggleView();
                      },
                      child: const Text(
                        'Login here',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfList(
    dynamic list,
  ) {
    var shouldAbsorb = isLoadingPdf ? true : false;

    var encoded = '';
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
                        dynamic pdfName;
                        dynamic file;
                        dynamic clickedButton;
                        return AbsorbPointer(
                          absorbing: shouldAbsorb,
                          child: GestureDetector(
                            onTap: () async => {
                              url = items[index]['url'],
                              encoded = Uri.encodeFull(url),
                              if (!kIsWeb)
                                {
                                  if (Platform.isWindows)
                                    {
                                      pdfName = items[index]['description']
                                          .replaceAll(' ', ''),
                                      clickedButton = await FlutterPlatformAlert
                                          .showCustomAlert(
                                        windowTitle: 'Download PDF',
                                        text:
                                            'Do you want to download $pdfName',
                                        positiveButtonTitle: "Yes",
                                        negativeButtonTitle: "No",
                                      ),
                                      if (clickedButton ==
                                          CustomButton.positiveButton)
                                        {
                                          setState(() {
                                            isLoadingPdf = true;
                                          }),
                                          await PDFApi.loadNetwork(url)
                                              .then((value) async => {
                                                    setState(() {
                                                      isLoadingPdf = false;
                                                    }),
                                                    await FlutterPlatformAlert
                                                        .showCustomAlert(
                                                            windowTitle:
                                                                'PDF Downloaded',
                                                            text: '',
                                                            neutralButtonTitle:
                                                                'Ok')
                                                  }),
                                        }
                                    }
                                  else
                                    {
                                      setState(() {
                                        isLoadingPdf = true;
                                      }),
                                      file = await PDFApi.loadNetwork(url),
                                      openPDF(items[index], file),
                                    }
                                }
                              else
                                {
                                  //print('encoded===>$encoded'),
                                  html.window.open(encoded, "_blank"),
                                  html.Url.revokeObjectUrl(encoded),
                                  setState(() {
                                    isLoadingPdf = false;
                                  }),
                                }
                              // if (Platform.isAndroid)
                              //   {
                              //     file = await PDFApi.loadNetwork(url),
                              //     openPDF(items[index], file),
                              //   }
                              // else if (Platform.isIOS)
                              //   {
                              //     file = await PDFApi.loadNetwork(url),
                              //     openPDF(items[index], file),
                              //   }
                              // else
                              //   {
                              //     print('encoded===>$encoded'),
                              //     html.window.open(encoded, "_blank"),
                              //     html.Url.revokeObjectUrl(encoded),
                              //     setState(() {
                              //       isLoadingPdf = false;
                              //     }),
                              //   }
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

  openPDF(items, file) async {
    setState(() {
      isLoadingPdf = false;
    });
    if (!Platform.isWindows) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SecondRoute(
                formData: items,
                file: file,
              )));
    }
    // else {
    //   String pdfName = items['description'].replaceAll(' ', '');
    //   final clickedButton = await FlutterPlatformAlert.showCustomAlert(
    //     windowTitle: 'Download PDF',
    //     text: 'Do you want to download $pdfName',
    //     positiveButtonTitle: "Yes",
    //     negativeButtonTitle: "No",
    //   );
    //   if (clickedButton == CustomButton.positiveButton) {
    //     setState(() {
    //       isLoadingPdf = true;
    //     });
    //   }
    // }
  }

  Widget _buildSearch() => SearchWidget(
        text: query,
        hintText: 'Search books',
        onChanged: (String value) {
          filterSearchResults(value);
        },
      );

  Future<void> registerUser() async {
      try {
        Map<String, dynamic> response =
            await PDFApi.registerUser(
                context,
                _emailController.text,
                _passwordController.text,
                selectedSubscription.toString());
        print(response);
        if (response['status_code'] == 200) {
          String name = _emailController.text.split('@')[0];
          String message = '$name registered';
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Success!',
              message:message,
              contentType: ContentType.success,
            ),
          );

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          setState(() {
            toggleView();
          });
        } else {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Warning!',
              message:response['message'],
              contentType: ContentType.warning,
            ),
          );

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }
      } catch (error) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message:error.toString(),
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
  }
  Future<void> processPaypalPayment(String subscriptionType) async {
    int total = 0;
    if(subscriptionType == 'trail'){
      total = 1;
    }else if (subscriptionType == 'one_week'){
      total = 7;
    }else if (subscriptionType == 'one_month'){
      total = 15;
    }else if (subscriptionType == 'one_year'){
      total = 40;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: true,
            clientId:
            "Afovgd_ltIk39SsZ-qBTm8TMtLMvf4GQoDH8W0nqqEZNRUSJIKA_0HBOs5R1x80OPiPydboCWPA0qC7J",
            secretKey:
            "EFwqxtdN3xC9fRG0npBg39zvFBTQJ5n_7Zwh76v1HAWckgZXikTJwIh6Fk2p0yEkTrHaVv3edH4fpl8o",
            returnURL: "https://samplesite.com/return",
            cancelURL: "https://samplesite.com/cancel",
            transactions:  [
              {
                "amount": {
                  "total": total,
                  "currency": "USD",
                },
              }
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              registerUser();
              print("onSuccess: $params");
            },
            onError: (error) {
              print("onError: $error");
            },
            onCancel: (params) {
              print('cancelled: $params');
            }),
      ),
    );
  }


}
