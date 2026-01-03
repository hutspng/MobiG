# MobiG - Gerenciador de Compras Mobile

Aplicativo Flutter para gerenciamento de produtos, clientes e registros de vendas com persistência em banco de dados SQLite.

## 📱 Funcionalidades

### Dashboard (Início)
- Exibição de estatísticas gerais:
  - Quantidade total de produtos
  - Quantidade total de clientes
  - Número total de compras registradas
  - Faturamento total
- Histórico de atividades recentes (últimas 5 transações)

### Produtos
- ✅ Criar novo produto com:
  - Nome (único)
  - Categoria
  - Preço
  - Quantidade em estoque
  - Opção "Sob demanda"
- ✅ Editar informações do produto
- ✅ Deletar produto
- ✅ Visualizar lista completa com filtro por categoria

### Clientes
- ✅ Criar novo cliente com:
  - Nome (único)
  - Apelido (opcional)
- ✅ Editar informações do cliente
- ✅ Deletar cliente (remove cliente e todas as suas vendas)
- ✅ Visualizar estatísticas por cliente:
  - Número total de compras
  - Valor total gasto

### Vendas
- ✅ Registrar nova venda com:
  - Seleção de cliente
  - Seleção de produto
  - Quantidade
  - Observações (opcional)
  - Cálculo automático de subtotal
- ✅ Carregamento em tempo real de produtos e clientes disponíveis
- ✅ Atualização automática do dashboard após nova venda

### Estatísticas (Stats)
- ✅ Gráfico dos 5 produtos mais vendidos (por quantidade)
- ✅ Histórico completo de vendas em ordem cronológica reversa
- ✅ Modo "Foco Diário" para visualizar apenas vendas do dia
- ✅ Botão para voltar ao topo da página

### Configurações
- ✅ Tema escuro ativo (padrão)
- ✅ Toggle "Foco Diário" para filtrar vendas por data
- ✅ Persistência de preferências com SharedPreferences

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework mobile
- **Dart**: Linguagem de programação
- **SQLite** (sqflite): Banco de dados local
- **SharedPreferences**: Armazenamento de preferências
- **Material Design**: Interface visual

## 📦 Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  path: ^1.8.3
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.2
```

## 🎨 Design

- **Paleta de cores**:
  - Fundo: `#01060c` (preto profundo)
  - Cards: `#1a1a2e` (cinza escuro)
  - Acento: `#1558c9` (azul)
  - Texto primário: Branco
  - Texto secundário: Cinza

- **Ícones**: Material Design Icons
- **Animações**: Transições suaves entre telas

## 📊 Estrutura do Banco de Dados

### Tabela: `products`
```
- id: INTEGER (PRIMARY KEY)
- name: TEXT (UNIQUE)
- category: TEXT
- price: REAL
- stock: INTEGER
- on_demand: INTEGER (0 ou 1)
- created_at: TIMESTAMP
```

### Tabela: `clients`
```
- id: INTEGER (PRIMARY KEY)
- name: TEXT (UNIQUE)
- nickname: TEXT
- purchases: INTEGER
- total_value: REAL
- created_at: TIMESTAMP
```

### Tabela: `sales`
```
- id: INTEGER (PRIMARY KEY)
- client_id: INTEGER (FOREIGN KEY)
- product_id: INTEGER (FOREIGN KEY)
- quantity: INTEGER
- unit_price: REAL
- total_price: REAL
- notes: TEXT
- sale_date: TIMESTAMP
```

## 🚀 Como Usar

### Instalação

1. Clone o repositório
2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Execute o aplicativo:
   ```bash
   flutter run
   ```

4. Para gerar APK release:
   ```bash
   flutter build apk --release
   ```

### Fluxo de Uso

1. **Adicionar Produtos**: Navegue para a aba "Produtos" e toque no botão flutuante (+) para criar novo produto

2. **Adicionar Clientes**: Navegue para a aba "Clientes" e toque no botão flutuante (+) para criar novo cliente

3. **Registrar Vendas**: Toque no botão flutuante (+) em qualquer aba (exceto Stats) para registrar uma nova compra

4. **Visualizar Estatísticas**: Acesse a aba "Stats" para ver:
   - Gráfico dos 5 produtos mais vendidos
   - Histórico completo de vendas
   - Opção de filtrar por data (Foco Diário)

5. **Configurações**: Toque o ícone de engrenagem para acessar:
   - Tema (em breve)
   - Foco Diário (filtrar vendas por data)

## 🔄 Sincronização de Dados

- Todas as operações (criar, editar, deletar) atualizam automaticamente as telas relacionadas
- O dashboard recarrega ao adicionar produtos, clientes ou vendas
- Ao deletar um cliente, todas as suas vendas são removidas do histórico e os totais são recalculados

## 🐛 Tratamento de Erros

- Validação de campos obrigatórios
- Nomes únicos para produtos e clientes
- Tratamento de erros de banco de dados
- Feedback visual com SnackBars

## 📱 Requisitos Mínimos

- **Android**: 5.0+ (API 21)
- **iOS**: 11.0+
- **Flutter**: 3.0+
- **Dart**: 3.0+

## 📄 Licença

Este projeto é fornecido como está para fins educacionais.

## 👨‍💻 Autor

Desenvolvimento em Flutter para aprendizado prático de desenvolvimento Android.

---

**Versão**: 1.0.0  
**Data**: Janeiro de 2026  
**Status**: Produção
