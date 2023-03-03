import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'sql_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

late List<Notes> temp;
Notes editCurrentNotes = Notes(content: '', id: 0, title: '');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  List<String> item = [
    "Clients",
    "Designer",
    "Developer",
    "Director",
    "Employee",
    "Manager",
    "Worker",
    "Owner"
  ];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //final dbHelper = SQLHelper.instance;
  late BannerAd _ad;
  // TODO: Add _isAdLoaded
  bool _isAdLoaded = false;
  String bannerAdsId = 'ca-app-pub-3940256099942544/4411468910';
  /*String bannerAdsId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';*/
  /*
  String bannerAdsId = Platform.isAndroid
      ? "ca-app-pub-9860072337130869/5088892533"
      : "ca-app-pub-9860072337130869/8724092620";
  */

  static int page = 0; //0,1
  List<Notes> noteList = [];
  late Future<List<Notes>> _future;

  static final TextEditingController _controller = new TextEditingController();
  static final TextEditingController _controller2 = new TextEditingController();

  static int autoIncreaseInt = 6; //0,1
  ThemeMode _themeMode = ThemeMode.light;
  static const THEME_STATUS = "THEMESTATUS";
  static bool _isDarkMode = false;

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    super.dispose();
    // TODO: Dispose a BannerAd object
    //_ad.dispose();
    BackButtonInterceptor.remove(myInterceptor);
  }

  @override
  void initState() /*async*/ {
    super.initState();
    Wakelock.enable();
    BackButtonInterceptor.add(myInterceptor);
    temp = List<Notes>.filled(0, Notes(id: 0, title: "", content: ""),
        growable: true);
    /*temp.addAll([
      Notes(id: 1, title: "Hello", content: "World"),
      Notes(id: 2, title: "Flutter", content: "Dart"),
      Notes(id: 3, title: "Computer", content: "Science"),
      Notes(id: 4, title: "Data", content: "Structures"),
      Notes(id: 5, title: "Super", content: "Man")
    ]);*/
    _future = dbHelper.getNotesList();
    /*SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(THEME_STATUS) != null) {
      if (prefs.getBool(THEME_STATUS)!)
        _themeMode = ThemeMode.dark;
      else
        _themeMode = ThemeMode.light;

      _isDarkMode = prefs.getBool(THEME_STATUS)!;
    }*/
    setDarkTheme(false, true);

    // TODO: Create a BannerAd instance
    /*_ad = BannerAd(
      adUnitId: bannerAdsId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: {
          // Releasad resource when it fails to load
          ad.dispose();

          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );
    // TODO: Load an ad
    _ad.load();*/
  }

  setDarkTheme(bool value, bool isInit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (isInit) {
      if (prefs.getBool(THEME_STATUS) != null) {
        if (prefs.getBool(THEME_STATUS)!)
          _themeMode = ThemeMode.dark;
        else
          _themeMode = ThemeMode.light;

        _isDarkMode = prefs.getBool(THEME_STATUS)!;
      }
    } else {
      prefs.setBool(THEME_STATUS, value);
      _isDarkMode = value;
      if (value)
        changeTheme(ThemeMode.dark);
      else
        changeTheme(ThemeMode.light);
    }
  }

  void backToNotesList() {
    setState(() {
      saveNote();
      page -= 1;
    });
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (page == 0) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      backToNotesList();
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > noteList.length) newIndex = noteList.length;
    if (oldIndex < newIndex) newIndex -= 1;

    setState(() {
      final Notes item = noteList[oldIndex];
      noteList.removeAt(oldIndex);

      print(item.title);
      noteList.insert(newIndex, item);
    });
  }

  void sorting() {
    setState(() {
      widget.item.sort();
    });
  }

  void saveNote() {
    if (_controller.text.isNotEmpty || _controller2.text.isNotEmpty) {
      editCurrentNotes.content = _controller2.text;
      editCurrentNotes.title = _controller.text;
      dbHelper.insertNotes(editCurrentNotes);
      setState(() {
        autoIncreaseInt += 1;
      });
    }
  }

  void deleteNote(int id) {
    dbHelper.deleteNote(id);
    setState(() {
      page -= 1;
    });
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget tempReturn;
    if (page == 0)
      tempReturn = getNotesListPage(context);
    else
      tempReturn = getNotesPage(context);

    return MaterialApp(
      home: tempReturn,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
    );
  }

  /*(Widget getNotePage(BuildContext context) {
    return null;
  }*/

  Widget getNotesListPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.blue,
        title: Text(''),
        actions: [
          IconButton(
            onPressed: () {
              setDarkTheme(!_isDarkMode, false);
            },
            icon: Icon(
              !_isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: Container(
          padding: EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              SizedBox(
                  height: MediaQuery.of(context).size.height * 0.882,
                  child: FutureBuilder(
                      future: _future,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.data == null) {
                          return Text('');
                        } else {
                          if (snapshot.data.length < 1) {
                            return Center(
                              child: Text(''),
                            );
                          }
                          noteList = snapshot.data;
                          return ReorderableListView(
                            onReorder: _onReorder,
                            children: List.generate(
                              snapshot.data.length,
                              (index) {
                                return ListTile(
                                  key: Key('$index'),
                                  title: Flexible(
                                    child: new Container(
                                      child: new Text(
                                        snapshot.data[index].title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  subtitle: Flexible(
                                    child: new Container(
                                      child: new Text(
                                        snapshot.data[index].content,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      editCurrentNotes.content =
                                          snapshot.data[index].content;
                                      editCurrentNotes.title =
                                          snapshot.data[index].title;
                                      editCurrentNotes.id =
                                          snapshot.data[index].id;
                                      _controller.text =
                                          snapshot.data[index].title;
                                      _controller2.text =
                                          snapshot.data[index].content;
                                      page = 1;
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        }
                      }))
            ],
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.text = "";
            _controller2.text = "";
            editCurrentNotes.content = '';
            editCurrentNotes.title = '';
            editCurrentNotes.id = 0;

            page = 1;
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget getNotesPage(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          //resizeToAvoidBottomInset: false,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
              ),
              onPressed: () {
                backToNotesList();
              },
            ),
            title: Text(""),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  deleteNote(editCurrentNotes.id);
                },
                icon: Icon(
                  Icons.delete,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.share,
                ),
              ),
              /*new PopupMenuButton<String>(
                  //offset: Offset(500, 500),
                  //elevation: 20,
                  icon: Icon(
                    Icons.abc,
                  ),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        new PopupMenuDivider(height: 1.0),
                        new PopupMenuItem<String>(
                            value: 'delete',
                            child: Icon(
                              Icons.delete,
                            )),
                        new PopupMenuDivider(height: 1.0),
                        new PopupMenuItem<String>(
                          value: 'share',
                          child: Icon(
                            Icons.share,
                          ),
                        ),
                      ],
                  onSelected: (String value) {
                    if (value == 'delete') {
                      deleteNote(editCurrentNotes.id);
                    } else if (value == 'share') {
                      //Share.share(_controller.text + "\n" + _controller2.text);
                    }
                  }),
              SizedBox(width: 20),
              SizedBox(
                width: 20,
              ),*/
            ],
          ),
          body: Container(
            margin: new EdgeInsets.all(4.0),
            child: SingleChildScrollView(
                // new line
                child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _controller,
                ),
                TextFormField(
                  autofocus: true,
                  controller: _controller2,
                  onChanged: (text) {},
                  maxLines: 10,
                  minLines: 3,
                ),
              ],
            )),
          ),
        ));
  }
}

class dbHelper {
  static Future<List<Notes>> getNotesList() {
    return Future.value(temp);
  }

  static insertNotes(Notes note) {
    if (temp.where((element) => element.id == note.id).length > 0)
      temp[temp.indexWhere((element) => element.id == note.id)] = note;
    else
      temp.add(note);
  }

  static void deleteNote(int id) {
    temp.removeWhere((item) => item.id == id);
  }
}
