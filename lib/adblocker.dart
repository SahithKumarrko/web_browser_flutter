import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webpage_dev_console/models/AdBlockerModel.dart';
import 'package:webpage_dev_console/objectbox.g.dart';

class AdBlockerImpl {
  List<String> paths = [
    'assets/blocklist/filter_blocklist1.txt',
    'assets/blocklist/filter_blocklist2.txt',
    'assets/blocklist/filter_blocklist3.txt',
    'assets/blocklist/filter_blocklist4.txt'
  ];
  Store? _store;
  Box<AdblockerModel>? box;
  initializeStore(Function s) async {
    Directory dir = await getApplicationDocumentsDirectory();
    s(dir.path + "/objectbox");
    print(dir.path + "/objectbox");
    _store = Store(getObjectBoxModel(), directory: dir.path + "/objectbox");
    box = _store?.box<AdblockerModel>();
  }

  Future<String> loadAsset(String path) async {
    return await rootBundle.loadString(path);
  }

  printDate(var op) {
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd hh:mm:ss');
    String formattedDate = formatter.format(now);
    log("$op : $formattedDate");
  }

  Future init(Function sets) async {
    List<String> hosts = [];
    printDate("Init");
    sets("Init");
    var rec = box?.count() ?? 0;
    if (rec > 0) {
      printDate("Completed ");
      sets("completed");
    } else {
      for (var i in paths) {
        String res = await loadAsset(i);
        printDate("Reading $i");
        sets("Reading $i");
        hosts.addAll(res.split("\n"));
        printDate("Completed :: Len ${hosts.length}");
        sets("Completed :: Len ${hosts.length}");
      }
      printDate("Creating OB");
      sets("COB");
      box?.removeAll();
      _store?.runInTransaction(
          TxMode.write,
          () => hosts.forEach((element) {
                box?.put(AdblockerModel(host: element));
              }));
      printDate("Completed : ${box?.count()} ");
      sets("completed COB");
    }
  }

  Future fetch(String s, Function sets) async {
    printDate("Getting $s");
    sets("Getting $s");
    var res = box
        ?.query(AdblockerModel_.host.equals(s))
        .build()
        .find()
        .map((e) => e.host);
    printDate("got Result $res");
    sets("Got Result $res");
    _store?.close();
  }
}

void main(List<String> args) {
  runApp(Adblocker());
}

class Adblocker extends StatefulWidget {
  const Adblocker({Key? key}) : super(key: key);

  @override
  _AdblockerState createState() => _AdblockerState();
}

class _AdblockerState extends State<Adblocker> {
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
  }

  String val = "";
  update(String s) {
    this.setState(() {
      val = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                Container(
                  child: TextButton(
                    child: Text("read"),
                    onPressed: () async {
                      AdBlockerImpl abi = AdBlockerImpl();
                      abi.initializeStore(update);
                      await Future.delayed(Duration(seconds: 3));
                      print("Initializing adblocker");
                      await abi.init(update);
                      await abi.fetch(
                          "zzzyyzzzyyyzyyzyyyzzyyzyzzzzzzzzyyzzyyyyyzyzyyzzyzpol7196.cmkaarten.nl",
                          update);
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text("$val"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
