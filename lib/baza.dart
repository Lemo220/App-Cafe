import 'dart:io' show Directory;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

class Order {
  final int id;
  final int date;

  Order({
    required this.id,
    required this.date,
  });
  factory Order.fromMap(Map<String, dynamic> json) => Order(
        id: json["id"],
        date: json["date"],
      );
}

class Products {
  final int id;
  final String name;
  final int count;
  final int price;

  Products({
    required this.id,
    required this.name,
    required this.count,
    required this.price,
  });
  factory Products.fromMap(Map<String, dynamic> json) => Products(
        id: json["id"],
        name: json["name"],
        count: json["count"],
        price: json["price"],
      );
}

// 2x 10
// 2x 15
// 1x 25
class DatabaseHelper {
  static const _databaseName = "coffee_db6.db";
  static const _databaseVersion = 1;

  static const table_orderss = 'coffee_orders';
  static const table_product = 'products';

  static const columnId = '_id';
  static const columnPrice = 'price';
  static const columnCount = 'count';
  static const columnName = 'name';
  static const ColumnDate = 'date';
  static const ForeKey = 'forid';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table_orderss(
            $columnId INTEGER PRIMARY KEY,
            $ColumnDate DATETIME NOT NULL
          );
          ''');
    await db.execute('''
    CREATE TABLE products(
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnPrice REAL NOT NULL,
        $columnCount INTEGER NOT NULL,
        $ForeKey INTEGER NOT NULL,
        FOREIGN KEY ($ForeKey) REFERENCES $table_orderss($columnId));''');
  }

  Future<List<Products>> getOrder() async {
    Database? db = await instance.database;
    var orders = await db?.query("products");
    List<Products> orderList = orders!.isNotEmpty
        ? orders.map((c) => Products.fromMap(c)).toList()
        : [];
    print(orders);

    return orderList;
  }

  Future fetchData(startDate, endDate) async {
    final Database db = await _initDatabase();
    final List<Map<String, dynamic>> queryResult = await db.rawQuery("""
select distinct name, count, price from products, coffee_orders where coffee_orders.date >= "${startDate.toString()}" and coffee_orders.date <= "${endDate.toString()}"
""");
    return queryResult;
  }

  Future yoinsert(products) async {
    // get a reference to the database
    // because this is an expensive operation we use async and await
    Database? db = await DatabaseHelper.instance.database;
    // row to insert
    DateTime now = DateTime.now();
    Map<String, dynamic> rowOrder = {
      DatabaseHelper.ColumnDate: now.toString(),
    };
    print("here $products");
    if (products.isNotEmpty) {
      print("jazda");
      int? idmain = await db?.insert(DatabaseHelper.table_orderss, rowOrder);
      for (var i = 0; i < products.length; i++) {
        Map<String, dynamic> rowProduct = {
          DatabaseHelper.columnName: products[i]["Nazwa"],
          DatabaseHelper.columnPrice: products[i]["Cena"],
          DatabaseHelper.columnCount: products[i]["Ilość"],
          DatabaseHelper.ForeKey: idmain,
        };
        int? id = await db?.insert(DatabaseHelper.table_product, rowProduct);
      }
    }

    // do the insert and get the id of the inserted row

    // show the results: print all rows in the db
  }
}
