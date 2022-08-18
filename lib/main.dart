import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:CoffeeRide/baza.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Ride',
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: "kalam"),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initial Selected Value
  String dropdownvalue = 'Kawa';
  int _counter = 0;
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  var cart = FlutterCart();
  bool _connected = false;
  late List<BluetoothDevice> _devices = [];
  late List<BluetoothDevice> _selectedPrinter = [];
  String tips = 'no service connected';

  void _startScanDevices() async {
    setState(() {
      _devices = [];
    });
    bluetoothPrint.startScan(timeout: const Duration(seconds: 2));

    bool? isConnected = await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;
    setState(() {});
    if (isConnected != null && isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  static const Map<String, String> items = {
    'Kawa': '10',
    'Ciastko': '15',
    'Napoj': '15',
    'Lody': '19',
    'Piwo': '12',
    'Wino': '16',
    'Podplomyk': '25',
    'Drink': '22',
    'Przekaska': '20',
    'Inne': '10',
  };
  void _printSummary() async {
    Map<String, dynamic> config = {};
    List<LineText> list = [];
    Map<String, num> all_items = {
      'Kawa': 0,
      'Ciastko': 0,
      'Napoj': 0,
      'Lody': 0,
      'Piwo': 0,
      'Wino': 0,
      'Podplomyk': 0,
      'Drink': 0,
      'Przekaska': 0,
      'Inne': 0,
    };
    var x = await DatabaseHelper.instance.fetchData(
        _controller.selectedRange?.startDate,
        _controller.selectedRange?.endDate);
    for (var i = 0; i < x.length; i++) {
      all_items[x[i]["name"]] =
          x[i]["count"] * x[i]["price"] + all_items[x[i]["name"]];
    }
    var values = all_items.values;
    var result = values.reduce((sum, element) => sum + element);
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Podsumowanie',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content:
            '${DateFormat('dd-MM-yyyy').format(_controller.selectedRange?.startDate as DateTime)}  do  ${DateFormat('dd-MM-yyyy').format(_controller.selectedRange?.endDate as DateTime)}',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content:
            '${JsonEncoder.withIndent('  ').convert(all_items).replaceAll("{\n", "").replaceAll("}", "").replaceAll('"', "").replaceAll(",", "").replaceAll("\nK", "").replaceAll("\n", " zl\n")} Suma: $result zl',
        weight: 0,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1));
    await bluetoothPrint.printReceipt(config, list);
  }

  void _printReceipt() async {
    Map<String, dynamic> config = {};
    List<LineText> list = [];
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content:
            'COFFEE RIDE\nUl. Kolejowa 6\n57-540 Ladek Zdroj\nNIP: 8811468089',
        weight: 0,
        align: LineText.ALIGN_LEFT,
        linefeed: 1));
    ByteData data = await rootBundle.load("lib/assets/logo.jpg");
    List<int> imageBytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    String base64Image = base64Encode(imageBytes);

    list.add(LineText(
        type: LineText.TYPE_IMAGE,
        content: base64Image,
        align: LineText.ALIGN_CENTER,
        width: 150,
        height: 150, // pass desired width
        size: 1,
        weight: 1,
        linefeed: 1));
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Zamowienie',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(linefeed: 1));
    for (var i = 0; i < products.length; i++) {
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content:
              '${products[i]["Nazwa"]} ${products[i]["Cena"]}zl * ${products[i]["Ilość"]} szt.= ${double.parse(products[i]["Ilość"].replaceAll(",", ".")) * double.parse(products[i]["Cena"].replaceAll(",", "."))}zl',
          weight: 0,
          align: LineText.ALIGN_RIGHT,
          linefeed: 1));
    }
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Suma: $sum zl',
        weight: 1,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1));

    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Dziekujemy!\n Zyczymy smacznego! :)',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(linefeed: 1));
    DatabaseHelper.instance.yoinsert(products);
    await bluetoothPrint.printReceipt(config, list);
    await Future.delayed(Duration(seconds: 1));

    clear_list();
  }

  void _decrementCounter() {
    if (int.parse(myCounter.text) < 1) {
      return;
    }
    setState(() {
      _counter--;
      myCounter.text =
          (int.parse(myCounter.text.replaceAll(",", ".")) - 1).toString();
    });
  }

  void _decrementPrice() {
    setState(() {
      myController.text = (int.parse(myController.text) - 1).toString();
    });
  }

  void _incrementPrice() {
    setState(() {
      myController.text = (int.parse(myController.text) + 1).toString();
    });
  }

  void _incrementCounter() {
    setState(() {
      myCounter.text =
          (int.parse(myCounter.text.replaceAll(",", ".")) + 1).toString();
    });
  }

  List lista = [];
  List products = [];
  final DateRangePickerController _controller = DateRangePickerController();
  late String _date =
      DateFormat('dd, MMMM yyyy').format(DateTime.now()).toString();
  final myController = TextEditingController();
  final myCounter = TextEditingController();
  final placeholder = 0;
  var sum = 0.0;

  void add() {
    var details = {'Nazwa': '', 'Cena': '', 'Ilość': ''};
    var x = details;
    sum = 0.0;
    x["Nazwa"] = dropdownvalue.toString();
    x["Cena"] = myController.text;
    x["Ilość"] = myCounter.text;
    products.add(x);
    print("prod $products");
    x = details;
    lista.add(
        "$dropdownvalue ${myController.text}zl * ${myCounter.text}szt = ${double.parse(myController.text.replaceAll(",", ".")) * double.parse(myCounter.text.replaceAll(",", "."))}zl");

    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
            backgroundColor: const Color.fromRGBO(160, 69, 14, 1),
            title: Text(
              "Dodano!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 50 * MediaQuery.of(context).size.width / 1080,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
                style: TextStyle(
                    fontSize: 50 * MediaQuery.of(context).size.width / 1080,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                "$dropdownvalue ${myController.text}zł * ${myCounter.text} szt = ${(double.parse(myController.text.replaceAll(",", ".")) * double.parse(myCounter.text.replaceAll(",", "."))).toStringAsFixed(2)}zł")));
    for (var i = 0; i < products.length; i++) {
      sum += double.parse(products[i]["Cena"]) *
          double.parse(products[i]["Ilość"]);
      print(products);
    }
  }

  void selectionChanged(DateRangePickerSelectionChangedArgs args) {
    SchedulerBinding.instance.addPostFrameCallback((duration) {
      setState(() {
        _date = DateFormat('dd, MMMM, yyyy').format(args.value).toString();
        print("tutaj ${_date}");
      });
    });
  }

  void displayListOrders() async {
    Map<String, num> all_items = {
      'Kawa': 0,
      'Ciastko': 0,
      'Napoj': 0,
      'Lody': 0,
      'Piwo': 0,
      'Wino': 0,
      'Podplomyk': 0,
      'Drink': 0,
      'Przekaska': 0,
      'Inne': 0,
    };
    var x = await DatabaseHelper.instance.fetchData(
        _controller.selectedRange?.startDate,
        _controller.selectedRange?.endDate);
    for (var i = 0; i < x.length; i++) {
      all_items[x[i]["name"]] =
          x[i]["count"] * x[i]["price"] + all_items[x[i]["name"]];
    }

    var values = all_items.values;
    var result = values.reduce((sum, element) => sum + element);
    print(JsonEncoder.withIndent('  ').convert(all_items));

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
            backgroundColor: const Color.fromRGBO(160, 69, 14, 1),
            title: Text(
              "Podsumowanie",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 50 * MediaQuery.of(context).size.width / 1080,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              ("${DateFormat('dd-MM-yyyy').format(_controller.selectedRange?.startDate as DateTime)}  do  ${DateFormat('dd-MM-yyyy').format(_controller.selectedRange?.endDate as DateTime)} ${JsonEncoder.withIndent('  ').convert(all_items).replaceAll("{\n", "").replaceAll("}", "").replaceAll('"', "").replaceAll(",", "").replaceAll("\nK", "").replaceAll("\n", " zl\n")} Suma: $result zl"),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 50 * MediaQuery.of(context).size.width / 1080,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )));
  }

  void displayOrders() async {
    // var x = await DatabaseHelper.instance.fetchData();
    // print(x);
    final textScale = MediaQuery.of(context).size.width / 1080;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              SfDateRangePicker(
                  monthViewSettings:
                      const DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
                  onSelectionChanged:
                      (DateRangePickerSelectionChangedArgs args) {
                    if (args.value is PickerDateRange) {
                      final DateTime rangeStartDate = args.value.startDate;
                      final DateTime rangeEndDate = args.value.endDate;
                    } else if (args.value is DateTime) {
                      final DateTime selectedDate = args.value;
                    } else if (args.value is List<DateTime>) {
                      final List<DateTime> selectedDates = args.value;
                    } else {
                      final List<PickerDateRange> selectedRanges = args.value;
                    }
                    final startDate = args.value.startDate;
                  },
                  controller: _controller,
                  view: DateRangePickerView.month,
                  selectionMode: DateRangePickerSelectionMode.range),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      displayListOrders();
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 * 0.5,
                      height: MediaQuery.of(context).size.height / 15 * 0.6,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(134, 51, 1, 1.0),
                        //background color of dropdown button
                        border: Border.all(color: Colors.black38, width: 3),
                        //border of dropdown button
                        borderRadius: BorderRadius.circular(50),
                        //border raiuds of dropdown button
                        boxShadow: const <BoxShadow>[
                          //apply shadow on Dropdown button
                          BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.57),
                              //shadow for button
                              blurRadius: 5) //blur radius of shadow
                        ],
                      ),
                      child: Text(
                        "Pokaż",
                        style: TextStyle(
                            fontSize: 40 * textScale, color: Colors.white),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _printSummary();
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 * 0.5,
                      height: MediaQuery.of(context).size.height / 15 * 0.6,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(134, 51, 1, 1.0),
                        //background color of dropdown button
                        border: Border.all(color: Colors.black38, width: 3),
                        //border of dropdown button
                        borderRadius: BorderRadius.circular(50),
                        //border raiuds of dropdown button
                        boxShadow: const <BoxShadow>[
                          //apply shadow on Dropdown button
                          BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.57),
                              //shadow for button
                              blurRadius: 5) //blur radius of shadow
                        ],
                      ),
                      child: Text(
                        "Drukuj",
                        style: TextStyle(
                            fontSize: 40 * textScale, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void display_list() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
            backgroundColor: const Color.fromRGBO(160, 69, 14, 1),
            title: Text(
              "Aktualnie dodane produkty",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 50 * MediaQuery.of(context).size.width / 1080,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              ("${lista.join('\n')}\nSuma: $sum zl"),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 45 * MediaQuery.of(context).size.width / 1080,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )));
  }

  void clear_list() {
    lista.clear();
    products.clear();
    sum = 0.0;
  }

  @override
  void initState() {
    super.initState();

    bluetoothPrint.scanResults.listen((devices) async {
      setState(() {
        _devices = devices;
        print(_devices.length.toString());
      });
    });
    _startScanDevices();
  }

  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).size.width / 1080;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Coffee Ride"),
      ),
      body: StreamBuilder<List<BluetoothDevice>>(
        stream: bluetoothPrint.scanResults,
        builder: (_, snapshot) {
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("lib/assets/coffee.png"),
                    fit: BoxFit.fill),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
                child: ListView(children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        height: MediaQuery.of(context).size.height / 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 15),
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(160, 69, 14, 1),
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border radius of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ]),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: Color.fromRGBO(160, 69, 14, 1),
                            style: TextStyle(
                                fontSize: 50 * textScale,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            // Initial Value
                            value: dropdownvalue,

                            // Down Arrow Icon
                            icon: const Icon(Icons.keyboard_arrow_down),

                            // Array list of items
                            items: items
                                .map((description, value) {
                                  return MapEntry(
                                      description,
                                      DropdownMenuItem<String>(
                                        value: description,
                                        child: Text(
                                          description,
                                          style: TextStyle(fontFamily: "kalam"),
                                        ),
                                      ));
                                })
                                // 2x 10   2x 19   1x 25
                                // 2x 25 1x 22
                                .values
                                .toList(),
                            alignment: AlignmentDirectional.center,
                            // After selecting the desired option,it will
                            // change button value to selected value
                            onChanged: (String? newValue) {
                              myCounter.text = "1";
                              setState(() {
                                dropdownvalue = newValue!;
                              });
                              myController.text =
                                  items[dropdownvalue].toString();
                            },
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: _decrementCounter,
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(160, 69, 14, 1),
                                //background color of dropdown button
                                border:
                                    Border.all(color: Colors.black38, width: 3),
                                //border of dropdown button
                                borderRadius: BorderRadius.circular(50),
                                //border raiuds of dropdown button
                                boxShadow: const <BoxShadow>[
                                  //apply shadow on Dropdown button
                                  BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.57),
                                      //shadow for button
                                      blurRadius: 5) //blur radius of shadow
                                ],
                              ),
                              child: Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 5,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(160, 69, 14, 1),
                              //background color of dropdown button
                              border:
                                  Border.all(color: Colors.black38, width: 3),
                              //border of dropdown button
                              borderRadius: BorderRadius.circular(15),
                              //border raiuds of dropdown button
                              boxShadow: const <BoxShadow>[
                                //apply shadow on Dropdown button
                                BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.57),
                                    //shadow for button
                                    blurRadius: 5) //blur radius of shadow
                              ],
                            ),
                            child: TextField(
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 50 * textScale,
                                  color: Colors.white),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                suffix: Text(
                                  'szt',
                                  style: TextStyle(
                                      fontSize: 50 * textScale,
                                      color: Colors.white),
                                ),
                              ),
                              controller: myCounter,
                              autofocus: false,
                            ),
                          ),
                          TextButton(
                            onPressed: _incrementCounter,
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(160, 69, 14, 1),
                                //background color of dropdown button
                                border:
                                    Border.all(color: Colors.black38, width: 3),
                                //border of dropdown button
                                borderRadius: BorderRadius.circular(50),
                                //border raiuds of dropdown button
                                boxShadow: const <BoxShadow>[
                                  //apply shadow on Dropdown button
                                  BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.57),
                                      //shadow for button
                                      blurRadius: 5) //blur radius of shadow
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _decrementPrice,
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(160, 69, 14, 1),
                                border:
                                    Border.all(color: Colors.black38, width: 3),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.57),
                                      blurRadius: 5) //blur radius of shadow
                                ],
                              ),
                              child: Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 5,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(160, 69, 14, 1),
                              //background color of dropdown button
                              border:
                                  Border.all(color: Colors.black38, width: 3),
                              //border of dropdown button
                              borderRadius: BorderRadius.circular(15),
                              //border raiuds of dropdown button
                              boxShadow: const <BoxShadow>[
                                //apply shadow on Dropdown button
                                BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.57),
                                    //shadow for button
                                    blurRadius: 5) //blur radius of shadow
                              ],
                            ),
                            child: TextField(
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 50 * textScale,
                                  color: Colors.white),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                suffix: Text(
                                  'zł',
                                  style: TextStyle(
                                      fontSize: 50 * textScale,
                                      color: Colors.white),
                                ),
                              ),
                              controller: myController,
                              autofocus: false,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _incrementPrice();
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(160, 69, 14, 1),
                                border:
                                    Border.all(color: Colors.black38, width: 3),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.57),
                                      blurRadius: 5) //blur radius of shadow
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          add();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(160, 69, 14, 1),
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border raiuds of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Dodaj do listy ",
                                style: TextStyle(
                                    fontSize: 50 * textScale,
                                    color: Colors.white),
                              ),
                              Icon(Icons.add_card,
                                  color: Colors.white, size: 50 * textScale),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: display_list,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(134, 51, 1, 1.0),
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border raiuds of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Pokaż listę ",
                                style: TextStyle(
                                    fontSize: 50 * textScale,
                                    color: Colors.white),
                              ),
                              Icon(Icons.search,
                                  color: Colors.white, size: 50 * textScale),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: clear_list,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border raiuds of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Wyczyść listę ",
                                style: TextStyle(
                                    fontSize: 50 * textScale,
                                    color: Colors.white),
                              ),
                              Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _printReceipt();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border raiuds of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Drukuj ",
                                style: TextStyle(
                                  fontSize: 50 * textScale,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                Icons.print,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _openDialog(context);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border raiuds of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Połącz drukarkę ",
                                style: TextStyle(
                                  fontSize: 50 * textScale,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                Icons.print,
                                color: Colors.white,
                                size: 50 * textScale,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          displayOrders();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(134, 51, 1, 1.0),
                            //background color of dropdown button
                            border: Border.all(color: Colors.black38, width: 3),
                            //border of dropdown button
                            borderRadius: BorderRadius.circular(50),
                            //border raiuds of dropdown button
                            boxShadow: const <BoxShadow>[
                              //apply shadow on Dropdown button
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  //shadow for button
                                  blurRadius: 5) //blur radius of shadow
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Podsumowania ",
                                style: TextStyle(
                                    fontSize: 50 * textScale,
                                    color: Colors.white),
                              ),
                              Icon(Icons.bar_chart,
                                  color: Colors.white, size: 50 * textScale),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder(
        stream: bluetoothPrint.isScanning,
        initialData: false,
        builder: (_, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return FloatingActionButton(
              onPressed: () => bluetoothPrint.stopScan(),
              child: Icon(Icons.stop),
              backgroundColor: Colors.redAccent,
            );
          } else {
            return FloatingActionButton(
              onPressed: () => _startScanDevices(),
              child: Icon(Icons.search),
            );
          }
        },
      ),
    );
  }

  Future _openDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
              title: Column(
                children: [
                  Text("Wybierz drukarkę do podłączenia"),
                  SizedBox(
                    height: 15.0,
                  ),
                ],
              ),
              content: _setupDialogContainer(context),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Zamknij'))
              ],
            ));
  }

  Widget _setupDialogContainer(BuildContext context) {
    print(_devices.length.toString());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200.0,
          width: 300.0,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: _devices.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () async {
                    await bluetoothPrint.connect(_devices[index]);
                    setState(() {
                      _selectedPrinter.add(_devices[index]);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 70.0,
                        padding: EdgeInsets.only(left: 10.0),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(
                              width: 10.0,
                            ),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_devices[index].name ?? ''),
                                Text(_devices[index].address.toString()),
                                Flexible(
                                    child: Text(
                                  'Kliknij aby wybrać drukarkę',
                                  style: TextStyle(color: Colors.grey[700]),
                                  textAlign: TextAlign.justify,
                                )),
                              ],
                            )),
                          ],
                        ),
                      ),
                      Divider(),
                    ],
                  ),
                );
              }),
        )
      ],
    );
  }
}
