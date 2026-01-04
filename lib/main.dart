import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// IMPORTANTE: Librería para el idioma del calendario
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- 1. CONFIGURACIÓN INICIAL ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  // TODO: REEMPLAZA CON TUS CREDENCIALES REALES
  await Supabase.initialize(
    url: 'https://imzvxzpdtvllzfpmkilm.supabase.co',
    anonKey: 'sb_publishable_xefs9EwRoQrSjk6aBpgDoA_zZNruwhP',
  );

  runApp(const MyApp());
}

// --- 2. TEMA Y ESTILOS ---
class AppColors {
  static const primary = Color(0xFF0052CC); // Azul Institucional
  static const primaryDark = Color(0xFF0747A6);
  static const background = Color(0xFFF4F5F7); // Gris Muy Claro
  static const surface = Colors.white;
  static const textDark = Color(0xFF172B4D);
  static const textGrey = Color(0xFF6B778C);
  static const border = Color(0xFFDFE1E6);
  static const success = Color(0xFF00875A);
  static const error = Color(0xFFDE350B);
  static const warning = Color(0xFFFF991F);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUENTAS POR PAGAR',
      debugShowCheckedModeBanner: false,
      // --- IDIOMA ESPAÑOL ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      // ----------------------
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textGrey),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- 3. UTILIDADES ---
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(',', '.');
    if ('.'.allMatches(newText).length > 1) return oldValue;
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// --- 4. MODELOS ---
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

  double get retentionAmount => (type == 'Nota' || !hasIva)
      ? 0.0
      : (retentionApplies ? manualIva * 0.75 : 0.0);

  // Total bruto antes de retenciones
  double get subTotal =>
      baseAmount + ((type == 'Nota' || !hasIva) ? 0.0 : manualIva) + liquorTax;

  // Total líquido a pagar
  double get totalPayable => subTotal - retentionAmount;

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      docNumber: map['doc_number'],
      provider: map['provider'] ?? 'Desconocido',
      date: DateTime.tryParse(map['invoice_date'] ?? '') ?? DateTime.now(),
      type: map['type'] ?? 'Factura',
      currency: map['currency'] ?? 'USD',
      exchangeRate: map['exchange_rate'] != null
          ? (map['exchange_rate'] as num).toDouble()
          : null,
      baseAmount: (map['base_amount'] as num?)?.toDouble() ?? 0.0,
      hasIva: map['has_iva'] ?? false,
      manualIva: (map['manual_iva'] as num?)?.toDouble() ?? 0.0,
      liquorTax: (map['liquor_tax'] as num?)?.toDouble() ?? 0.0,
      retentionApplies: map['retention_applies'] ?? false,
      notes: map['notes'],
    );
  }
}

// --- 5. PANTALLAS ---

// A. LOGIN
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
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainLayout()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña incorrecta'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const Icon(Icons.security, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'CUENTAS POR PAGAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _passCtrl,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('ENTRAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// B. LAYOUT PRINCIPAL
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;
  final List<Widget> _views = [
    const DashboardView(),
    const InvoiceListView(),
    const PaymentsView(),
    const ProvidersListView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              groupAlignment: -0.9,
              leading: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: Text('Resumen'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: Text('Cuentas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Abonos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt_rounded),
                  label: Text('Prov.'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: Text('Config'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: _views[_index]),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: _views[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Resumen',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Cuentas',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              label: 'Abonos',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Prov.',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Config',
            ),
          ],
        ),
      );
    }
  }
}

// C. FORMULARIO FACTURA
class InvoiceForm extends StatefulWidget {
  final Invoice? existing;
  const InvoiceForm({super.key, this.existing});
  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _docCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  final _ivaCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _provCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _type = 'Factura';
  String _currency = 'USD';
  String? _selectedProv;
  List<String> _provs = [];
  bool _iva = true;
  bool _ret = false;
  bool _loading = false;
  bool _manualIvaEdit = false;

