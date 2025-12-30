import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// --- CONFIGURACIÓN INICIAL ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // REEMPLAZA ESTO CON TUS CREDENCIALES DE SUPABASE
  await Supabase.initialize(
    url: 'https://imzvxzpdtvllzfpmkilm.supabase.co',
    anonKey: 'sb_publishable_xefs9EwRoQrSjk6aBpgDoA_zZNruwhP',
  );

  runApp(const MyApp());
}

// --- HERRAMIENTA MAGICA PARA COMAS Y PUNTOS ---
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(',', '.');
    if ('.'.allMatches(newText).length > 1) {
      return oldValue;
    }
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Licorería',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Azul Corporativo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- PANTALLA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passCtrl = TextEditingController();
  bool _isObscure = true;

  void _login() {
    if (_passCtrl.text.trim() == 'BBT-2025') {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña incorrecta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Color(0xFF1E88E5),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sistema Licorería',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passCtrl,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña de Acceso',
                    prefixIcon: const Icon(Icons.vpn_key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _login,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('INGRESAR AL SISTEMA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MODELOS DE DATOS ---
class Invoice {
  final int id;
  final String? docNumber;
  final String provider;
  final DateTime date;
  final String type;
  final String currency;
  final double? exchangeRate;
  final double baseAmount;
  final bool hasIva;
  final double manualIva;
  final double liquorTax;
  final bool retentionApplies;
  final String? notes;

  Invoice({
    required this.id,
    this.docNumber,
    required this.provider,
    required this.date,
    required this.type,
    required this.currency,
    this.exchangeRate,
    required this.baseAmount,
    required this.hasIva,
    required this.manualIva,
    required this.liquorTax,
    required this.retentionApplies,
    this.notes,
  });

  double get retentionAmount {
    if (type == 'Nota') return 0.0;
    if (!hasIva) return 0.0;
    return retentionApplies ? manualIva * 0.75 : 0.0;
  }

  double get totalPayable {
    double ivaToSum = (type == 'Nota' || !hasIva) ? 0.0 : manualIva;
    double totalFacial = baseAmount + ivaToSum + liquorTax;
    return totalFacial - retentionAmount;
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      docNumber: map['doc_number'],
      provider: map['provider'],
      date: DateTime.parse(map['invoice_date']),
      type: map['type'],
      currency: map['currency'],
      exchangeRate: map['exchange_rate'] != null
          ? (map['exchange_rate'] as num).toDouble()
          : null,
      baseAmount: (map['base_amount'] as num).toDouble(),
      hasIva: map['has_iva'] ?? false,
      manualIva: (map['manual_iva'] as num?)?.toDouble() ?? 0.0,
      liquorTax: (map['liquor_tax'] as num?)?.toDouble() ?? 0.0,
      retentionApplies: map['retention_applies'] ?? false,
      notes: map['notes'],
    );
  }
}

// --- PANTALLA PRINCIPAL ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    InvoiceListScreen(), // Índice 0: Todas las cuentas
    ProviderSummaryScreen(), // Índice 1: Resumen por Proveedor
    SettingsScreen(), // Índice 2: Configuración
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Proveedores',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}

// --- PANTALLA 2: RESUMEN POR PROVEEDOR ---
class ProviderSummaryScreen extends StatefulWidget {
  const ProviderSummaryScreen({super.key});

  @override
  State<ProviderSummaryScreen> createState() => _ProviderSummaryScreenState();
}

class _ProviderSummaryScreenState extends State<ProviderSummaryScreen> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _getSummaryStream() {
    // Reutilizamos la lógica de traer facturas y pagos para calcular
    return _supabase.from('invoices').stream(primaryKey: ['id']).asyncMap((
      invoices,
    ) async {
      final invoicesWithPayments = await Future.wait(
        invoices.map((inv) async {
          final payments = await _supabase
              .from('payments')
              .select('amount')
              .eq('invoice_id', inv['id']);
          double totalPaid = 0;
          for (var p in payments) {
            totalPaid += (p['amount'] as num).toDouble();
          }
          return {...inv, 'total_paid': totalPaid};
        }),
      );
      return invoicesWithPayments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deuda por Proveedor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getSummaryStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;

          // Agrupar por proveedor
          Map<String, Map<String, dynamic>> providerStats =
              {}; // { 'Polar': { 'debtUSD': 100, 'count': 2 } }

          for (var item in data) {
            final inv = Invoice.fromMap(item);
            final paid = (item['total_paid'] as num).toDouble();
            final balance = inv.totalPayable - paid;

            if (balance > 0.01) {
              // Solo si hay deuda
              if (!providerStats.containsKey(inv.provider)) {
                providerStats[inv.provider] = {'debtUSD': 0.0, 'count': 0};
              }

              double debtInUsd = 0;
              if (inv.currency == 'USD') {
                debtInUsd = balance;
              } else if (inv.currency == 'Bs' &&
                  inv.exchangeRate != null &&
                  inv.exchangeRate! > 0) {
                debtInUsd = balance / inv.exchangeRate!;
              }

              providerStats[inv.provider]!['debtUSD'] += debtInUsd;
              providerStats[inv.provider]!['count'] += 1;
            }
          }

          if (providerStats.isEmpty) {
            return const Center(
              child: Text(
                '¡Excelente! No tienes deudas pendientes.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          // Convertir a lista y ordenar por mayor deuda
          List<MapEntry<String, Map<String, dynamic>>> sortedProviders =
              providerStats.entries.toList()..sort(
                (a, b) => b.value['debtUSD'].compareTo(a.value['debtUSD']),
              );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedProviders.length,
            itemBuilder: (context, index) {
              final entry = sortedProviders[index];
              final name = entry.key;
              final stats = entry.value;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    '${stats['count']} facturas pendientes',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Deuda',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '\$ ${stats['debtUSD'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // NAVEGAR A LA VISTA FILTRADA DE ESTE PROVEEDOR
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          // Reutilizamos la misma pantalla de lista pero con un parámetro de filtro
                          appBar: AppBar(
                            title: Text(name),
                          ), // AppBar simple para la subpantalla
                          body: InvoiceListScreen(
                            providerFilter: name,
                          ), // Pasamos el filtro
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- LISTA DE FACTURAS (REUTILIZABLE Y FILTRABLE) ---
class InvoiceListScreen extends StatefulWidget {
  final String? providerFilter; // Parámetro opcional para filtrar
  const InvoiceListScreen({super.key, this.providerFilter});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = '';
  late Stream<List<Map<String, dynamic>>> _currentStream;

  @override
  void initState() {
    super.initState();
    _refreshStream();
  }

  void _refreshStream() {
    setState(() {
      var query = _supabase
          .from('invoices')
          .stream(primaryKey: ['id'])
          .order('invoice_date', ascending: false);

      // La libreria stream de supabase no soporta .eq() directo en el stream builder facilmente para filtros dinamicos complejos
      // Lo manejaremos filtrando la data en memoria (rápido para < 5000 registros)
      // O si preferimos, podríamos usar .eq si el filtro no cambia, pero para simplificar la UI reactiva:

      _currentStream = query.asyncMap((invoices) async {
        final invoicesWithPayments = await Future.wait(
          invoices.map((inv) async {
            final payments = await _supabase
                .from('payments')
                .select('amount')
                .eq('invoice_id', inv['id']);
            double totalPaid = 0;
            for (var p in payments) {
              totalPaid += (p['amount'] as num).toDouble();
            }
            return {...inv, 'total_paid': totalPaid};
          }),
        );
        return invoicesWithPayments;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si hay filtro de proveedor, no mostramos el Scaffold completo con AppBar de búsqueda
    // porque ya estamos dentro de otra pantalla que tiene AppBar.
    // Usaremos un widget contenedor.

    // Si ES la pantalla principal (sin filtro), usamos Scaffold completo.
    // Si TIENE filtro, devolvemos solo el contenido del body.

    Widget content = StreamBuilder<List<Map<String, dynamic>>>(
      stream: _currentStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData)
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );

        final data = snapshot.data!;

        // FILTRADO LOCAL
        final filteredData = data.where((inv) {
          final provider = inv['provider'].toString();
          // 1. Filtro estricto de proveedor (si venimos de la pantalla de resumen)
          if (widget.providerFilter != null &&
              provider != widget.providerFilter) {
            return false;
          }
          // 2. Filtro de búsqueda (si estamos en la pantalla principal)
          if (widget.providerFilter == null) {
            final search = _searchQuery.toLowerCase();
            final doc = inv['doc_number']?.toString().toLowerCase() ?? '';
            return provider.toLowerCase().contains(search) ||
                doc.contains(search);
          }
          return true;
        }).toList();

        // Cálculo de totales (Solo se muestran si NO estamos filtrando, o si queremos ver el total de ese proveedor)
        double totalDebtUsd = 0;
        for (var item in filteredData) {
          final inv = Invoice.fromMap(item);
          final paid = (item['total_paid'] as num).toDouble();
          final balance = inv.totalPayable - paid;
          if (balance > 0.01) {
            if (inv.currency == 'USD') {
              totalDebtUsd += balance;
            } else if (inv.currency == 'Bs' &&
                inv.exchangeRate != null &&
                inv.exchangeRate! > 0) {
              totalDebtUsd += balance / inv.exchangeRate!;
            }
          }
        }

        if (filteredData.isEmpty) {
          return const Center(
            child: Text(
              'No hay registros encontrados',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.only(
            bottom: widget.providerFilter == null ? 80 : 20,
          ), // Espacio para FAB solo si no hay filtro
          children: [
            // TARJETA DE RESUMEN (Visible siempre, muestra el total de lo que se ve en pantalla)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.providerFilter != null
                        ? [
                            Colors.orange.shade800,
                            Colors.deepOrange,
                          ] // Naranja para modo proveedor
                        : [
                            const Color(0xFF1565C0),
                            const Color(0xFF1E88E5),
                          ], // Azul para modo general
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.providerFilter != null
                              ? 'Deuda Total con ${widget.providerFilter}'
                              : 'Deuda Total Estimada',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$ ${totalDebtUsd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.providerFilter != null
                            ? Icons.person
                            : Icons.attach_money,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LISTA DE FACTURAS
            ...filteredData.map((item) {
              final invoice = Invoice.fromMap(item);
              final totalPaid = (item['total_paid'] as num).toDouble();
              final balance = invoice.totalPayable - totalPaid;
              final isPaid = balance <= 0.01;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: InkWell(
                  onTap: () => _showDetail(context, invoice),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.provider,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (invoice.docNumber != null &&
                                      invoice.docNumber!.isNotEmpty)
                                    Text(
                                      '#${invoice.docNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(invoice.date),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PAGADA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PENDIENTE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saldo Pendiente:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${invoice.currency} ${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (!isPaid) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showInvoiceForm(
                                    context,
                                    invoice: invoice,
                                  ),
                                  child: const Text('Editar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _showPaymentModal(
                                    context,
                                    invoice: invoice,
                                    maxAmount: balance,
                                  ),
                                  icon: const Icon(
                                    Icons.attach_money,
                                    size: 16,
                                  ),
                                  label: const Text('Abonar'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );

    // ESTRUCTURA FINAL: Si es modo filtro, solo devolvemos el contenido. Si es modo principal, devolvemos Scaffold.
    if (widget.providerFilter != null) {
      return Container(color: Colors.grey[100], child: content);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text(
              'Cuentas por Pagar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar proveedor, número...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
            ),
          ),
          SliverFillRemaining(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInvoiceForm(context),
        label: const Text('Nueva Cuenta'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showInvoiceForm(
    BuildContext context, {
    Invoice? invoice,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => InvoiceForm(existingInvoice: invoice),
    );
    _refreshStream();
  }

  Future<void> _showPaymentModal(
    BuildContext context, {
    required Invoice invoice,
    required double maxAmount,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PaymentDialog(invoice: invoice, maxAmount: maxAmount),
      ),
    );
    _refreshStream();
  }

  Future<void> _showDetail(BuildContext context, Invoice invoice) async {
    await showDialog(
      context: context,
      builder: (context) => InvoiceDetailDialog(invoice: invoice),
    );
    _refreshStream();
  }
}

// --- FORMULARIO DE FACTURA ---
class InvoiceForm extends StatefulWidget {
  final Invoice? existingInvoice;
  const InvoiceForm({super.key, this.existingInvoice});
  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _docCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  final _ivaCtrl = TextEditingController();
  final _liquorTaxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final TextEditingController _providerTypeAheadCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _type = 'Factura';
  String _currency = 'USD';
  String? _selectedProvider;
  List<String> _providersList = [];
  bool _hasIva = true;
  bool _retentionApplies = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _docCtrl.text = inv.docNumber ?? '';
      _selectedProvider = inv.provider;
      _providerTypeAheadCtrl.text = inv.provider;

      _baseCtrl.text = inv.baseAmount.toString();
      _ivaCtrl.text = inv.manualIva.toString();
      _liquorTaxCtrl.text = inv.liquorTax > 0 ? inv.liquorTax.toString() : '';
      _notesCtrl.text = inv.notes ?? '';
      _rateCtrl.text = inv.exchangeRate?.toString() ?? '';
      _selectedDate = inv.date;
      _type = inv.type;
      _currency = inv.currency;
      _hasIva = inv.hasIva;
      _retentionApplies = inv.retentionApplies;
    }
  }

  Future<void> _fetchProviders() async {
    final res = await Supabase.instance.client
        .from('providers')
        .select()
        .order('name');
    if (mounted) {
      setState(() {
        _providersList = (res as List).map((e) => e['name'] as String).toList();
      });
    }
  }

  void _calculateIva() {
    if (_type == 'Factura' && _hasIva && _baseCtrl.text.isNotEmpty) {
      final base = double.tryParse(_baseCtrl.text) ?? 0;
      setState(() {
        _ivaCtrl.text = (base * 0.16).toStringAsFixed(2);
      });
    } else {
      if (_ivaCtrl.text.isNotEmpty && (!_hasIva || _type == 'Nota')) {
        _ivaCtrl.text = '0.00';
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final providerToSave = _selectedProvider ?? _providerTypeAheadCtrl.text;
    if (providerToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un proveedor')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final isNota = _type == 'Nota';
      final finalHasIva = isNota ? false : _hasIva;
      final finalRetention = isNota ? false : _retentionApplies;
      final finalManualIva = (isNota || !finalHasIva)
          ? 0.0
          : double.parse(_ivaCtrl.text.isEmpty ? '0' : _ivaCtrl.text);
      final finalLiquorTax = double.tryParse(_liquorTaxCtrl.text) ?? 0.0;

      final data = {
        'doc_number': _docCtrl.text,
        'provider': providerToSave,
        'invoice_date': _selectedDate.toIso8601String(),
        'type': _type,
        'currency': _currency,
        'exchange_rate': _currency == 'Bs' && _rateCtrl.text.isNotEmpty
            ? double.parse(_rateCtrl.text)
            : null,
        'base_amount': double.parse(_baseCtrl.text),
        'has_iva': finalHasIva,
        'manual_iva': finalManualIva,
        'liquor_tax': finalLiquorTax,
        'retention_applies': finalRetention,
        'notes': _notesCtrl.text,
      };

      if (widget.existingInvoice != null) {
        await Supabase.instance.client
            .from('invoices')
            .update(data)
            .eq('id', widget.existingInvoice!.id);
      } else {
        await Supabase.instance.client.from('invoices').insert(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingInvoice != null ? 'Editar Cuenta' : 'Nueva Cuenta',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _docCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nº Doc',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: _selectedDate,
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _providersList.where((String option) {
                  return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedProvider = selection;
                  _providerTypeAheadCtrl.text = selection;
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    if (controller.text.isEmpty &&
                        _providerTypeAheadCtrl.text.isNotEmpty) {
                      controller.text = _providerTypeAheadCtrl.text;
                    }
                    controller.addListener(() {
                      _selectedProvider = controller.text;
                      _providerTypeAheadCtrl.text = controller.text;
                    });

                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        prefixIcon: Icon(Icons.store),
                        hintText: 'Escribe para buscar...',
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    );
                  },
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: ['Factura', 'Nota']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _type = v!;
                      if (_type == 'Nota') {
                        _hasIva = false;
                        _retentionApplies = false;
                        _ivaCtrl.text = '0.00';
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'Moneda'),
                    items: ['USD', 'Bs']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),
            if (_currency == 'Bs') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateCtrl,
                inputFormatters: [DecimalInputFormatter()],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tasa de Cambio',
                  suffixText: 'Bs/\$',
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseCtrl,
              inputFormatters: [DecimalInputFormatter()],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Monto Base (Subtotal)',
                prefixText: _currency == 'USD' ? '\$ ' : 'Bs ',
              ),
              onChanged: (_) => _calculateIva(),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),

            // CAMPO DE IMPUESTO AL LICOR
            const SizedBox(height: 16),
            TextFormField(
              controller: _liquorTaxCtrl,
              inputFormatters: [DecimalInputFormatter()],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Impuesto al Licor (Opcional)',
                prefixIcon: const Icon(Icons.liquor),
                prefixText: _currency == 'USD' ? '\$ ' : 'Bs ',
                helperText: 'Impuesto adicional fuera de la base imponible',
              ),
            ),

            if (_type == 'Factura') ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Aplica IVA (16%)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: _hasIva,
                      onChanged: (v) => setState(() {
                        _hasIva = v;
                        _calculateIva();
                      }),
                    ),
                    if (_hasIva) ...[
                      TextFormField(
                        controller: _ivaCtrl,
                        inputFormatters: [DecimalInputFormatter()],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monto IVA',
                          fillColor: Colors.white,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Retención 75%'),
                        subtitle: const Text('Contribuyente Especial'),
                        value: _retentionApplies,
                        onChanged: (v) => setState(() => _retentionApplies = v),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GUARDAR CUENTA'),
            ),
            if (widget.existingInvoice != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Eliminar Factura',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Eliminar Factura?'),
                      content: const Text(
                        'Esta acción borrará la factura y todos sus abonos. No se puede deshacer.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() => _loading = true);
                    await Supabase.instance.client
                        .from('invoices')
                        .delete()
                        .eq('id', widget.existingInvoice!.id);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// --- CONFIGURACIÓN ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Proveedores'),
            Tab(text: 'Métodos de Pago'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GenericConfigList(tableName: 'providers', title: 'Proveedor'),
          GenericConfigList(tableName: 'payment_methods', title: 'Método'),
        ],
      ),
    );
  }
}

class GenericConfigList extends StatefulWidget {
  final String tableName;
  final String title;
  const GenericConfigList({
    super.key,
    required this.tableName,
    required this.title,
  });

  @override
  State<GenericConfigList> createState() => _GenericConfigListState();
}

class _GenericConfigListState extends State<GenericConfigList> {
  final _textCtrl = TextEditingController();

  Future<void> _addOrUpdate({int? id, String? currentName}) async {
    _textCtrl.text = currentName ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          id == null ? 'Agregar ${widget.title}' : 'Editar ${widget.title}',
        ),
        content: TextField(
          controller: _textCtrl,
          decoration: InputDecoration(labelText: 'Nombre del ${widget.title}'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_textCtrl.text.isNotEmpty) {
                try {
                  if (id == null) {
                    await Supabase.instance.client
                        .from(widget.tableName)
                        .insert({'name': _textCtrl.text});
                  } else {
                    await Supabase.instance.client
                        .from(widget.tableName)
                        .update({'name': _textCtrl.text})
                        .eq('id', id);
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    _textCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from(widget.tableName)
        .stream(primaryKey: ['id'])
        .order('name');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: () => _addOrUpdate(),
            icon: const Icon(Icons.add),
            label: Text('Agregar Nuevo ${widget.title}'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(item['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _addOrUpdate(
                              id: item['id'],
                              currentName: item['name'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('¿Eliminar?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Sí'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true)
                                await Supabase.instance.client
                                    .from(widget.tableName)
                                    .delete()
                                    .eq('id', item['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- MODAL DE PAGO (CREAR / EDITAR) ---
class PaymentDialog extends StatefulWidget {
  final Invoice invoice;
  final double maxAmount;
  final Map<String, dynamic>? existingPayment;

  const PaymentDialog({
    super.key,
    required this.invoice,
    required this.maxAmount,
    this.existingPayment,
  });
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountCtrl = TextEditingController();
  String? _method;
  DateTime _paymentDate = DateTime.now();
  List<String> _methodsList = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchMethods();
    if (widget.existingPayment != null) {
      _amountCtrl.text = widget.existingPayment!['amount'].toString();
      _paymentDate = DateTime.parse(widget.existingPayment!['payment_date']);
      _method = widget.existingPayment!['method'];
    }
  }

  Future<void> _fetchMethods() async {
    final res = await Supabase.instance.client
        .from('payment_methods')
        .select()
        .order('name');
    setState(() {
      _methodsList = (res as List).map((e) => e['name'] as String).toList();
      if (_method == null && _methodsList.isNotEmpty) _method = _methodsList[0];
    });
  }

  Future<void> _pay() async {
    if (_amountCtrl.text.isEmpty || _method == null) return;
    setState(() => _loading = true);
    try {
      final paymentData = {
        'invoice_id': widget.invoice.id,
        'amount': double.parse(_amountCtrl.text),
        'method': _method,
        'payment_date': _paymentDate.toIso8601String(),
      };

      if (widget.existingPayment != null) {
        await Supabase.instance.client
            .from('payments')
            .update(paymentData)
            .eq('id', widget.existingPayment!['id']);
      } else {
        await Supabase.instance.client.from('payments').insert(paymentData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingPayment != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? 'Editar Abono' : 'Registrar Abono',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (!isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Deuda Pendiente',
                    style: TextStyle(color: Colors.green),
                  ),
                  Text(
                    '${widget.invoice.currency} ${widget.maxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: _paymentDate,
              );
              if (picked != null) setState(() => _paymentDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha del Abono',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd/MM/yyyy').format(_paymentDate)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            inputFormatters: [DecimalInputFormatter()], // FIX COMAS
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Monto a Abonar',
              prefixText: widget.invoice.currency == 'USD' ? '\$ ' : 'Bs ',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _method,
            items: _methodsList
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _method = v),
            decoration: const InputDecoration(labelText: 'Método de Pago'),
            hint: const Text('Cargando métodos...'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _pay,
            child: Text(isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR PAGO'),
          ),
        ],
      ),
    );
  }
}

// --- DETALLE DE FACTURA E HISTORIAL ACTUALIZADO ---
class InvoiceDetailDialog extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('invoice_id', invoice.id)
        .order('payment_date', ascending: false);

    final double totalFacial = invoice.type == 'Nota'
        ? invoice.baseAmount
        : invoice.baseAmount + invoice.manualIva + invoice.liquorTax;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 800),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              );

            final payments = snapshot.data!;
            double totalPaid = 0;
            for (var p in payments) {
              totalPaid += (p['amount'] as num).toDouble();
            }
            final double remainingBalance = invoice.totalPayable - totalPaid;
            final bool isPaid = remainingBalance <= 0.01;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.provider,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (invoice.docNumber != null)
                              Text(
                                'Doc: ${invoice.docNumber}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        _row(
                          'Base Imponible (+)',
                          invoice.baseAmount,
                          invoice.currency,
                        ),
                        if (invoice.type == 'Factura' && invoice.hasIva)
                          _row(
                            'IVA 16% (+)',
                            invoice.manualIva,
                            invoice.currency,
                          ),

                        if (invoice.liquorTax > 0)
                          _row(
                            'Impuesto Licor (+)',
                            invoice.liquorTax,
                            invoice.currency,
                            color: Colors.purple,
                          ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(),
                        ),
                        _row(
                          'Total Facial (=)',
                          totalFacial,
                          invoice.currency,
                          isBold: true,
                        ),

                        if (invoice.type == 'Factura' &&
                            invoice.retentionApplies &&
                            invoice.hasIva) ...[
                          const SizedBox(height: 8),
                          _row(
                            'Retención IVA 75% (-)',
                            -invoice.retentionAmount,
                            invoice.currency,
                            color: Colors.orange[800]!,
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(thickness: 2),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL A PAGAR:',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1565C0),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${invoice.currency} ${invoice.totalPayable.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isPaid ? '¡FACTURA PAGADA!' : 'SALDO PENDIENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                        Text(
                          '${invoice.currency} ${remainingBalance < 0 ? 0 : remainingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Historial de Abonos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  Expanded(
                    child: payments.isEmpty
                        ? const Center(
                            child: Text(
                              'Sin abonos registrados',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemCount: payments.length,
                            itemBuilder: (context, index) {
                              final p = payments[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                title: Text('${p['method']}'),
                                subtitle: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(DateTime.parse(p['payment_date'])),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(p['amount'] as num).toStringAsFixed(2)} ${invoice.currency}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final del = await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              '¿Eliminar abono?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Sí'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (del == true)
                                          await Supabase.instance.client
                                              .from('payments')
                                              .delete()
                                              .eq('id', p['id']);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(
                                          ctx,
                                        ).viewInsets.bottom,
                                      ),
                                      child: PaymentDialog(
                                        invoice: invoice,
                                        maxAmount: 0,
                                        existingPayment: p,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(
    String label,
    double amount,
    String currency, {
    bool isBold = false,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: 13,
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
