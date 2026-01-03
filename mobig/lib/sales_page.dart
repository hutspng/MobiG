import 'package:flutter/material.dart';
import 'database/database_helper.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key, required this.products, required this.clients});

  final List<Map<String, String>> products;
  final List<Map<String, String>> clients;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  String? selectedClient;
  String? selectedProduct;
  int quantity = 1;
  final notesController = TextEditingController();

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  double get subtotal {
    if (selectedProduct == null) return 0;
    final product = widget.products.firstWhere(
      (p) => p['name'] == selectedProduct,
      orElse: () => {'price': 'R\$ 0.00'},
    );
    final priceText = product['price']!.replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(priceText) ?? 0;
    return price * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF01060c),
      appBar: AppBar(
        backgroundColor: const Color(0xFF01060c),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nova Compra',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cliente
              const Text(
                'Cliente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: DropdownButton<String>(
                  value: selectedClient,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Selecione um cliente',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1a1a2e),
                  items: widget.clients.map((client) {
                    return DropdownMenuItem(
                      value: client['name'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(client['name']!),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClient = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Produto
              const Text(
                'Produto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: DropdownButton<String>(
                  value: selectedProduct,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Selecione um produto',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1a1a2e),
                  items: widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product['name'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${product['name']} - ${product['price']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProduct = value;
                      quantity = 1;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Quantidade
              const Text(
                'Quantidade',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0f1419),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    quantity = int.tryParse(value) ?? 1;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Observações
              const Text(
                'Observações (opcional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Adicione observações sobre a compra',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0f1419),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Subtotal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantidade',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        Text(
                          '${quantity}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Botão de registrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1558c9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: selectedClient == null || selectedProduct == null
                      ? null
                      : () async {
                          try {
                            final dbHelper = DatabaseHelper();

                            // Encontrar IDs do cliente e produto
                            int? clientId;
                            int? productId;
                            double? productPrice;

                            // Buscar cliente
                            final clients = await dbHelper.getClients();
                            for (var client in clients) {
                              if (client['name'] == selectedClient) {
                                clientId = client['id'];
                                break;
                              }
                            }

                            // Buscar produto
                            final products = await dbHelper.getProducts();
                            for (var product in products) {
                              if (product['name'] == selectedProduct) {
                                productId = product['id'];
                                productPrice = product['price'] as double;
                                break;
                              }
                            }

                            if (clientId != null &&
                                productId != null &&
                                productPrice != null) {
                              final totalPrice = productPrice * quantity;

                              await dbHelper.insertSale(
                                clientId: clientId,
                                productId: productId,
                                quantity: quantity,
                                unitPrice: productPrice,
                                totalPrice: totalPrice,
                                notes: notesController.text.isEmpty
                                    ? null
                                    : notesController.text,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Compra registrada com sucesso!',
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao registrar compra: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text(
                    'Registrar Compra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
