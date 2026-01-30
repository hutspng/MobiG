import 'package:flutter/material.dart';
import 'products_page.dart';
import 'clients_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';
import 'sales_page.dart';
import 'database/database_helper.dart';

void main() {
  runApp(const MyApp());
}

final GlobalKey<HomePageState> homeKey = GlobalKey();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobiG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFF01060c),
      ),
      home: HomePage(key: homeKey),
    );
  }
}

// Widget para construir cada card de estatística
Widget _buildStatCard({
  required IconData icon,
  required String number,
  required String label,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1a1a2e),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[800]!, width: 1),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.cyan, size: 28),
        const SizedBox(height: 16),
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    ),
  );
}

// Widget para construir cada item de atividade recente
Widget _buildActivityItem({
  required String name,
  required String product,
  required String value,
  required String time,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1a1a2e),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[800]!, width: 1),
    ),
    padding: const EdgeInsets.all(12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Método público para recarregar os dados do dashboard
  Future<void> refresh() async {
    await _loadInitialData();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();
  late List<Map<String, String>> _products = [];
  late List<Map<String, String>> _clients = [];
  late List<Map<String, String>> _history = [];
  late List<Map<String, dynamic>> _bestSellers = [];
  int _totalProducts = 0;
  int _totalClients = 0;
  int _totalSales = 0;
  double _totalRevenue = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];

  final GlobalKey<ProductsPageState> _productsKey = GlobalKey();
  final GlobalKey<ClientsPageState> _clientsKey = GlobalKey();
  final GlobalKey<StatsPageState> _statsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProducts(),
      _loadClients(),
      _loadDashboardStats(),
      _loadRecentActivities(),
    ]);
  }

  Future<void> _loadDashboardStats() async {
    final products = await _dbHelper.getTotalProducts();
    final clients = await _dbHelper.getTotalClients();
    final sales = await _dbHelper.getTotalSalesAll();
    final revenue = await _dbHelper.getTotalRevenueAll();
    setState(() {
      _totalProducts = products;
      _totalClients = clients;
      _totalSales = sales;
      _totalRevenue = revenue;
    });
  }

  Future<void> _loadRecentActivities() async {
    final activities = await _dbHelper.getSales(limit: 5);
    setState(() {
      _recentActivities = activities;
    });
  }

  Future<void> _loadProducts() async {
    final products = await _dbHelper.getProducts();
    setState(() {
      _products = products
          .map(
            (p) => {
              'id': p['id'].toString(),
              'name': p['name'] as String,
              'category': p['category'] as String,
              'price': 'R\$ ${(p['price'] as double).toStringAsFixed(2)}',
              'stock': (p['stock'] as int).toString(),
              'on_demand': (p['on_demand'] as int) == 1 ? 'true' : 'false',
            },
          )
          .toList();
    });
  }

  Future<void> _loadClients() async {
    final clients = await _dbHelper.getClients();
    setState(() {
      _clients = clients
          .map(
            (c) => {
              'id': c['id'].toString(),
              'name': c['name'] as String,
              'nickname': c['nickname'] as String? ?? '',
              'purchases': (c['purchases'] as int).toString(),
              'total': 'R\$ ${(c['total_value'] as double).toStringAsFixed(2)}',
              'email': c['nickname'] as String? ?? '',
            },
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageTitles = ['Gestão de Compras', 'Produtos', 'Clientes', 'Stats'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF01060c),
        elevation: 0,
        title: Text(
          pageTitles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
          ? ProductsPage(key: _productsKey, products: _products)
          : _selectedIndex == 2
          ? ClientsPage(key: _clientsKey, clients: _clients)
          : StatsPage(
              key: _statsKey,
              bestSellers: _bestSellers,
              history: _history,
            ),
      floatingActionButton: _selectedIndex == 3
          ? null // Não mostrar FAB na página Stats
          : FloatingActionButton(
              backgroundColor: const Color(0xFF1558c9),
              child: const Icon(Icons.add, size: 28),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesPage()),
                );
                // Recarregar dados após adicionar venda
                homeKey.currentState?.refresh();
                _productsKey.currentState?.loadProducts();
                _clientsKey.currentState?.loadClients();
                _statsKey.currentState?.refresh();
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF01060c),
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produtos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: Colors.cyan,
      backgroundColor: const Color(0xFF1a1a2e),
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Gestão de Compras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gerencie produtos, clientes e vendas',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 1),
                    child: _buildStatCard(
                      icon: Icons.shopping_bag,
                      number: _totalProducts.toString(),
                      label: 'Produtos',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 2),
                    child: _buildStatCard(
                      icon: Icons.people,
                      number: _totalClients.toString(),
                      label: 'Clientes',
                    ),
                  ),
                  _buildStatCard(
                    icon: Icons.trending_up,
                    number: _totalSales.toString(),
                    label: 'Compras totais',
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 3),
                    child: _buildStatCard(
                      icon: Icons.attach_money,
                      number: 'R\$ ${_totalRevenue.toStringAsFixed(2)}',
                      label: 'Faturamento',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Atividade Recente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _recentActivities.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma atividade registrada',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : Column(
                      children: _recentActivities.map((activity) {
                        final clientName = activity['client_name'] as String;
                        final productName = activity['product_name'] as String;
                        final value = activity['total_price'] as double;
                        final timeStr = _formatTimeAgo(
                          activity['sale_date'] as String,
                        );

                        return Column(
                          children: [
                            _buildActivityItem(
                              name: clientName,
                              product: productName,
                              value: 'R\$ ${value.toStringAsFixed(2)}',
                              time: timeStr,
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final saleDate = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(saleDate);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m atrás';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h atrás';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d atrás';
      } else {
        return '${(difference.inDays / 7).floor()}w atrás';
      }
    } catch (e) {
      return 'Recentemente';
    }
  }
}
