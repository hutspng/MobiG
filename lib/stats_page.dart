import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.bestSellers,
    required this.history,
  });

  final List<Map<String, dynamic>> bestSellers;
  final List<Map<String, String>> history;

  @override
  State<StatsPage> createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topClients = [];
  List<Map<String, dynamic>> _allSales = [];
  bool _dailyFocus = false;

  @override
  void initState() {
    super.initState();
    _loadDailyFocusAndData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }
  }

  Future<void> _loadDailyFocusAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyFocus = prefs.getBool('daily_focus') ?? false;
    await _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    final topProducts = await _dbHelper.getTopProducts(limit: 5);
    final topClients = await _dbHelper.getTopClients(limit: 3);
    final allSales = _dailyFocus
        ? await _dbHelper.getSalesToday()
        : await _dbHelper.getSales();

    setState(() {
      _topProducts = topProducts;
      _topClients = topClients;
      _allSales = allSales;
    });
  }

  void refresh() {
    _loadDailyFocusAndData();
  }

  @override
  Widget build(BuildContext context) {
    final maxValueProducts = _topProducts.isEmpty
        ? 100
        : _topProducts
              .map((e) => (e['sales_count'] as int?) ?? 0)
              .reduce((a, b) => a > b ? a : b);

    final maxValueClients = _topClients.isEmpty
        ? 100
        : _topClients
              .map((e) => (e['purchases'] as int?) ?? 0)
              .reduce((a, b) => a > b ? a : b);

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estatísticas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Análise de vendas e clientes',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildChart(
                  _topProducts,
                  maxValueProducts,
                  'Produtos Mais Vendidos',
                  'sales_count',
                ),
                const SizedBox(height: 24),
                _buildChart(
                  _topClients,
                  maxValueClients,
                  'Top Clientes',
                  'purchases',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Histórico de Compras',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _allSales.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Nenhuma compra registrada',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    : Column(
                        children: _allSales.map((sale) {
                          return _HistoryCard(item: sale);
                        }).toList(),
                      ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (_showScrollToTop)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF1558c9),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildChart(
    List<Map<String, dynamic>> data,
    int maxValue,
    String title,
    String countKey,
  ) {
    if (data.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Center(
          child: Text('Sem dados', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    // Calcular o valor máximo para o eixo Y
    final roundedMax = ((maxValue / 5).ceil() * 5);
    final gridStep = roundedMax > 20 ? (roundedMax / 4).ceil() : 5;
    final gridMax = gridStep * 4;
    final gridLines = List.generate(5, (i) => i * gridStep);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                countKey == 'purchases' ? Icons.emoji_events : Icons.show_chart,
                color: countKey == 'purchases' ? Colors.amber : Colors.cyan,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eixo Y com valores
              SizedBox(
                width: 30,
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: gridLines.reversed.map((value) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Área do gráfico com linhas de grade
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      // Linhas de grade horizontais
                      ...gridLines.map((value) {
                        final topPosition = 200 - (value / gridMax) * 180;
                        return Positioned(
                          top: topPosition,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey[800]!,
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Barras
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: data.map((item) {
                            final count = (item[countKey] as int?) ?? 0;
                            final barHeight = gridMax > 0
                                ? (count / gridMax) * 180
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 40,
                                    height: barHeight.clamp(15.0, 180.0),
                                    decoration: BoxDecoration(
                                      color: countKey == 'purchases'
                                          ? Colors.amber
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Labels dos produtos
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: data.map((item) {
                            return SizedBox(
                              width: 60,
                              child: Text(
                                item['name'] as String? ?? 'N/A',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({required this.item});

  final Map<String, dynamic> item;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late int _isPaid;

  @override
  void initState() {
    super.initState();
    _isPaid = widget.item['paid'] as int? ?? 0;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Data não disponível';
    try {
      final date = DateTime.parse(dateStr);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year às $hour:$minute';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientName =
        widget.item['client_name'] as String? ?? 'Cliente não disponível';
    final productName =
        widget.item['product_name'] as String? ?? 'Produto não disponível';
    final totalPrice = widget.item['total_price'] as double? ?? 0.0;
    final quantity = widget.item['quantity'] as int? ?? 1;
    final saleDate = widget.item['sale_date'] as String?;
    final saleId = widget.item['id'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isPaid == 1 ? const Color(0xFF0d3b1f) : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isPaid == 1 ? Colors.green[700]! : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          if (saleId != null) {
            final newPaidStatus = _isPaid == 0 ? 1 : 0;
            await _dbHelper.updateSalePaidStatus(saleId, newPaidStatus == 1);
            setState(() {
              _isPaid = newPaidStatus;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isPaid == 1
                        ? 'Compra marcada como paga'
                        : 'Compra marcada como não paga',
                  ),
                ),
              );
            }
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$productName (x$quantity)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(saleDate),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isPaid == 1 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isPaid == 1 ? 'Pago' : 'Pendente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
