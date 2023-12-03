import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:family_hundred/group.dart';
import 'package:family_hundred/mode.dart';
import 'package:family_hundred/question.dart';
import 'package:family_hundred/section.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

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
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Group> _groups = [];
  List<String> _members = [];
  List<Group> _selectedGroups = [];

  List<Section> _sections = [];

  Group? _activeGroup;
  int _groupATotalPoint = 0;
  int _groupBTotalPoint = 0;
  int _groupAWrongCount = 0;
  int _groupBWrongCount = 0;
  Mode mode = Mode.membering;
  String _inputtedAnswer = "";
  List<String> _correctInputtedAnswers = [];
  List<String> _spilledAnswers = [];
  final _inputController = TextEditingController();
  Section? _activeSection;
  Question? _activeQuestion;
  bool _showWrongOverlay = false;

  final confettiPlayer = AudioPlayer();
  final drumRollPlayer = AudioPlayer();
  final timerPlayer = AudioPlayer();
  final wrongAnswerPlayer = AudioPlayer();
  final correctAnswerPlayer = AudioPlayer();
  final unansweredPlayer = AudioPlayer();
  late List<AudioPlayer> players = [timerPlayer, wrongAnswerPlayer, correctAnswerPlayer, unansweredPlayer, confettiPlayer, drumRollPlayer];

  void randomizeMember() {
    _members.shuffle(Random());
    // Grouping per 4
    List<Group> groups = [];
    Group group = Group(name: "Group 1",members: [], totalScore: 0);
    int i = 0;
    for (var member in _members) {
      if (i % 4 == 0 && i > 0) {
        groups.add(group);
        group = Group(name: "Group ${groups.length}", members: [], totalScore: 0);
      }
      group.members.add(member);
      i++;
    }
    i = 0;
    for (var element in group.members) {
      groups[i].members.add(element);
      i++;
    }
    groups.sort((groupA, groupB) => groupA.members.length.compareTo(groupB.members.length));

    // Limit to only 8
    const maxGroupCount = 8;
    if (groups.length > maxGroupCount) {
      final exceededGroupCount = groups.length - maxGroupCount;
      for (var i = 0; i < exceededGroupCount; i++) {
        int ii = 0;
        for (var element in groups[groups.length - i - 1].members) {
          groups[ii].members.add(element);
          ii++;
        }
        groups.removeLast();
      }
    }

    groups.sort((groupA, groupB) => groupA.name.compareTo(groupB.name));
    
    setState(() {
      _groups = groups;
      
      SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString("groups", "${_groups.map((e) => e.toJson()).toList()}");
        });
    });
  }

  @override
  void initState() {

    drumRollPlayer.setUrl("asset://assets/drum_roll.mp3");
    confettiPlayer.setUrl("asset://assets/confetti.m4a");
    timerPlayer.setUrl("asset://assets/timer.mp3");
    wrongAnswerPlayer.setUrl("asset://assets/wrong_answer.mp3");
    correctAnswerPlayer.setUrl("asset://assets/correct_answer.mp3");
    unansweredPlayer.setUrl("asset://assets/unanswered_answer.mp3");

    // Load quizes
    DefaultAssetBundle.of(context).loadString("assets/family_hundred.json")
      .then((value) {
        
        final sectionJson = (json.decode(value) as List<dynamic>);
        final sections = sectionJson.map((e) => Section.fromJson(e)).toList();
        _sections = sections;
        SharedPreferences.getInstance()
            .then((prefs) {
              final savedSelectedGroupsString = prefs.getString("selectedGroups");
              if (savedSelectedGroupsString != null) {
                final savedSelectedGroupJson = (json.decode(savedSelectedGroupsString) as List<dynamic>);
                final savedSelectedGroups = savedSelectedGroupJson.map((e) => Group.fromJson(e)).toList();
                setState(() {
                  _selectedGroups = savedSelectedGroups;
                  mode = Mode.gameStarted;
                  _activeGroup = null;
                  _groupATotalPoint = 0;
                  _groupBTotalPoint = 0;
                  _groupAWrongCount = 0;
                  _groupBWrongCount = 0;
                  _correctInputtedAnswers = [];
                  _spilledAnswers = [];
                  _inputtedAnswer = "";
                  _inputController.clear();
                  _activeSection = _sections.firstOrNull;
                  _activeQuestion = _activeSection?.questions.firstOrNull;
                });
              }
            });
      });

    // Load members
    DefaultAssetBundle.of(context).loadString("assets/members.json")
      .then((value) {

        // Read from json and shuffle
        final members = (json.decode(value) as List<dynamic>).map((e) => e.toString()).toList();
        _members = members;

        SharedPreferences.getInstance()
          .then((prefs) {
            final savedGroupsString = prefs.getString("groups");
            if (savedGroupsString != null) {
              final savedGroupJson = (json.decode(savedGroupsString) as List<dynamic>);
              final savedGroups = savedGroupJson.map((e) => Group.fromJson(e)).toList();
              setState(() {
                _groups = savedGroups;
              });
            } else {
              randomizeMember();
            }
          });

      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family 100", style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                switch (mode) {
                  case Mode.membering:
                  return unstartedWidget();
                  case Mode.gameStarted:
                  return startedWidget();
                  case Mode.gameFinished:
                  return finishedWidget();
                }
              },
            ),
          ),
          _showWrongOverlay ? const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(left: 64, right: 64, bottom: 400, top: 64),
              child: Icon(Icons.clear, color: Colors.red, size: 900),
            ),
          ) : Container()
        ],
      )
    );
  }

  Widget finishedWidget() => Column(
    children: [
      Expanded(
        child: Builder(
          builder: (context) {
            Widget winnerWidget;
            Widget loserWidget;

            if (_groupATotalPoint > _groupBTotalPoint) {
              winnerWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_selectedGroups[0].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                  Text("$_groupATotalPoint", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 80))
                ],
              );

              loserWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_selectedGroups[1].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                  Text("$_groupBTotalPoint", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 80))
                ],
              );
            } else if (_groupBTotalPoint > _groupATotalPoint) {

              loserWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_selectedGroups[0].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                  Text("$_groupATotalPoint", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 80))
                ],
              );

              winnerWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_selectedGroups[1].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                  Text("$_groupBTotalPoint", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 80))
                ],
              );
            } else {
              winnerWidget = Container();
              loserWidget = Container();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LottieBuilder.asset("assets/winner.json"),
                      const SizedBox(width: 8),
                      winnerWidget,
                      const SizedBox(width: 80)
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text("VS", style: TextStyle(fontSize: 40)),

                const SizedBox(height: 16),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LottieBuilder.asset("assets/loser.json"),
                      const SizedBox(width: 8),
                      loserWidget,
                      const SizedBox(width: 80)
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      TextButton(onPressed: () { 
        setState(() {
          mode = Mode.membering;
          _selectedGroups = [];
          SharedPreferences.getInstance()
            .then((prefs) {
              prefs.remove("selectedGroups");
            });
        });
      }, child: const Text("New Game")),
      const SizedBox(height: 32),
    ],
  );

  Widget startedWidget() => Column(
    children: [
      Expanded(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 16),

                //////////////////////////////////////////////////////////
                ///
                /// Group A
                ///
                ///////////////////////////////////////////////////////////
                InkWell(
                  onTap: () {
                    setState(() {
                      _activeGroup = _selectedGroups[0] == _activeGroup ? null : _selectedGroups[0];
                    });
                  },
                  child: Column(
                    children: [
                      Text(_selectedGroups[0].name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: _activeGroup == _selectedGroups[0] ? Colors.green : Colors.grey.withOpacity(0.4))),

                      _groupATotalPoint > 0 ? Text("$_groupATotalPoint", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)) : Container(),
                      ...List.generate(_groupAWrongCount, (index) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Icon(Icons.clear, color: Colors.red),
                        );
                      })
                    ],
                  ),
                ),



                //////////////////////////////////////////////////////////
                ///
                /// Quizes
                ///
                ///////////////////////////////////////////////////////////
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Text(_activeQuestion?.question ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 35)),
                      const SizedBox(height: 16),
                      ...(_activeQuestion?.answers ?? []).mapIndexed((i, e) {
                        final showAnswer = _correctInputtedAnswers.firstWhereOrNull((element) => e.answer.toLowerCase().contains(element.toLowerCase())) != null ||
                           _spilledAnswers.firstWhereOrNull((element) => e.answer.toLowerCase().contains(element.toLowerCase())) != null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () async {
                              // TODO: If you want to submit answer by clicking, uncomment this
                              _inputtedAnswer = e.answer;
                              if (await onSubmitAnswer()) {
                                // await Future.wait(players.map((element) => element.pause() ));
                                // await Future.wait(players.map((element) => element.seek(Duration.zero) ));
                                // await unansweredPlayer.play();
                              }
                              
                              // TODO: If you dont want to submit answer by clicking, comment this
                              // setState(() {
                              //   _spilledAnswers.add(e.answer);
                              // });
                              // await Future.wait(players.map((element) => element.pause() ));
                              // await Future.wait(players.map((element) => element.seek(Duration.zero) ));
                              // await unansweredPlayer.play();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    top: 0,
                                    child: Center(child: Text("${i + 1}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                  ),
                                  showAnswer ? Center(
                                    child: Text(e.answer, style: const TextStyle(fontSize: 25),),
                                  ) : Container(),
                                  showAnswer ? Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(child: Text(e.point.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                  ) : Container()
                                ],
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                ),
                

                //////////////////////////////////////////////////////////
                ///
                /// Group B
                ///
                ///////////////////////////////////////////////////////////
                const SizedBox(width: 24),
                InkWell(
                  onTap: () {
                    setState(() {
                      _activeGroup = _selectedGroups[1] == _activeGroup ? null : _selectedGroups[1];
                    });
                  },
                  child: Column(
                    children: [
                      Text(_selectedGroups[1].name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: _activeGroup == _selectedGroups[1] ? Colors.green : Colors.grey.withOpacity(0.4))),

                      _groupBTotalPoint > 0 ? Text("$_groupBTotalPoint", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)) : Container(),
                      ...List.generate(_groupBWrongCount, (index) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Icon(Icons.clear, color: Colors.red),
                        );
                      })
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 32),
            (_activeSection?.questions.length ?? 0) > 1 ? ElevatedButton(onPressed: () {
              setState(() {
                _activeSection?.questions.removeAt(0);
                _activeQuestion = _activeSection?.questions.firstOrNull;
              });
            }, child: const Text("Next")) : Container(),
            const SizedBox(height: 16),
            _selectedGroups[0].isWinner == true || _selectedGroups[1].isWinner == true ? ElevatedButton(onPressed: () async {
              await Future.wait(players.map((element) => element.pause() ));
              await Future.wait(players.map((element) => element.seek(Duration.zero) ));
              await drumRollPlayer.play();
              setState(() {
                mode = Mode.gameFinished;
                _sections.removeAt(0);
                _activeSection = null;
                SharedPreferences.getInstance()
                  .then((value) {
                    value.setString("sections", "${_sections.map((e) => e.toJson()).toList()}");
                  });
              });

              await drumRollPlayer.pause();
              await drumRollPlayer.seek(Duration.zero);
              await confettiPlayer.play();
            }, child: const Text("End Game")) : Container(),
          ],
        ),
      ),

      Row(
        children: [
          const SizedBox(width: 32),
          // Expanded(
          //   child: TextField(
          //     onSubmitted: (inputtedValue) {
          //       _inputtedAnswer = inputtedValue;
          //       onSubmitAnswer();
          //     },
          //     controller: _inputController,
          //     decoration: const InputDecoration(
          //       hintText: "Input answer here"
          //     ),
          //     onChanged: (value) {
          //       _inputtedAnswer = value;
          //     },
          //   ),
          // ),
          TextButton(onPressed: () async { 
            setState(() {
              _showWrongOverlay = true;
            });
            await Future.wait(players.map((element) => element.pause() ));
            await Future.wait(players.map((element) => element.seek(Duration.zero) ));
            await wrongAnswerPlayer.seek(const Duration(milliseconds: 700));
            await wrongAnswerPlayer.play();
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              _showWrongOverlay = false;
            });
          }, child: const Text("Wrong")),
          const SizedBox(width: 32),
        ],
      ),
      const SizedBox(height: 120)
    ],
  );

  Future<bool> onSubmitAnswer() async {
    if (_activeGroup == null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please choose active group first")));
      return false;
    }
    if (_inputtedAnswer.isEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please input the answer first")));
      return false;
    }
    if (_correctInputtedAnswers.contains(_inputtedAnswer)) {
      _inputController.clear();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please input different answer")));
      return false;
    }
    final correctAnswer = _sections[0].questions[0].answers.firstWhereOrNull((element) => element.answer.toLowerCase().contains(_inputtedAnswer.toLowerCase()));
    bool isAnswerCorrect = correctAnswer != null;
    _inputController.clear();

    if (!_spilledAnswers.contains(correctAnswer?.answer)) {
      setState(() {
        _correctInputtedAnswers.add(_inputtedAnswer);
        if (_activeGroup == _selectedGroups[0]) {
          if (isAnswerCorrect) {
            _groupATotalPoint += correctAnswer.point;
            _activeGroup?.totalScore = _groupATotalPoint;
          } else {
            _activeGroup = _selectedGroups[1];
            _groupAWrongCount += 1;
          }
        } else if (_activeGroup == _selectedGroups[1]) {
          if (isAnswerCorrect) {
            _groupBTotalPoint += correctAnswer.point;
            _activeGroup?.totalScore = _groupBTotalPoint;
          } else {
            _activeGroup = _selectedGroups[0];
            _groupBWrongCount += 1;
          }
        }
        
        _selectedGroups[0].isWinner = _selectedGroups[0].totalScore > _selectedGroups[1].totalScore;
        _selectedGroups[1].isWinner = _selectedGroups[1].totalScore > _selectedGroups[0].totalScore;
      });
      _groups.firstWhereOrNull((element) => element.name == _selectedGroups[0].name)?.totalScore = _selectedGroups[0].totalScore;
      _groups.firstWhereOrNull((element) => element.name == _selectedGroups[1].name)?.totalScore = _selectedGroups[1].totalScore;
      _groups.firstWhereOrNull((element) => element.name == _selectedGroups[0].name)?.isWinner = _selectedGroups[0].totalScore > _selectedGroups[1].totalScore;
      _groups.firstWhereOrNull((element) => element.name == _selectedGroups[1].name)?.isWinner = _selectedGroups[1].totalScore > _selectedGroups[0].totalScore;

      SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString("groups", "${_groups.map((e) => e.toJson()).toList()}");
        });
      if (isAnswerCorrect) {
        await Future.wait(players.map((element) => element.pause() ));
        await Future.wait(players.map((element) => element.seek(Duration.zero) ));
        await correctAnswerPlayer.play();
      } else {
        await Future.wait(players.map((element) => element.pause() ));
        await Future.wait(players.map((element) => element.seek(Duration.zero) ));
        await wrongAnswerPlayer.seek(const Duration(milliseconds: 700));
        await wrongAnswerPlayer.play();
      }
    }
    return true;
  }

  Widget unstartedWidget() => Column(
    children: [
      Expanded(
        flex: 7,
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              final children = <Widget>[];
              List<Widget> rowChildren = <Widget>[];
              _groups.forEachIndexed((i, group) {
                
                if (i % 4 == 0 && i > 0) {
                  children.add(Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,children: rowChildren));
                  rowChildren = [];
                }
                rowChildren.add(Expanded(
                  child: InkWell(
                    onTap: group.isWinner == false ? null : () {
                      setState(() {
                        if (_selectedGroups.contains(group)) {
                          _selectedGroups.remove(group);
                        } else {
                          if (_selectedGroups.length >= 2) {
                            _selectedGroups.removeLast();
                          }
                          _selectedGroups.add(group);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(color: _selectedGroups.contains(group) ? Colors.green.shade100.withOpacity(0.8) : Colors.transparent),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: group.isWinner == false ? Colors.grey.withOpacity(0.3) : Colors.black)),
                          ...group.members.map((e) {
                            return Text(e, style: TextStyle(fontSize: 22, color: group.isWinner == false ? Colors.grey.withOpacity(0.3) : Colors.black));
                          }),
                          const SizedBox(height: 32),
                        ],
                      )
                    ),
                  ),
                ));
              });
              children.add(Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,children: rowChildren));
              children.add(const SizedBox(height: 16));
              children.add(ElevatedButton(onPressed: () {
                randomizeMember();
                }, child: const Text("Randomize")));
              return Column(
                children: children,
              );
            },
          ),
        ),
      ),

      const Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_selectedGroups.isNotEmpty ? _selectedGroups.first.name : "", style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          _selectedGroups.length > 1 ? const Text("VS", style: TextStyle(fontSize: 90)) : Container(),
          const SizedBox(width: 16),
          Text(_selectedGroups.length > 1 ? _selectedGroups.last.name : "", style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 16),
      _selectedGroups.length > 1 ? ElevatedButton(onPressed: () { 
        setState(() {
          mode = Mode.gameStarted;
          _activeGroup = null;
          _groupATotalPoint = 0;
          _groupBTotalPoint = 0;
          _groupAWrongCount = 0;
          _groupBWrongCount = 0;
          _correctInputtedAnswers = [];
          _spilledAnswers = [];
          _inputtedAnswer = "";
          _inputController.clear();
          _activeSection = _sections.firstOrNull;
          _activeQuestion = _activeSection?.questions.firstOrNull;
          SharedPreferences.getInstance()
            .then((prefs) {
              prefs.setString("selectedGroups", "${_selectedGroups.map((e) => e.toJson()).toList()}");
            });
        });
      }, child: const Text("Start")) : Container(),
      const Spacer(),
      
      // Row(
      //   children: [
      //     ElevatedButton(onPressed: () async {
      //       await Future.wait(players.map((element) => element.pause() ));
      //       await Future.wait(players.map((element) => element.seek(Duration.zero) ));
      //       await wrongAnswerPlayer.seek(const Duration(milliseconds: 700));
      //       await wrongAnswerPlayer.play();
      //     }, child: Text("Wrong")),
      //     ElevatedButton(onPressed: () async {
      //       await Future.wait(players.map((element) => element.pause() ));
      //       await Future.wait(players.map((element) => element.seek(Duration.zero) ));
      //       await correctAnswerPlayer.play();
      //     }, child: Text("Correct")),
      //     ElevatedButton(onPressed: () async {
      //       await Future.wait(players.map((element) => element.pause() ));
      //       await Future.wait(players.map((element) => element.seek(Duration.zero) ));
      //       await timerPlayer.seek(const Duration(milliseconds: 700));
      //       await timerPlayer.play();
      //     }, child: Text("Timer")),
      //     ElevatedButton(onPressed: () async {
      //       await Future.wait(players.map((element) => element.pause() ));
      //       await Future.wait(players.map((element) => element.seek(Duration.zero) ));
      //       await unansweredPlayer.play();
      //     }, child: Text("Unanswered")),
      //     ElevatedButton(onPressed: () async {
      //       await Future.wait(players.map((element) => element.pause() ));
      //       await Future.wait(players.map((element) => element.seek(Duration.zero) ));
      //       await confettiPlayer.play();
      //     }, child: Text("Confetti")),
      //     ElevatedButton(onPressed: () async {
      //       await Future.wait(players.map((element) => element.pause() ));
      //       await Future.wait(players.map((element) => element.seek(Duration.zero) ));
      //       await drumRollPlayer.play();
      //     }, child: Text("Drum Roll"))
      //   ],
      // ),
      const SizedBox(height: 32)
    ],
  );
}
