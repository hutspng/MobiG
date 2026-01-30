import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'mobig.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Adicionar coluna 'paid' à tabela sales se não existir
      try {
        await db.execute(
          'ALTER TABLE sales ADD COLUMN paid INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        // Coluna já existe, ignorar erro
      }
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabela de Produtos
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        on_demand INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabela de Clientes
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        nickname TEXT,
        purchases INTEGER NOT NULL DEFAULT 0,
        total_value REAL NOT NULL DEFAULT 0.0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabela de Vendas
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        notes TEXT,
        paid INTEGER NOT NULL DEFAULT 0,
        sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES clients(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
  }

  // ===== PRODUTOS =====
  Future<int> insertProduct({
    required String name,
    required String category,
    required double price,
    required int stock,
    required bool onDemand,
  }) async {
    final db = await database;
    return db.insert('products', {
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'on_demand': onDemand ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return db.query('products', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateProduct({
    required int id,
    required String name,
    required String category,
    required double price,
    required int stock,
    required bool onDemand,
  }) async {
    final db = await database;
    return db.update(
      'products',
      {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'on_demand': onDemand ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ===== CLIENTES =====
  Future<int> insertClient({
    required String name,
    required String nickname,
  }) async {
    final db = await database;
    return db.insert('clients', {'name': name, 'nickname': nickname});
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    return db.query('clients', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getClient(int id) async {
    final db = await database;
    final results = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateClient({
    required int id,
    required String name,
    required String nickname,
  }) async {
    final db = await database;
    return db.update(
      'clients',
      {'name': name, 'nickname': nickname},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;

    // Deletar todas as vendas associadas ao cliente
    await db.delete('sales', where: 'client_id = ?', whereArgs: [id]);

    // Deletar o cliente
    return db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ===== VENDAS =====
  Future<int> insertSale({
    required int clientId,
    required int productId,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
    String? notes,
    bool paid = false,
  }) async {
    final db = await database;

    // Atualizar dados do cliente apenas se a compra for marcada como paga
    if (paid) {
      await db.rawUpdate(
        'UPDATE clients SET purchases = purchases + 1, total_value = total_value + ? WHERE id = ?',
        [totalPrice, clientId],
      );
    }

    return db.insert('sales', {
      'client_id': clientId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'paid': paid ? 1 : 0,
      'sale_date': DateTime.now().toIso8601String(),
    });
  }


  Future<List<Map<String, dynamic>>> getSales({int? clientId, int? limit}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    
    if (clientId != null) {
      where = 'WHERE s.client_id = ?';
      args.add(clientId);
    }
    
    String limitClause = '';
    if (limit != null) {
      limitClause = 'LIMIT ?';
      args.add(limit);
    }
    
    return db.rawQuery('''
      SELECT s.*, c.name as client_name, p.name as product_name
      FROM sales s
      JOIN clients c ON s.client_id = c.id
      JOIN products p ON s.product_id = p.id
      $where
      ORDER BY s.sale_date DESC
      $limitClause
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getSalesToday() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    return db.rawQuery(
      '''
      SELECT s.*, c.name as client_name, p.name as product_name
      FROM sales s
      JOIN clients c ON s.client_id = c.id
      JOIN products p ON s.product_id = p.id
      WHERE s.sale_date >= ? AND s.sale_date <= ?
      ORDER BY s.sale_date DESC
    ''',
      [todayStart, todayEnd],
    );
  }



  Future<int> deleteSale(int id) async {
    final db = await database;
    
    // Buscar a venda para obter informações antes de deletar
    final sale = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (sale.isEmpty) return 0;

    final saleData = sale.first;
    final clientId = saleData['client_id'] as int;
    final totalPrice = saleData['total_price'] as double;
    final wasPaid = (saleData['paid'] as int) == 1;

    // Se era uma venda paga, atualizar stats do cliente
    if (wasPaid) {
      await db.rawUpdate(
        'UPDATE clients SET purchases = purchases - 1, total_value = total_value - ? WHERE id = ?',
        [totalPrice, clientId],
      );
    }

    return db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSalePaidStatus(int saleId, bool paid) async {
    final db = await database;

    // Buscar a venda em transação
    return db.transaction((txn) async {
      final sale = await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
      if (sale.isEmpty) return 0;

      final saleData = sale.first;
      final clientId = saleData['client_id'] as int;
      final totalPrice = saleData['total_price'] as double;
      final wasPaid = (saleData['paid'] as int) == 1;

      // Se está mudando de não pago para pago
      if (!wasPaid && paid) {
        await txn.rawUpdate(
          'UPDATE clients SET purchases = purchases + 1, total_value = total_value + ? WHERE id = ?',
          [totalPrice, clientId],
        );
      }
      // Se está mudando de pago para não pago
      else if (wasPaid && !paid) {
        await txn.rawUpdate(
          'UPDATE clients SET purchases = purchases - 1, total_value = total_value - ? WHERE id = ?',
          [totalPrice, clientId],
        );
      }

      return txn.update(
        'sales',
        {'paid': paid ? 1 : 0},
        where: 'id = ?',
        whereArgs: [saleId],
      );
    });
  }

  Future<int> updateClientSalesPaidStatus(int clientId, bool paid) async {
    final db = await database;
    return db.update(
      'sales',
      {'paid': paid ? 1 : 0},
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  // ===== ESTATÍSTICAS =====
  Future<int> getTotalProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalClients() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM clients');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalSalesThisMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sales
      WHERE paid = 1 AND strftime('%Y-%m', sale_date) = strftime('%Y-%m', 'now')
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getTotalRevenueThisMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(total_price) as total FROM sales
      WHERE paid = 1 AND strftime('%Y-%m', sale_date) = strftime('%Y-%m', 'now')
    ''');
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT p.id, p.name, COALESCE(SUM(s.quantity), 0) as sales_count, COALESCE(SUM(s.total_price), 0) as total_revenue
      FROM products p
      LEFT JOIN sales s ON p.id = s.product_id
      GROUP BY p.id
      ORDER BY sales_count DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getTopClients({int limit = 3}) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT c.id, c.name, c.purchases, c.total_value
      FROM clients c
      ORDER BY c.purchases DESC, c.name ASC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<int> getTotalSalesAll() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales WHERE paid = 1',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getTotalRevenueAll() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(total_price) as total FROM sales WHERE paid = 1
    ''');
    return (result.first['total'] as double?) ?? 0.0;
  }


  // ===== LIMPEZA =====
  Future<void> deleteAllData() async {
    final db = await database;
    // Deletar todas as vendas
    await db.delete('sales');
    // Deletar todos os clientes
    await db.delete('clients');
    // Deletar todos os produtos
    await db.delete('products');
  }

  Future<void> deleteAllDatabase() async {
    // Fechar conexão primeiro
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'mobig.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
