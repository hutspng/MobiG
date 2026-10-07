import 'package:flutter/material.dart';
import 'database/database_helper.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.products, this.onChanged});

  final List<Map<String, String>> products;

  /// Chamado depois de qualquer alteração (criar, excluir) para que o
  /// dashboard recarregue seus números.
  final VoidCallback? onChanged;

  @override
  State<ProductsPage> createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  late Set<int> selectedProducts = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, String>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  // O indicador de carregamento só aparece na primeira carga; nas recargas a
  // lista é atualizada sem piscar e sem perder a posição de rolagem.
  Future<void> loadProducts() async {
    final products = await _dbHelper.getProducts();
    if (!mounted) return;
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
      // A seleção é guardada pela posição na lista. Depois de recarregar, as
      // posições podem ter mudado, então a seleção é descartada.
      selectedProducts.clear();
      _isLoading = false;
    });
  }

  /// Abre o diálogo de novo produto (acionado pelo botão + da tela inicial).
  void showAddProductDialog() {
    _showAddProductDialog(context, () {
      loadProducts();
      widget.onChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (selectedProducts.isEmpty)
                  const Text(
                    'Produtos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '${selectedProducts.length} selecionado${selectedProducts.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (selectedProducts.isNotEmpty)
                  IconButton(
                    onPressed: _deleteSelectedProducts,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  )
                else
                  // Mantém a altura do cabeçalho igual com ou sem seleção
                  const SizedBox(height: 48),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar produtos...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._products.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> product = entry.value;
              return _ProductCard(
                product: product,
                isSelected: selectedProducts.contains(index),
                onLongPress: () {
                  setState(() {
                    if (selectedProducts.contains(index)) {
                      selectedProducts.remove(index);
                    } else {
                      selectedProducts.add(index);
                    }
                  });
                },
                onTap: () {
                  if (selectedProducts.isNotEmpty) {
                    setState(() {
                      if (selectedProducts.contains(index)) {
                        selectedProducts.remove(index);
                      } else {
                        selectedProducts.add(index);
                      }
                    });
                  } else {
                    _showEditProductDialog(context, product);
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedProducts() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Confirmar exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja excluir ${selectedProducts.length} produto${selectedProducts.length > 1 ? 's' : ''}?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Ids dos produtos selecionados (a seleção é por posição)
              final ids = selectedProducts
                  .where((index) => index < _products.length)
                  .map((index) => int.parse(_products[index]['id']!))
                  .toList();

              for (final id in ids) {
                await _dbHelper.deleteProduct(id);
              }

              // Recarrega a lista (isso também limpa a seleção) e o dashboard
              await loadProducts();
              widget.onChanged?.call();

              // Usa o context/mounted da página: o do diálogo já foi fechado
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produtos excluídos com sucesso!'),
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showAddProductDialog(BuildContext context, VoidCallback onProductAdded) {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  bool onDemand = false;
  final dbHelper = DatabaseHelper();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Novo Produto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Nome do Produto',
                'Ex: Notebook Dell',
                nameController,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Categoria',
                'Ex: Eletrônicos',
                categoryController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Preço', '0.00', priceController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      'Estoque',
                      '0',
                      stockController,
                      enabled: !onDemand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: onDemand,
                    onChanged: (value) {
                      setState(() {
                        onDemand = value ?? false;
                        if (onDemand) {
                          stockController.clear();
                        }
                      });
                    },
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.cyan;
                      }
                      return Colors.grey[700];
                    }),
                    checkColor: const Color(0xFF1a1a2e),
                  ),
                  const Text(
                    'Sob demanda',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1558c9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      categoryController.text.isEmpty ||
                      priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha todos os campos obrigatórios'),
                      ),
                    );
                    return;
                  }

                  final price = double.tryParse(priceController.text) ?? 0;
                  final stock = int.tryParse(stockController.text) ?? 0;

                  try {
                    await dbHelper.insertProduct(
                      name: nameController.text,
                      category: categoryController.text,
                      price: price,
                      stock: onDemand ? 0 : stock,
                      onDemand: onDemand,
                    );
                    Navigator.pop(context);
                    // Recarregar página
                    onProductAdded();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Produto adicionado com sucesso!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao adicionar produto: $e'),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Salvar Produto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showEditProductDialog(BuildContext context, Map<String, String> product) {
  final priceController = TextEditingController(text: product['price']);
  final stockController = TextEditingController(text: product['stock']);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Editar Produto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Produto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['name']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Preço (R\$)',
                    '0.00',
                    priceController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField('Estoque', '0', stockController),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1558c9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // TODO: Salvar alterações do produto
                Navigator.pop(context);
              },
              child: const Text(
                'Salvar Alterações',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTextField(
  String label,
  String hint,
  TextEditingController controller, {
  bool enabled = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: enabled
              ? const Color(0xFF0f1419)
              : const Color(0xFF0a0a0a),
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
    ],
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Map<String, String> product;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2a3a4e) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Color(0xFF1a1a2e)),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1f2c45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.cyan,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['category']!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product['price']!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Estoque: ${product['stock']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
