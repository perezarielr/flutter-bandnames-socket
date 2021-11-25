import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:flutter/cupertino.dart';
import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

// ignore: use_key_in_widget_constructors
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: "1", name: "Metallica", votes: 5),
    // Band(id: "2", name: "Queen", votes: 1),
    // Band(id: "3", name: "Heroes del Silencio", votes: 2),
    // Band(id: "4", name: "Radio Head", votes: 5),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on("active-bands", _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off("active-bands");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "BandNames",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)
                ? Icon(Icons.check_circle, color: Colors.blue[300])
                : Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
       //_showGraph(),
      body: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) => _bandTitle(bands[i])),
             
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add), elevation: 1, onPressed: addNewBand //(){}
          ),
    );
  }

  Widget _bandTitle(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit("delete-band", {"id": band.id}),
      background: Container(
          padding: EdgeInsets.only(left: 8.0),
          color: Colors.orange,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Delete Band",
              style: TextStyle(color: Colors.white),
            ),
          )),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text(
          "${band.votes}",
          style: TextStyle(fontSize: 20),
        ),
        onTap: () => socketService.socket.emit("vote-band", {"id": band.id}),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    if (!Platform.isAndroid) {
      // Android
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("New band name:"),
          content: TextField(
            controller: textController,
          ),
          actions: [
            MaterialButton(
                child: const Text("Add"),
                elevation: 5,
                textColor: Colors.blue,
                onPressed: () => addBandToList(textController.text))
          ],
        ),
      );
    }

    showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
              title: const Text("New band name:"),
              content: CupertinoTextField(
                controller: textController,
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text("Add"),
                  onPressed: () => addBandToList(textController.text),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(
                    "Dismiss",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ));
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit("add-band", {"name": name});
    }

    Navigator.pop(context);
  }
  // Mostrar grafica

  _showGraph() {

    Map<String, double> dataMap = {};

    for (var band in bands) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    }

    final List<Color> colorList = [
      Colors.red,
      Colors.red[200]!,
      Colors.green,
      Colors.green[200]!,
      Colors.blue,
      Colors.blue[200]!,
      Colors.yellow,
      Colors.yellow[200]!
    ];
    return Container(
      padding: const EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 200,
      child: PieChart(dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 2.5,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 20,
        //centerText: "HYBRID",
        legendOptions: LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
         //legendShape: _BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: false,
          showChartValues: true,
          showChartValuesInPercentage: true,
          showChartValuesOutside: false,
          decimalPlaces: 0,
        ),
        // gradientList: ---To add gradient colors---
        // emptyColorGradient: ---Empty Color gradient---
      ),
    );
  


  }


}