  double _prevTotal = 0;
  double _prevRetAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadProvs();
    if (widget.existing != null) {
      final i = widget.existing!;
      _docCtrl.text = i.docNumber ?? '';
      _provCtrl.text = i.provider;
      _selectedProv = i.provider;
      _baseCtrl.text = i.baseAmount.toString();
      _ivaCtrl.text = i.manualIva.toString();
      _taxCtrl.text = i.liquorTax > 0 ? i.liquorTax.toString() : '';
      _noteCtrl.text = i.notes ?? '';
      _rateCtrl.text = i.exchangeRate?.toString() ?? '';
      _date = i.date;
      _type = i.type;
      _currency = i.currency;
      _iva = i.hasIva;
      _ret = i.retentionApplies;
      _manualIvaEdit = true;
    }
    _baseCtrl.addListener(_onBaseAmountChanged);
    _updatePreview();
  }

  @override
  void dispose() {
    _baseCtrl.removeListener(_onBaseAmountChanged);
    super.dispose();
  }

  void _onBaseAmountChanged() {
    if (_type == 'Factura' && _iva && !_manualIvaEdit) {
      double base = double.tryParse(_baseCtrl.text.replaceAll(',', '.')) ?? 0;
      double autoIva = base * 0.16;
      _ivaCtrl.text = autoIva == 0 ? '' : autoIva.toStringAsFixed(2);
    }
    _updatePreview();
  }

  Future<void> _loadProvs() async {
    final res = await Supabase.instance.client
        .from('providers')
        .select()
        .order('name');
    if (mounted)
      setState(
        () => _provs = (res as List).map((e) => e['name'] as String).toList(),
      );
  }

  void _updatePreview() {
    double base = double.tryParse(_baseCtrl.text.replaceAll(',', '.')) ?? 0;
    double tax = double.tryParse(_taxCtrl.text.replaceAll(',', '.')) ?? 0;
    double ivaCalc = 0;
    double retCalc = 0;

    if (_type == 'Factura' && _iva) {
      ivaCalc = double.tryParse(_ivaCtrl.text.replaceAll(',', '.')) ?? 0;
      if (_ret) retCalc = ivaCalc * 0.75;
    }

    setState(() {
      _prevRetAmount = retCalc;
      _prevTotal = (base + ivaCalc + tax) - retCalc;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = _selectedProv ?? _provCtrl.text;
    if (prov.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falta Proveedor')));
      return;
    }
    setState(() => _loading = true);

    try {
      final isNota = _type == 'Nota';
      final data = {
        'doc_number': _docCtrl.text,
        'provider': prov,
        'invoice_date': _date.toIso8601String(),
        'type': _type,
        'currency': _currency,
        'exchange_rate': _currency == 'Bs' && _rateCtrl.text.isNotEmpty
            ? double.parse(_rateCtrl.text.replaceAll(',', '.'))
            : null,
        'base_amount':
            double.tryParse(_baseCtrl.text.replaceAll(',', '.')) ?? 0,
        'has_iva': isNota ? false : _iva,
        'manual_iva': (isNota || !_iva)
            ? 0
            : double.tryParse(_ivaCtrl.text.replaceAll(',', '.')) ?? 0,
        'liquor_tax': double.tryParse(_taxCtrl.text.replaceAll(',', '.')) ?? 0,
        'retention_applies': isNota ? false : _ret,
        'notes': _noteCtrl.text,
      };

      if (widget.existing != null) {
        await Supabase.instance.client
            .from('invoices')
            .update(data)
            .eq('id', widget.existing!.id);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existing != null ? 'Editar Documento' : 'Registrar Cuenta',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('DATOS GENERALES'),
                        Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Autocomplete<String>(
                                  optionsBuilder: (v) => v.text.isEmpty
                                      ? const Iterable.empty()
                                      : _provs.where(
                                          (p) => p.toLowerCase().contains(
                                            v.text.toLowerCase(),
                                          ),
                                        ),
                                  onSelected: (v) => setState(() {
                                    _selectedProv = v;
                                    _provCtrl.text = v;
                                  }),
                                  fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                                    if (ctrl.text.isEmpty &&
                                        _provCtrl.text.isNotEmpty)
                                      ctrl.text = _provCtrl.text;
                                    ctrl.addListener(() {
                                      _selectedProv = ctrl.text;
                                      _provCtrl.text = ctrl.text;
                                    });
                                    return TextFormField(
                                      controller: ctrl,
                                      focusNode: focus,
                                      decoration: const InputDecoration(
                                        labelText: 'Proveedor',
                                        hintText: 'Ej. Polar',
                                        prefixIcon: Icon(
                                          Icons.storefront_outlined,
                                        ),
                                      ),
                                      validator: (v) =>
                                          v!.isEmpty ? 'Requerido' : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _docCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nº Documento',
                                          prefixIcon: Icon(Icons.tag),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildDateInput()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        _sectionHeader('MONTOS'),
                        Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'Factura',
                                      label: Text('Factura'),
                                    ),
                                    ButtonSegment(
                                      value: 'Nota',
                                      label: Text('Nota Entrega'),
                                    ),
                                  ],
                                  selected: {_type},
                                  onSelectionChanged:
                                      (Set<String> newSelection) {
                                        setState(() {
                                          _type = newSelection.first;
                                          if (_type == 'Nota') {
                                            _iva = false;
                                            _ret = false;
                                            _ivaCtrl.clear();
                                          } else {
                                            _iva = true;
                                            _onBaseAmountChanged();
                                          }
                                          _updatePreview();
                                        });
                                      },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    side: MaterialStateProperty.all(
                                      BorderSide(
                                        color: AppColors.primary.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: DropdownButtonFormField<String>(
                                        value: _currency,
                                        decoration: const InputDecoration(
                                          labelText: 'Moneda',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 16,
                                          ),
                                        ),
                                        items: ['USD', 'Bs']
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(
                                                  c,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _currency = v!),
                                      ),
                                    ),
                                    if (_currency == 'Bs') ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _rateCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            DecimalInputFormatter(),
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Tasa (Bs)',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _baseCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [DecimalInputFormatter()],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Monto Base',
                                    prefixText: _currency == 'USD'
                                        ? '\$ '
                                        : 'Bs ',
                                  ),
                                  onChanged: (_) => _updatePreview(),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _taxCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [DecimalInputFormatter()],
                                  decoration: const InputDecoration(
                                    labelText: 'Impuesto Licor (Opcional)',
                                    prefixIcon: Icon(Icons.liquor_outlined),
                                  ),
                                  onChanged: (_) => _updatePreview(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_type == 'Factura') ...[
                          const SizedBox(height: 24),
                          _sectionHeader('IMPUESTOS'),
                          Card(
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    title: const Text(
                                      "Aplicar IVA (16%)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    value: _iva,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() {
                                      _iva = v!;
                                      if (_iva)
                                        _onBaseAmountChanged();
                                      else {
                                        _ivaCtrl.clear();
                                        _ret = false;
                                      }
                                      _updatePreview();
                                    }),
                                  ),
                                  if (_iva) ...[
                                    TextFormField(
                                      controller: _ivaCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        DecimalInputFormatter(),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Monto IVA',
                                        prefixIcon: Icon(Icons.percent),
                                      ),
                                      onChanged: (val) {
                                        setState(() => _manualIvaEdit = true);
                                        _updatePreview();
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    SwitchListTile(
                                      title: const Text(
                                        'Retención IVA (75%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Contribuyente Especial',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                      value: _ret,
                                      activeColor: AppColors.warning,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (v) => setState(() {
                                        _ret = v;
                                        _updatePreview();
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        _sectionHeader('OBSERVACIONES'),
                        Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText:
                                    'Notas adicionales (Ej: Compra de vinos, Reparación)...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_ret)
                      Text(
                        "- Retención: ${NumberFormat("#,##0.00").format(_prevRetAmount)}",
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const Text(
                      'TOTAL A PAGAR',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_currency ${NumberFormat("#,##0.00").format(_prevTotal)}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('GUARDAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textGrey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDateInput() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDate: _date,
          locale: const Locale('es'),
        );
        if (d != null) setState(() => _date = d);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          DateFormat('dd MMM yyyy', 'es').format(_date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// D. DASHBOARD
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});
  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('invoices')
        .stream(primaryKey: ['id'])
        .asyncMap((invoices) async {
          final withPayments = await Future.wait(
            invoices.map((inv) async {
              final payments = await Supabase.instance.client
                  .from('payments')
                  .select('amount')
                  .eq('invoice_id', inv['id']);
              double paid = 0;
              for (var p in payments) paid += (p['amount'] as num).toDouble();
              return {...inv, 'paid': paid};
            }),
          );
          return withPayments;
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Principal')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          double debtUSD = 0;
          int count = 0;
          Map<String, double> topDebtors = {};

          for (var item in snapshot.data!) {
            final inv = Invoice.fromMap(item);
            final balance = inv.totalPayable - (item['paid'] as num).toDouble();
            if (balance > 0.01) {
              double usd = (inv.currency == 'USD')
                  ? balance
                  : (inv.exchangeRate != null && inv.exchangeRate! > 0)
                  ? balance / inv.exchangeRate!
                  : 0;
              debtUSD += usd;
              count++;
              topDebtors[inv.provider] = (topDebtors[inv.provider] ?? 0) + usd;
            }
          }
          var sorted = topDebtors.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          if (sorted.length > 5) sorted = sorted.sublist(0, 5);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'DEUDA TOTAL (USD)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${NumberFormat("#,##0.00", "en_US").format(debtUSD)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count Facturas Pendientes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: sorted.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Sin deudas pendientes',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                        )
                      : Column(
                          children: sorted.map((e) {
                            final max = sorted.first.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '\$${NumberFormat("#,##0.00").format(e.value)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: e.value / max,
                                      minHeight: 6,
                                      color: AppColors.primary,
                                      backgroundColor: AppColors.background,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvoiceForm()),
        ),
        label: const Text('Nueva Factura'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// E. LISTADO DE CUENTAS
class InvoiceListView extends StatefulWidget {
  final String? providerFilter;
  const InvoiceListView({super.key, this.providerFilter});
  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> {
  final _supabase = Supabase.instance.client;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final stream = _supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .order('invoice_date', ascending: false)
        .asyncMap((invoices) async {
          final withPayments = await Future.wait(
            invoices.map((inv) async {
              final payments = await _supabase
                  .from('payments')
                  .select('amount')
                  .eq('invoice_id', inv['id']);
              double paid = 0;
              for (var p in payments) paid += (p['amount'] as num).toDouble();
              return {...inv, 'paid': paid};
            }),
          );
          return withPayments;
        });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.providerFilter ?? 'Cuentas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final filtered = snapshot.data!.where((item) {
            final inv = Invoice.fromMap(item);
            if (widget.providerFilter != null &&
                inv.provider != widget.providerFilter)
              return false;
            if (_search.isNotEmpty)
              return inv.provider.toLowerCase().contains(_search) ||
                  (inv.docNumber ?? '').toLowerCase().contains(_search);
            return true;
          }).toList();

          if (filtered.isEmpty)
            return const Center(
              child: Text(
                'Sin registros',
                style: TextStyle(color: Colors.grey),
              ),
            );

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final inv = Invoice.fromMap(item);
              final paid = (item['paid'] as num).toDouble();
              final balance = inv.totalPayable - paid;
              final isPaid = balance <= 0.01;

              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => InvoiceDetailDialog(invoice: inv),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.provider,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${inv.currency} ${NumberFormat("#,##0.00").format(balance)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isPaid
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${inv.type} #${inv.docNumber ?? "S/N"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM', 'es').format(inv.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                        if (inv.notes != null && inv.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 14,
                                  color: AppColors.textGrey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    inv.notes!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isPaid) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InvoiceForm(existing: inv),
                                    ),
                                  ),
                                  child: const Text('Editar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(
                                          ctx,
                                        ).viewInsets.bottom,
                                      ),
                                      child: PaymentDialog(
                                        invoice: inv,
                                        maxAmount: balance,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.attach_money,
                                    size: 16,
                                  ),
                                  label: const Text('Abonar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
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
            },
          );
        },
      ),
    );
  }
}

// F. MODAL PAGO (REPARADO Y CON AUTO-RELLENADO)
class PaymentDialog extends StatefulWidget {
  final Invoice invoice;
  final double maxAmount;
  final Map<String, dynamic>? existing;
  const PaymentDialog({
    super.key,
    required this.invoice,
    required this.maxAmount,
    this.existing,
  });
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amt = TextEditingController();
  final _note = TextEditingController();
  String? _method;
  DateTime _date = DateTime.now();
  List<String> _methods = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMethods();
    // AUTO-RELLENAR: Si no es edición, ponemos el monto total pendiente
    if (widget.existing != null) {
      _amt.text = widget.existing!['amount'].toString();
      _note.text = widget.existing!['note'] ?? '';
      _method = widget.existing!['method'];
      _date = DateTime.parse(widget.existing!['payment_date']);
    } else {
      _amt.text = widget.maxAmount.toStringAsFixed(2);
    }
  }

  Future<void> _loadMethods() async {
    final r = await Supabase.instance.client
        .from('payment_methods')
        .select()
        .order('name');
    if (mounted)
      setState(() {
        _methods = (r as List).map((e) => e['name'] as String).toList();
        if (_method == null && _methods.isNotEmpty) _method = _methods[0];
      });
  }

  Future<void> _save() async {
    if (_amt.text.isEmpty || _method == null) return;
    setState(() => _loading = true);
    final data = {
      'invoice_id': widget.invoice.id,
      'amount': double.parse(_amt.text.replaceAll(',', '.')),
      'method': _method,
      'payment_date': _date.toIso8601String(),
      'note': _note.text,
    };
    if (widget.existing != null)
      await Supabase.instance.client
          .from('payments')
          .update(data)
          .eq('id', widget.existing!['id']);
    else
      await Supabase.instance.client.from('payments').insert(data);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing != null ? 'Editar Pago' : 'Registrar Pago',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (widget.existing == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pendiente por pagar',
                    style: TextStyle(color: AppColors.success),
                  ),
                  Text(
                    '${widget.invoice.currency} ${NumberFormat("#,##0.00").format(widget.maxAmount)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amt,
            keyboardType: TextInputType.number,
            inputFormatters: [DecimalInputFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Monto a Abonar',
              prefixText: widget.invoice.currency == 'USD' ? '\$ ' : 'Bs ',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: _date,
                      locale: const Locale('es'),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMM yyyy', 'es').format(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _method,
                  items: _methods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _method = v),
                  decoration: const InputDecoration(
                    labelText: 'Método',
                    prefixIcon: Icon(Icons.wallet),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Nota (Opcional)',
              prefixIcon: Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: Text(
              widget.existing != null ? 'GUARDAR CAMBIOS' : 'PROCESAR PAGO',
            ),
          ),
        ],
      ),
    );
  }
}

// G. VISTA PROVEEDORES
class ProvidersListView extends StatefulWidget {
  const ProvidersListView({super.key});
  @override
  State<ProvidersListView> createState() => _ProvidersListViewState();
}

class _ProvidersListViewState extends State<ProvidersListView> {
  final _supabase = Supabase.instance.client;
  String _filter = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filtrar...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _filter = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('invoices').stream(primaryKey: ['id']).asyncMap((
          invoices,
        ) async {
          final withPayments = await Future.wait(
            invoices.map((inv) async {
              final payments = await _supabase
                  .from('payments')
                  .select('amount')
                  .eq('invoice_id', inv['id']);
              double paid = 0;
              for (var p in payments) paid += (p['amount'] as num).toDouble();
              return {...inv, 'paid': paid};
            }),
          );
          return withPayments;
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          Map<String, Map<String, dynamic>> stats = {};
          for (var item in snapshot.data!) {
            final inv = Invoice.fromMap(item);
            final balance = inv.totalPayable - (item['paid'] as num).toDouble();
            if (!stats.containsKey(inv.provider))
              stats[inv.provider] = {'usd': 0.0, 'count': 0};
            if (balance > 0.01) {
              double usd = (inv.currency == 'USD')
                  ? balance
                  : (inv.exchangeRate != null && inv.exchangeRate! > 0)
                  ? balance / inv.exchangeRate!
                  : 0;
              stats[inv.provider]!['usd'] += usd;
              stats[inv.provider]!['count'] += 1;
            }
          }
          final list =
              stats.entries
                  .where((e) => e.key.toLowerCase().contains(_filter))
                  .toList()
                ..sort((a, b) => b.key.compareTo(a.key));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = list[index];
              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  title: Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    e.value['count'] > 0
                        ? '${e.value['count']} cuentas pendientes'
                        : 'Al día',
                  ),
                  trailing: Text(
                    '\$${NumberFormat("#,##0.00").format(e.value['usd'])}',
                    style: TextStyle(
                      color: e.value['usd'] > 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoiceListView(providerFilter: e.key),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// H. ABONOS GENERALES
class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});
  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  final _supabase = Supabase.instance.client;
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final stream = _supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .order('invoice_date', ascending: false)
        .asyncMap((invoices) async {
          final withPayments = await Future.wait(
            invoices.map((inv) async {
              final payments = await _supabase
                  .from('payments')
                  .select('amount')
                  .eq('invoice_id', inv['id']);
              double paid = 0;
              for (var p in payments) paid += (p['amount'] as num).toDouble();
              return {...inv, 'paid': paid};
            }),
          );
          return withPayments;
        });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizar Abono'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar cuenta...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final filtered = snapshot.data!.where((item) {
            final inv = Invoice.fromMap(item);
            double paid = (item['paid'] as num).toDouble();
            if ((inv.totalPayable - paid) <= 0.01) return false;
            if (_search.isNotEmpty)
              return inv.provider.toLowerCase().contains(_search);
            return true;
          }).toList();
          if (filtered.isEmpty)
            return const Center(
              child: Text(
                'No hay cuentas por cobrar',
                style: TextStyle(color: Colors.grey),
              ),
            );
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final inv = Invoice.fromMap(item);
              final paid = (item['paid'] as num).toDouble();
              final balance = inv.totalPayable - paid;
              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  title: Text(
                    inv.provider,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${inv.type} #${inv.docNumber} • ${DateFormat('dd/MM').format(inv.date)}',
                      ),
                      if (inv.notes != null && inv.notes!.isNotEmpty)
                        Text(
                          inv.notes!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  isThreeLine: inv.notes != null && inv.notes!.isNotEmpty,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Debe: ${inv.currency} ${NumberFormat("#,##0.00").format(balance)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: PaymentDialog(invoice: inv, maxAmount: balance),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// I. CONFIGURACIÓN
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Proveedores'),
            Tab(text: 'Métodos Pago'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          GenericConfigList(table: 'providers', label: 'Proveedor'),
          GenericConfigList(table: 'payment_methods', label: 'Método'),
        ],
      ),
    );
  }
}

