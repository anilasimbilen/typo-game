import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'GameState.dart';
import 'package:marquee/marquee.dart';
import 'dart:async';
import 'dart:convert';
import "Routes.dart";
import "UserEntry.dart";
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Typo',
      theme: CupertinoThemeData(),
      home: MyHomePage(title: 'Typo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GameState _currentState = GameState.LOBBY;
  int score = 0;
  List<String> lorem =
      "consectetur adipiscing elit Morbi ut felis finibus nulla fermentum gravida donec commodo fermentum consectetur Nulla pharetra dignissim orci, vel convallis mi. Praesent eu urna vitae ligula elementum ultricies sit amet id lacus. Integer sollicitudin, arcu sed volutpat sagittis, enim magna eleifend purus, sed rutrum velit sapien ac ligula. Nullam in libero magna. Duis sit amet nisl massa. Ut id congue lorem. Donec consequat augue enim, ut hendrerit sapien volutpat sit amet. Maecenas non arcu at quam viverra eleifend vel ac nunc.Aenean tempor lectus sed felis tempor, nec posuere sapien fringilla. Pellentesque tincidunt tincidunt sem. Integer scelerisque nibh vel justo faucibus sagittis. In non diam at ante suscipit elementum ut eget mi. Mauris consequat ex quis nisi bibendum lobortis. In maximus odio felis, at auctor mauris commodo et. Etiam consequat lacinia libero sed convallis. Duis nisl nisl, luctus quis dignissim ut, elementum quis quam. Vestibulum id quam varius, porta risus quis, tincidunt eros."
          .toLowerCase()
          .replaceAll(".", " ")
          .replaceAll(",", "")
          .split(" ");
  String prefix = "                           lorem ipsum dolor sit amet";
  String loremText;
  int lastTyped;
  int maxTime = 4000; // in millis
  String userName = "";
  bool isSent = false;
  var child;
  var table = Table(
    children: [
      TableRow(children: [Text("Lütfen bekleyiniz")])
    ],
  );

  void updateLastTypedAt() {
    this.lastTyped = DateTime.now().millisecondsSinceEpoch;
  }

  void refreshGame() {
    setState(() {
      _currentState = GameState.LOBBY;
      score = 0;
      lorem.shuffle();
      loremText = '$prefix ${lorem.join(" ")}';
      updateLastTypedAt();
      isSent = false;
    });
  }

  void onStartPressed() {
    refreshGame();
    setState(() {
      _currentState = GameState.PLAYING;
    });
    var timer = Timer.periodic(new Duration(seconds: 1), (timer) {
      int now = DateTime.now().millisecondsSinceEpoch;
      if (_currentState == GameState.PLAYING) {
        if (now - lastTyped >= maxTime) {
          setState(() {
            _currentState = GameState.GAME_OVER;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  onInputChange(String value) {
    String trimmed = this.loremText.trimLeft();

    updateLastTypedAt();
    if (trimmed.indexOf(value) != 0) {
      setState(() {
        _currentState = GameState.GAME_OVER;
      });
    } else {
      setState(() {
        score++;
      });
    }
  }

  Widget lobbyCreator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("Hazır mısın?"),
        Container(
          margin: EdgeInsets.only(top: 10),
          child: CupertinoButton(
            child: Text("Başla"),
            onPressed: onStartPressed,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 10),
          child: CupertinoButton(
            child: Text("Skor tablosunu göster."),
            onPressed: onScoreClick,
          ),
        ),
      ],
    );
  }

  Widget playing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Container(
              height: 40,
              child: Text("Skor: $score"),
            ),
          ],
        ),
        Container(
          height: 40,
          child: Marquee(
            text: loremText,
            style: TextStyle(fontSize: 24, letterSpacing: 2),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 20.0,
            velocity: 125,
            startPadding: 0,
            accelerationDuration: Duration(seconds: 20),
            accelerationCurve: Curves.ease,
            decelerationDuration: Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        CupertinoTextField(
          maxLines: 1,
          autofocus: true,
          autocorrect: false,
          onChanged: onInputChange,
        ),
        CupertinoButton(
          child: Text("Geri"),
          onPressed: refreshGame,
        )
      ],
    );
  }

  onScoreClick() async {
    var tbl = await scoreTable();
    setState(() {
      _currentState = GameState.BROWSING_TABLE;
      this.table = tbl;
    });
  }

  scoreTable() async {
    print("inside scoreTable");
    var response = await http.get("https://typo-api.herokuapp.com/users",
        headers: {
          "Content-Type": "application/json",
          "accept": "application/json"
        });
    var respJson = jsonDecode(response.body);
    List<UserEntry> entries = new List();
    print("entries initialized");
    respJson.map((item) {
      return (Map<String, dynamic>.from(item));
      //UserEntry.fromJson(item);
    }).forEach((item) {
      entries.add(UserEntry.fromJson(item));
    });
    List<TableRow> rows = [
      TableRow(
          children: [
            Container(
              alignment: Alignment(0.0, 0.0),
              child: Text("İsim"),
            ),
            Container(
              alignment: Alignment(0.0, 0.0),
              child: Text("Skor"),
            ),
          ]
      )
    ];

    entries.forEach((element) {
      print(element);
      rows.add(TableRow(children: [
        Container(
          alignment: Alignment(0.0, 0.0),
          child: Text(element.name),
        ),
        Container(
          alignment: Alignment(0.0, 0.0),
          child: Text(element.score.toString()),
        ),
      ]));
    });
    return Table(
      border: TableBorder.all(),
      children: rows,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    );
  }

  Widget gameOver() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "Skorunuz $score",
          style:
              TextStyle(fontSize: 24, fontFamily: "Helvetica", wordSpacing: 2),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CupertinoButton(
              padding: EdgeInsets.all(5),
              child: Text("Yeniden Başla"),
              onPressed: refreshGame,
            ),
            CupertinoButton(
              child: Text("Skorumu tabloya gönder"),
              onPressed: () {
                if (isSent) {
                  showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            height: 200,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("Skorunuz tabloya kaydoldu."),
                                  CupertinoButton(
                                    child: Text("Geri"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                  return;
                }
                showCupertinoDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20.0)), //this right here
                        child: Container(
                          height: 200,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                      hintText: 'Tabloda görünecek isim'),
                                  onChanged: (String val) {
                                    this.userName = val;
                                  },
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      CupertinoButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "İptal",
                                        ),
                                      ),
                                      CupertinoButton(
                                        onPressed: () async {
                                          var res = await http
                                              .post(Routes.POST_SCORE, body: {
                                            'userName': userName,
                                            'score': score.toString(),
                                            'text': loremText
                                          });
                                          bool successMessage =
                                              jsonDecode(res.body)["success"];
                                          if (successMessage) {
                                            setState(() {
                                              isSent = true;
                                            });
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        child: Text(
                                          "Gönder",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case GameState.LOBBY:
        child = lobbyCreator();
        break;
      case GameState.PLAYING:
        child = playing();
        break;
      case GameState.GAME_OVER:
        child = gameOver();
        break;
      case GameState.BROWSING_TABLE:
        child = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            table,
            Container(
              margin: EdgeInsets.only(top: 20),
              child: CupertinoButton(
                  child: Text("Geri"),
                  onPressed: () {
                    setState(() {
                      _currentState = GameState.LOBBY;
                    });
                  }),
            )
          ],
        );
        break;
      default:
        child = lobbyCreator();
    }

    return CupertinoPageScaffold(
      child: Center(child: child),
    );
  }
}
