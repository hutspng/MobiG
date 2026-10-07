import 'package:flutter/material.dart';
import 'database/database_helper.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key, required this.clients, this.onChanged});

  final List<Map<String, String>> clients;

  /// Chamado depois de qualquer alteração (criar, editar, excluir, marcar
  /// como pago) para que o dashboard recarregue seus números.
  final VoidCallback? onChanged;

  @override
  State<ClientsPage> createState() => ClientsPageState();
}

class ClientsPageState extends State<ClientsPage> {
  late Set<int> selectedClients = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, String>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  // O indicador de carregamento só aparece na primeira carga; nas recargas a
  // lista é atualizada sem piscar e sem perder a posição de rolagem.
  Future<void> loadClients() async {
    final clients = await _dbHelper.getClients();
    if (!mounted) return;
    setState(() {
      _clients = clients.map((c) {
        final pending = (c['pending_value'] as num).toDouble();
        return {
          'id': c['id'].toString(),
          'name': c['name'] as String,
          'nickname': c['nickname'] as String? ?? '',
          'purchases': (c['purchases'] as num).toInt().toString(),
          // Valor já pago (verde)
          'total':
              'R\$ ${(c['total_value'] as num).toDouble().toStringAsFixed(2)}',
          // Valor das compras ainda não pagas (vermelho)
          'pending': 'R\$ ${pending.toStringAsFixed(2)}',
          'has_pending': pending > 0 ? 'true' : 'false',
          'email': c['nickname'] as String? ?? '',
        };
      }).toList();
      // A seleção é guardada pela posição na lista. Depois de recarregar, as
      // posições podem ter mudado, então a seleção é descartada.
      selectedClients.clear();
      _isLoading = false;
    });
  }

  /// Abre o diálogo de novo cliente (acionado pelo botão + da tela inicial).
  void showAddClientDialog() {
    _showAddClientDialog(context, () {
      loadClients();
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
                if (selectedClients.isEmpty)
                  const Text(
                    'Clientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '${selectedClients.length} selecionado${selectedClients.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (selectedClients.isNotEmpty)
                  IconButton(
                    onPressed: _deleteSelectedClients,
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
                  hintText: 'Buscar clientes...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._clients.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> client = entry.value;
              return _ClientCard(
                client: client,
                isSelected: selectedClients.contains(index),
                onLongPress: () {
                  setState(() {
                    if (selectedClients.contains(index)) {
                      selectedClients.remove(index);
                    } else {
                      selectedClients.add(index);
                    }
                  });
                },
                onTap: () {
                  if (selectedClients.isNotEmpty) {
                    setState(() {
                      if (selectedClients.contains(index)) {
                        selectedClients.remove(index);
                      } else {
                        selectedClients.add(index);
                      }
                    });
                  } else {
                    _showEditClientDialog(context, client, () {
                      loadClients();
                      widget.onChanged?.call();
                    });
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedClients() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Confirmar exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja excluir ${selectedClients.length} cliente${selectedClients.length > 1 ? 's' : ''}?',
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

              // Ids dos clientes selecionados (a seleção é por posição)
              final ids = selectedClients
                  .where((index) => index < _clients.length)
                  .map((index) => int.parse(_clients[index]['id']!))
                  .toList();

              for (final id in ids) {
                await _dbHelper.deleteClient(id);
              }

              // Recarrega a lista (isso também limpa a seleção) e o dashboard,
              // que guarda contadores e atividade recente em memória.
              await loadClients();
              widget.onChanged?.call();

              // Usa o context/mounted da página: o do diálogo já foi fechado
              // e, por isso, o aviso de sucesso nunca aparecia.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clientes excluídos com sucesso!'),
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

void _showEditClientDialog(
  BuildContext context,
  Map<String, String> client,
  VoidCallback onChanged,
) {
  final nameController = TextEditingController(text: client['name']);
  final nicknameController = TextEditingController(text: client['nickname']);
  final dbHelper = DatabaseHelper();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Cliente',
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
              _buildClientTextField(
                'Nome Completo',
                'Ex: Maria Silva',
                nameController,
              ),
              const SizedBox(height: 12),
              _buildClientTextField(
                'Apelido',
                'Como prefere ser chamado',
                nicknameController,
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Compras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final clientId = int.parse(client['id']!);
                        await dbHelper.updateClientSalesPaidStatus(
                          clientId,
                          true,
                        );
                        onChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Todas as compras marcadas como pagas',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Marcar Tudo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final clientId = int.parse(client['id']!);
                        await dbHelper.updateClientSalesPaidStatus(
                          clientId,
                          false,
                        );
                        onChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Todas as compras marcadas como pendentes',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Desmarcar Tudo'),
                    ),
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
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha o nome do cliente'),
                      ),
                    );
                    return;
                  }

                  try {
                    final clientId = int.parse(client['id']!);
                    await dbHelper.updateClient(
                      id: clientId,
                      name: nameController.text,
                      nickname: nicknameController.text,
                    );
                    onChanged();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cliente atualizado com sucesso!'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar cliente: $e')),
                    );
                  }
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
    ),
  );
}

void _showAddClientDialog(BuildContext context, VoidCallback onClientAdded) {
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final dbHelper = DatabaseHelper();

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
                  'Novo Cliente',
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
            _buildTextField('Nome Completo', 'Ex: Maria Silva', nameController),
            const SizedBox(height: 12),
            _buildTextField(
              'Apelido',
              'Como prefere ser chamado',
              nicknameController,
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha o nome do cliente')),
                  );
                  return;
                }

                try {
                  await dbHelper.insertClient(
                    name: nameController.text,
                    nickname: nicknameController.text,
                  );
                  Navigator.pop(context);
                  onClientAdded();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente adicionado com sucesso!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao adicionar cliente: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Salvar Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildClientTextField(
  String label,
  String hint,
  TextEditingController controller,
) {
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
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
    ],
  );
}

Widget _buildTextField(
  String label,
  String hint,
  TextEditingController controller,
) {
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
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
    ],
  );
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Map<String, String> client;
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
                child: const Icon(Icons.person_outline, color: Colors.cyan),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    client['email']!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${client['purchases']} compras',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      // Verde: valor já pago
                      Text(
                        client['total']!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Vermelho: valor das compras feitas e ainda não pagas
                      // (só aparece quando o cliente está devendo)
                      if (client['has_pending'] == 'true') ...[
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          client['pending']!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