class GenericConfigList extends StatefulWidget {
  final String table;
  final String label;
  const GenericConfigList({
    super.key,
    required this.table,
    required this.label,
  });
  @override
  State<GenericConfigList> createState() => _GenericConfigListState();
}

class _GenericConfigListState extends State<GenericConfigList> {
  final _supabase = Supabase.instance.client;
  void _upsert([int? id, String? name]) {
    final ctrl = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${id == null ? "Agregar" : "Editar"} ${widget.label}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              if (id == null)
                await _supabase.from(widget.table).insert({'name': ctrl.text});
              else
                await _supabase
                    .from(widget.table)
                    .update({'name': ctrl.text})
                    .eq('id', id);
              if (mounted) Navigator.pop(c);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from(widget.table)
            .stream(primaryKey: ['id'])
            .order('name'),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = snapshot.data![i];
              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _upsert(item['id'], item['name']),
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _supabase
                              .from(widget.table)
                              .delete()
                              .eq('id', item['id']);
                        },
                        icon: const Icon(Icons.delete, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upsert(),
        icon: const Icon(Icons.add),
        label: Text('Agregar ${widget.label}'),
      ),
    );
  }
}

// J. DETALLE FACTURA (CON ELIMINAR Y SUB-TOTALES)
class InvoiceDetailDialog extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          children: [
            // Cabecera Azul (AHORA CON BOTÓN DE ELIMINAR)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.provider,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${invoice.type} #${invoice.docNumber ?? "S/N"}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Botón Eliminar
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar Factura?'),
                          content: const Text(
                            'Esta acción borrará la factura y todo su historial de pagos. No se puede deshacer.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await Supabase.instance.client
                            .from('invoices')
                            .delete()
                            .eq('id', invoice.id);
                        if (context.mounted)
                          Navigator.pop(
                            context,
                          ); // Cierra el diálogo de detalle
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenido con Stream de Pagos
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('payments')
                    .stream(primaryKey: ['id'])
                    .eq('invoice_id', invoice.id)
                    .order('payment_date', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  // Cálculos Financieros
                  double paid = 0;
                  for (var p in snapshot.data!)
                    paid += (p['amount'] as num).toDouble();
                  final balance = invoice.totalPayable - paid;
                  final isPaid = balance <= 0.01;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // --- RESUMEN FINANCIERO MEJORADO (CON SUBTOTAL) ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _r('Base', invoice.baseAmount),
                            if (invoice.liquorTax > 0)
                              _r('Imp. Licor', invoice.liquorTax),
                            if (invoice.hasIva)
                              _r('IVA (16%)', invoice.manualIva),

                            // SI HAY RETENCIÓN, MOSTRAMOS EL SUBTOTAL PRIMERO
                            if (invoice.retentionAmount > 0) ...[
                              const Divider(),
                              _r(
                                'Subtotal',
                                invoice.subTotal,
                                bold: true,
                              ), // Suma antes de retención
                              _r(
                                'Retención (-)',
                                -invoice.retentionAmount,
                                color: AppColors.error,
                              ),
                            ],
                            const Divider(),
                            _r(
                              'TOTAL A PAGAR',
                              invoice.totalPayable,
                              bold: true,
                              size: 16,
                            ),

                            // SECCIÓN DE RESTANTE (Solo si hay abonos)
                            if (paid > 0) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  thickness: 1,
                                  color: AppColors.border,
                                ),
                              ),
                              _r(
                                'Abonado (-)',
                                -paid,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "RESTANTE POR PAGAR",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat(
                                      "#,##0.00",
                                    ).format(balance < 0 ? 0 : balance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: isPaid
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ----------------------------------------------------------------
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historial de Pagos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isPaid
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? 'COMPLETADO' : 'PENDIENTE',
                              style: TextStyle(
                                color: isPaid
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (snapshot.data!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No se han registrado abonos',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...snapshot.data!.map(
                          (p) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.success,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              p['method'] ?? 'Pago',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy',
                                'es',
                              ).format(DateTime.parse(p['payment_date'])),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${NumberFormat("#,##0.00").format(p['amount'])} ${invoice.currency}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final c = await showDialog(
                                      context: context,
                                      builder: (d) => AlertDialog(
                                        title: const Text('¿Eliminar pago?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(d, true),
                                            child: const Text('Si'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(d, false),
                                            child: const Text('No'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (c == true)
                                      await Supabase.instance.client
                                          .from('payments')
                                          .delete()
                                          .eq('id', p['id']);
                                  },
                                ),
                              ],
                            ),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                ),
                                child: PaymentDialog(
                                  invoice: invoice,
                                  maxAmount: 0,
                                  existing: p,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Botón de acción (CORREGIDO: AHORA PASA EL BALANCE REAL)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                // Necesitamos recalcular el saldo para enviarlo al botón
                stream: Supabase.instance.client
                    .from('payments')
                    .stream(primaryKey: ['id'])
                    .eq('invoice_id', invoice.id),
                builder: (context, snapshot) {
                  double paid = 0;
                  if (snapshot.hasData) {
                    for (var p in snapshot.data!)
                      paid += (p['amount'] as num).toDouble();
                  }
                  final currentBalance = invoice.totalPayable - paid;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: currentBalance <= 0.01
                          ? null
                          : () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                ),
                                child: PaymentDialog(
                                  invoice: invoice,
                                  maxAmount: currentBalance,
                                ), // AQUI SE PASABA 0 ANTES
                              ),
                            ),
                      icon: const Icon(Icons.add_card),
                      label: const Text('REGISTRAR ABONO'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _r(
    String l,
    double v, {
    bool bold = false,
    Color? color,
    double size = 14,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: size,
            color: AppColors.textDark,
          ),
        ),
        Text(
          NumberFormat("#,##0.00").format(v),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textDark,
            fontSize: size,
          ),
        ),
      ],
    ),
  );
}
