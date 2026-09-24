import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String supabaseUrl = 'https://nlggetwdohewdhnlykxf.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sZ2dldHdkb2hld2Robmx5a3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxOTQxNDUsImV4cCI6MjEwNTc3MDE0NX0.P1Q1A-4aONqrAB_R_-yZ0U5yzHd_SC2nBNrIWWxjUGY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: supabaseUrl, 
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  } catch (e) {
    debugPrint('Supabase Init Info: $e');
  }
  runApp(const ClinicAppMaster());
}

class ClinicAppMaster extends StatelessWidget {
  const ClinicAppMaster({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة العيادات والمراكز الطبية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGateScreen(),
    );
  }
}

// ========================== MODELS ==========================
class UserModel {
  final String id;
  String name;
  String email;
  String password;
  String role;
  String? linkedDoctorId;
  bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.linkedDoctorId,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'password_hash': password,
    'role': role,
    'linked_doctor_id': linkedDoctorId,
    'is_active': isActive,
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    password: m['password_hash'] ?? m['password'] ?? '123456',
    role: m['role'] ?? 'RECEPTIONIST',
    linkedDoctorId: m['linked_doctor_id']?.toString(),
    isActive: m['is_active'] ?? m['isActive'] ?? true,
  );
}

class DoctorModel {
  final String id;
  String name;
  String specialty;
  double consultationFee;
  int durationMinutes;
  String workStartTime;
  String workEndTime;
  bool allowReceptionBooking;
  bool isActive;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.consultationFee,
    required this.durationMinutes,
    required this.workStartTime,
    required this.workEndTime,
    required this.allowReceptionBooking,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'specialty': specialty,
    'consultation_fee': consultationFee,
    'duration_minutes': durationMinutes,
    'work_start_time': workStartTime,
    'work_end_time': workEndTime,
    'allow_reception_booking': allowReceptionBooking,
    'is_active': isActive,
  };

  factory DoctorModel.fromMap(Map<String, dynamic> m) => DoctorModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    name: m['name'] ?? '',
    specialty: m['specialty'] ?? '',
    consultationFee: (m['consultation_fee'] as num?)?.toDouble() ?? 3000.0,
    durationMinutes: (m['duration_minutes'] as num?)?.toInt() ?? 15,
    workStartTime: m['work_start_time']?.toString() ?? '09:00:00',
    workEndTime: m['work_end_time']?.toString() ?? '17:00:00',
    allowReceptionBooking: m['allow_reception_booking'] ?? true,
    isActive: m['is_active'] ?? true,
  );
}

class ClinicServiceModel {
  final String id;
  final String? doctorId;
  String name;
  double price;
  bool isActive;

  ClinicServiceModel({
    required this.id,
    this.doctorId,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctor_id': doctorId,
    'name': name,
    'price': price,
    'is_active': isActive,
  };

  factory ClinicServiceModel.fromMap(Map<String, dynamic> m) => ClinicServiceModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    doctorId: m['doctor_id']?.toString(),
    name: m['name'] ?? '',
    price: (m['price'] as num?)?.toDouble() ?? 0.0,
    isActive: m['is_active'] ?? true,
  );
}

class PatientModel {
  final String id;
  String fullName;
  String phone;
  int age;
  String gender;
  String notes;
  String chronicDiseases;

  PatientModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.age,
    required this.gender,
    required this.notes,
    this.chronicDiseases = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'age': age,
    'gender': gender,
    'notes': notes,
    'chronic_diseases': chronicDiseases,
  };

  factory PatientModel.fromMap(Map<String, dynamic> m) => PatientModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    fullName: m['full_name'] ?? m['fullName'] ?? '',
    phone: m['phone'] ?? '',
    age: (m['age'] as num?)?.toInt() ?? 25,
    gender: m['gender'] ?? 'MALE',
    notes: m['notes'] ?? '',
    chronicDiseases: m['chronic_diseases'] ?? '',
  );
}

class AppointmentServiceModel {
  final String id;
  final String appointmentId;
  final String serviceName;
  final double price;

  AppointmentServiceModel({
    required this.id,
    required this.appointmentId,
    required this.serviceName,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'appointment_id': appointmentId,
    'service_name': serviceName,
    'price': price,
  };

  factory AppointmentServiceModel.fromMap(Map<String, dynamic> m) => AppointmentServiceModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    appointmentId: m['appointment_id']?.toString() ?? '',
    serviceName: m['service_name'] ?? '',
    price: (m['price'] as num?)?.toDouble() ?? 0.0,
  );
}

class PaymentReceiptModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;

  PaymentReceiptModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'appointment_id': appointmentId,
    'patient_id': patientId,
    'amount': amount,
    'payment_method': paymentMethod,
    'payment_date': paymentDate,
  };

  factory PaymentReceiptModel.fromMap(Map<String, dynamic> m) => PaymentReceiptModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    appointmentId: m['appointment_id']?.toString() ?? '',
    patientId: m['patient_id']?.toString() ?? '',
    amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: m['payment_method'] ?? 'CASH',
    paymentDate: m['payment_date'] ?? DateTime.now().toString(),
  );
}

class AppointmentModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String visitType;
  final String status;
  final double totalAmount;
  double paidAmount;
  double remainingAmount;
  final String paymentMethod;
  String paymentStatus;
  final String createdByRole;
  bool isSynced;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.visitType,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdByRole,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctor_id': doctorId,
    'patient_id': patientId,
    'created_by_role': createdByRole,
    'appointment_date': appointmentDate,
    'start_time': startTime,
    'end_time': endTime,
    'visit_type': visitType,
    'status': status,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'remaining_amount': remainingAmount,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
  };

  factory AppointmentModel.fromMap(Map<String, dynamic> m, {DoctorModel? doc, PatientModel? pat}) => AppointmentModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    doctorId: m['doctor_id']?.toString() ?? '',
    doctorName: doc?.name ?? m['doctor_name'] ?? 'طبيب',
    patientId: m['patient_id']?.toString() ?? '',
    patientName: pat?.fullName ?? m['patient_name'] ?? 'مريض',
    patientPhone: pat?.phone ?? m['patient_phone'] ?? '',
    appointmentDate: m['appointment_date']?.toString() ?? '',
    startTime: m['start_time']?.toString() ?? '',
    endTime: m['end_time']?.toString() ?? '',
    visitType: m['visit_type'] ?? 'NEW_VISIT',
    status: m['status'] ?? 'CONFIRMED',
    totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0.0,
    paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0.0,
    remainingAmount: (m['remaining_amount'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: m['payment_method'] ?? 'CASH',
    paymentStatus: m['payment_status'] ?? 'PAID',
    createdByRole: m['created_by_role'] ?? 'RECEPTIONIST',
    isSynced: true,
  );
}

// ========================== AUTH GATE ==========================
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;
  bool obscurePass = true;

  @override
  void initState() {
    super.initState();
    _checkCachedSession();
  }

  Future<void> _checkCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_current_user');
    if (cachedUser != null) {
      final user = UserModel.fromMap(jsonDecode(cachedUser));
      if (user.isActive && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ClinicMainDashboard(currentUser: user)),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .eq('password_hash', pass)
          .maybeSingle();

      if (res != null) {
        final loggedUser = UserModel.fromMap(res);
        if (!loggedUser.isActive) throw Exception('هذا الحساب معطل حالياً من الإدارة.');

        await prefs.setString('cached_current_user', jsonEncode(loggedUser.toMap()));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ClinicMainDashboard(currentUser: loggedUser)),
          );
        }
        return;
      }
    } catch (e) {
      final localUsersStr = prefs.getString('clinic_users');
      if (localUsersStr != null) {
        final List list = jsonDecode(localUsersStr);
        final matched = list.cast<Map<String, dynamic>>().firstWhere(
          (m) => m['email'] == email && (m['password_hash'] == pass || m['password'] == pass),
          orElse: () => {},
        );
        if (matched.isNotEmpty) {
          final localUser = UserModel.fromMap(matched);
          if (localUser.isActive && mounted) {
            await prefs.setString('cached_current_user', jsonEncode(localUser.toMap()));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ClinicMainDashboard(currentUser: localUser)),
            );
            return;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('فشل تسجيل الدخول: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),
              const Text('نظام إدارة العيادات والمراكز الطبية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              const Text('تسجيل دخول سحابي / أوفلاين ذكي', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passCtrl,
                        obscureText: obscurePass,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscurePass = !obscurePass),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================== DASHBOARD ==========================
class ClinicMainDashboard extends StatefulWidget {
  final UserModel currentUser;
  const ClinicMainDashboard({super.key, required this.currentUser});

  @override
  State<ClinicMainDashboard> createState() => _ClinicMainDashboardState();
}

class _ClinicMainDashboardState extends State<ClinicMainDashboard> {
  int _currentIndex = 0;
  bool isSyncing = false;
  bool isOnline = true;
  Timer? _autoSyncTimer;
  RealtimeChannel? _liveChannel;

  List<UserModel> users = [];
  List<DoctorModel> doctors = [];
  List<ClinicServiceModel> services = [];
  List<PatientModel> patients = [];
  List<AppointmentModel> appointments = [];
  List<PaymentReceiptModel> payments = [];
  List<AppointmentServiceModel> appointmentServices = [];

  String patientSearchQuery = '';
  DateTime selectedCalendarDate = DateTime.now();
  DateTime selectedAuditDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _initSupabaseRealtime();
    _startPeriodicSync();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    if (_liveChannel != null) {
      Supabase.instance.client.removeChannel(_liveChannel!);
    }
    super.dispose();
  }

  void _startPeriodicSync() {
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isSyncing) {
        _syncWithSupabase(silent: true);
      }
    });
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final uStr = prefs.getString('clinic_users');
    final dStr = prefs.getString('clinic_doctors');
    final sStr = prefs.getString('clinic_services');
    final pStr = prefs.getString('clinic_patients');
    final aStr = prefs.getString('clinic_appointments');
    final payStr = prefs.getString('clinic_payments');
    final asStr = prefs.getString('clinic_appointment_services');

    if (uStr != null) users = (jsonDecode(uStr) as List).map((e) => UserModel.fromMap(e)).toList();
    if (dStr != null) doctors = (jsonDecode(dStr) as List).map((e) => DoctorModel.fromMap(e)).toList();
    if (sStr != null) services = (jsonDecode(sStr) as List).map((e) => ClinicServiceModel.fromMap(e)).toList();
    if (pStr != null) patients = (jsonDecode(pStr) as List).map((e) => PatientModel.fromMap(e)).toList();
    if (aStr != null) appointments = (jsonDecode(aStr) as List).map((e) => AppointmentModel.fromMap(e)).toList();
    if (payStr != null) payments = (jsonDecode(payStr) as List).map((e) => PaymentReceiptModel.fromMap(e)).toList();
    if (asStr != null) appointmentServices = (jsonDecode(asStr) as List).map((e) => AppointmentServiceModel.fromMap(e)).toList();

    setState(() {});
    _syncWithSupabase();
  }

  Future<void> _saveAllLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clinic_users', jsonEncode(users.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_doctors', jsonEncode(doctors.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_services', jsonEncode(services.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_patients', jsonEncode(patients.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_appointments', jsonEncode(appointments.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_payments', jsonEncode(payments.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_appointment_services', jsonEncode(appointmentServices.map((e) => e.toMap()).toList()));
  }

  void _initSupabaseRealtime() {
    try {
      final client = Supabase.instance.client;
      final uniqueChannel = 'clinic_sync_${DateTime.now().microsecondsSinceEpoch}';

      _liveChannel = client.channel(uniqueChannel)
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (payload) => _syncWithSupabase(silent: true),
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patients',
          callback: (payload) => _syncWithSupabase(silent: true),
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doctors',
          callback: (payload) => _syncWithSupabase(silent: true),
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clinic_services',
          callback: (payload) => _syncWithSupabase(silent: true),
        )
        ..subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (mounted) setState(() => isOnline = true);
          }
        });
    } catch (e) {
      debugPrint('Realtime setup: $e');
    }
  }

  Future<void> _syncWithSupabase({bool silent = false}) async {
    if (isSyncing) return;
    if (!silent && mounted) setState(() => isSyncing = true);

    try {
      final client = Supabase.instance.client;

      final unsynced = appointments.where((a) => !a.isSynced).toList();
      for (var app in unsynced) {
        await client.from('appointments').upsert(app.toMap());
        app.isSynced = true;
      }

      final pRes = await client.from('patients').select();
      final dRes = await client.from('doctors').select();
      final sRes = await client.from('clinic_services').select();
      final aRes = await client.from('appointments').select();
      final uRes = await client.from('users').select();

      if (mounted) {
        setState(() {
          isOnline = true;
          doctors = (dRes as List).map((e) => DoctorModel.fromMap(e)).toList();
          services = (sRes as List).map((e) => ClinicServiceModel.fromMap(e)).toList();
          patients = (pRes as List).map((e) => PatientModel.fromMap(e)).toList();
          users = (uRes as List).map((e) => UserModel.fromMap(e)).toList();

          appointments = (aRes as List).map((m) {
            final d = doctors.cast<DoctorModel?>().firstWhere((doc) => doc?.id == m['doctor_id'], orElse: () => null);
            final p = patients.cast<PatientModel?>().firstWhere((pat) => pat?.id == m['patient_id'], orElse: () => null);
            return AppointmentModel.fromMap(m, doc: d, pat: p);
          }).toList();
        });
      }

      await _saveAllLocally();
    } catch (e) {
      if (mounted) setState(() => isOnline = false);
      debugPrint('Sync status: Offline mode active');
    } finally {
      if (mounted && !silent) setState(() => isSyncing = false);
    }
  }

  void _showNotification(String title, String desc, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isWarning ? Colors.amber.shade900 : const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(isWarning ? Icons.warning_amber_rounded : Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppointmentModel> get currentRoleAppointments {
    if (widget.currentUser.role == 'DOCTOR_SECRETARY') {
      return appointments.where((a) => a.doctorId == widget.currentUser.linkedDoctorId).toList();
    }
    return appointments;
  }

  List<String> _generateTimeSlots(DoctorModel doc) {
    List<String> slots = [];
    try {
      final startParts = doc.workStartTime.split(':');
      final endParts = doc.workEndTime.split(':');

      DateTime now = DateTime.now();
      DateTime start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      DateTime end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));

      while (start.isBefore(end)) {
        slots.add(DateFormat('hh:mm a').format(start));
        start = start.add(Duration(minutes: doc.durationMinutes));
      }
    } catch (e) {
      slots = ['09:00 ص', '09:30 ص', '10:00 ص', '10:30 ص', '11:00 ص', '11:30 ص', '12:00 م', '04:00 م', '04:30 م'];
    }
    return slots;
  }

  Future<void> _printReceiptPdf(AppointmentModel app, [PaymentReceiptModel? receipt]) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final attachedServices = appointmentServices.where((s) => s.appointmentId == app.id).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context ctx) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue900, width: 2),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Text('مجمع العيادات والمراكز الطبية', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                  pw.Center(child: pw.Text(receipt == null ? 'سند قبض وتأكيد موعد' : 'سند سداد دفعة لاحقة', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))),
                  pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                  pw.SizedBox(height: 6),
                  pw.Text('رقم السند: ${receipt?.id.substring(0, 8).toUpperCase() ?? app.id.substring(0, 8).toUpperCase()}'),
                  pw.Text('المريض: ${app.patientName} | هاتف: ${app.patientPhone}'),
                  pw.Text('الطبيب المعالج: ${app.doctorName}'),
                  pw.Text('التاريخ: ${app.appointmentDate} - الوقت: ${app.startTime}'),
                  pw.Text('نوع الزيارة: ${app.visitType == 'NEW_VISIT' ? 'معاينة جديدة' : 'مراجعة / عودة مجانية'}'),
                  if (attachedServices.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('الخدمات والفحوصات المرفقة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...attachedServices.map((s) => pw.Text('- ${s.serviceName}: ${s.price} ر.ي')),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('المبلغ الإجمالي:'),
                            pw.Text('${app.totalAmount} ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('المدفوع في هذا السند:'),
                            pw.Text('${receipt?.amount ?? app.paidAmount} ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('المتبقي في الذمة:'),
                            pw.Text('${app.remainingAmount} ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('توقيع الاستقبال: ....................'),
                      pw.Text('طريقة السداد: ${receipt?.paymentMethod ?? app.paymentMethod}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ================= طباعة تقرير اليوم =================
  Future<void> _printDailyClosingPdf(DateTime date, List<AppointmentModel> dayApps) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final totalIncome = dayApps.where((a) => a.status != 'CANCELLED').fold(0.0, (s, a) => s + a.paidAmount);
    final totalRemaining = dayApps.where((a) => a.status != 'CANCELLED').fold(0.0, (s, a) => s + a.remainingAmount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context ctx) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('تقرير الإغلاق المالي والإداري اليومي', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                pw.Center(child: pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(date)}', style: const pw.TextStyle(fontSize: 14))),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('إجمالي المرضى: ${dayApps.length}'),
                    pw.Text('المحصل: $totalIncome ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Text('المتبقي: $totalRemaining ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Table.fromTextArray(
                  headers: ['المريض', 'الطبيب', 'الوقت', 'النوع', 'الحالة', 'المدفوع', 'المتبقي'],
                  data: dayApps.map((a) => [
                    a.patientName,
                    a.doctorName,
                    a.startTime,
                    a.visitType == 'NEW_VISIT' ? 'كشف' : 'عودة',
                    a.status,
                    '${a.paidAmount}',
                    '${a.remainingAmount}',
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  cellAlignment: pw.Alignment.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _openPayRemainingDialog(AppointmentModel app) {
    final payAmountCtrl = TextEditingController(text: app.remainingAmount.toStringAsFixed(0));
    String payMethod = 'CASH';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سداد دفعة للمريض: ${app.patientName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ المتبقي الحالي: ${app.remainingAmount} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 12),
            TextField(
              controller: payAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ المسدد الآن'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: payMethod,
              decoration: const InputDecoration(labelText: 'طريقة السداد'),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('نقدي')),
                DropdownMenuItem(value: 'NETWORK', child: Text('شبكة/حوالة')),
                DropdownMenuItem(value: 'INSURANCE', child: Text('تأمين طبي')),
              ],
              onChanged: (v) {
                if (v != null) payMethod = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () async {
              double amount = double.tryParse(payAmountCtrl.text) ?? 0.0;
              if (amount <= 0 || amount > app.remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
                return;
              }

              final newReceipt = PaymentReceiptModel(
                id: const Uuid().v4(),
                appointmentId: app.id,
                patientId: app.patientId,
                amount: amount,
                paymentMethod: payMethod,
                paymentDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              );

              setState(() {
                app.paidAmount += amount;
                app.remainingAmount -= amount;
                app.paymentStatus = app.remainingAmount == 0 ? 'PAID' : 'PARTIALLY_PAID';
                payments.add(newReceipt);
              });

              await _saveAllLocally();
              try {
                await Supabase.instance.client.from('payments').upsert(newReceipt.toMap());
                await Supabase.instance.client.from('appointments').update({
                  'paid_amount': app.paidAmount,
                  'remaining_amount': app.remainingAmount,
                  'payment_status': app.paymentStatus,
                }).eq('id', app.id);
              } catch (_) {}

              Navigator.pop(ctx);
              _showNotification('تم تسجيل السداد', 'تم سداد $amount ر.ي للمريض ${app.patientName}');
              _printReceiptPdf(app, newReceipt);
            },
            child: const Text('تأكيد السداد وطباعة السند'),
          ),
        ],
      ),
    );
  }

  // ================= الحجز السريع المباشر للسحابة =================
  void _openQuickBookingDialog({PatientModel? prefilledPatient, String initialVisitType = 'NEW_VISIT'}) {
    final nameCtrl = TextEditingController(text: prefilledPatient?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: prefilledPatient?.phone ?? '');
    final ageCtrl = TextEditingController(text: prefilledPatient?.age.toString() ?? '25');
    final paidCtrl = TextEditingController();

    List<DoctorModel> availableDocs = doctors.where((d) => d.isActive).toList();

    if (widget.currentUser.role == 'RECEPTIONIST') {
      availableDocs = availableDocs.where((d) => d.allowReceptionBooking == true).toList();
    } else if (widget.currentUser.role == 'DOCTOR_SECRETARY') {
      availableDocs = availableDocs.where((d) => d.id == widget.currentUser.linkedDoctorId).toList();
    }

    if (availableDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            widget.currentUser.role == 'RECEPTIONIST'
                ? 'عفواً، لا توجد عيادات مصرح للاستقبال بالحجز لها حالياً من قبل المدير.'
                : 'لم يتم ربط حسابك بعيادة طبيب محدد.',
          ),
        ),
      );
      return;
    }

    DoctorModel selectedDoc = availableDocs.first;
    List<String> availableSlots = _generateTimeSlots(selectedDoc);
    String selectedTime = availableSlots.isNotEmpty ? availableSlots.first : '09:00 ص';
    String visitType = initialVisitType;
    String paymentMethod = 'CASH';

    List<ClinicServiceModel> selectedExtraServices = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final docServices = services.where((s) => s.doctorId == selectedDoc.id || s.doctorId == null).toList();

            double consultationAmount = (visitType == 'RETURN_VISIT') ? 0.0 : selectedDoc.consultationFee;
            double totalFee = consultationAmount + selectedExtraServices.fold(0.0, (s, item) => s + item.price);

            if (paidCtrl.text.isEmpty) {
              paidCtrl.text = totalFee.toStringAsFixed(0);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          visitType == 'RETURN_VISIT' ? 'تسجيل عودة ومراجعة مجانية' : 'حجز كشف ومعاينة جديدة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: visitType == 'RETURN_VISIT' ? Colors.green.shade800 : const Color(0xFF1E3A8A),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم جوال المريض (للبحث والملف)', prefixIcon: Icon(Icons.phone_outlined)),
                      onChanged: (val) {
                        final existing = patients.cast<PatientModel?>().firstWhere(
                          (p) => p?.phone == val.trim(),
                          orElse: () => null,
                        );
                        if (existing != null) {
                          setModalState(() {
                            nameCtrl.text = existing.fullName;
                            ageCtrl.text = existing.age.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(labelText: 'اسم المريض الكامل', prefixIcon: Icon(Icons.person_outline)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'العمر'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<DoctorModel>(
                      value: selectedDoc,
                      decoration: const InputDecoration(labelText: 'الطبيب والعيادة المصرح بها', prefixIcon: Icon(Icons.medical_services_outlined)),
                      items: availableDocs.map((doc) => DropdownMenuItem(value: doc, child: Text('${doc.name} (${doc.specialty})'))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedDoc = val;
                            availableSlots = _generateTimeSlots(selectedDoc);
                            if (availableSlots.isNotEmpty) selectedTime = availableSlots.first;
                            selectedExtraServices.clear();
                            paidCtrl.text = ((visitType == 'RETURN_VISIT') ? 0.0 : selectedDoc.consultationFee).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: visitType,
                            decoration: const InputDecoration(labelText: 'نوع الموعد'),
                            items: const [
                              DropdownMenuItem(value: 'NEW_VISIT', child: Text('معاينة جديدة (مدفوعة)')),
                              DropdownMenuItem(value: 'RETURN_VISIT', child: Text('عودة ومراجعة (مجانية)')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() {
                                  visitType = v;
                                  double fee = (visitType == 'RETURN_VISIT' ? 0.0 : selectedDoc.consultationFee) +
                                      selectedExtraServices.fold(0.0, (s, item) => s + item.price);
                                  paidCtrl.text = fee.toStringAsFixed(0);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedTime,
                            decoration: const InputDecoration(labelText: 'وقت الحجز'),
                            items: availableSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedTime = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (docServices.isNotEmpty) ...[
                      const Text('خدمات وإجراءات العيادة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Wrap(
                        spacing: 6,
                        children: docServices.map((srv) {
                          final isSelected = selectedExtraServices.contains(srv);
                          return FilterChip(
                            label: Text('${srv.name} (+${srv.price} ر.ي)'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedExtraServices.add(srv);
                                } else {
                                  selectedExtraServices.remove(srv);
                                }
                                double fee = (visitType == 'RETURN_VISIT' ? 0.0 : selectedDoc.consultationFee) +
                                    selectedExtraServices.fold(0.0, (s, item) => s + item.price);
                                paidCtrl.text = fee.toStringAsFixed(0);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: paidCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'المبلغ المدفوع الآن (ر.ي)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: const InputDecoration(labelText: 'وسيلة الدفع'),
                            items: const [
                              DropdownMenuItem(value: 'CASH', child: Text('نقدي')),
                              DropdownMenuItem(value: 'NETWORK', child: Text('شبكة/حوالة')),
                              DropdownMenuItem(value: 'INSURANCE', child: Text('تأمين طبي')),
                              DropdownMenuItem(value: 'DEFERRED', child: Text('آجل / دين')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => paymentMethod = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى تعبئة الاسم ورقم الجوال')),
                          );
                          return;
                        }

                        PatientModel? p = patients.cast<PatientModel?>().firstWhere(
                          (item) => item?.phone == phoneCtrl.text.trim(),
                          orElse: () => null,
                        );

                        if (p == null) {
                          p = PatientModel(
                            id: const Uuid().v4(),
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            age: int.tryParse(ageCtrl.text) ?? 25,
                            gender: 'MALE',
                            notes: '',
                          );
                          patients.add(p);
                        }

                        double paid = double.tryParse(paidCtrl.text) ?? 0.0;
                        double remaining = (totalFee - paid).clamp(0.0, 999999.0);

                        final conflictIdx = appointments.indexWhere((a) =>
                            a.doctorId == selectedDoc.id &&
                            a.startTime == selectedTime &&
                            a.status != 'CANCELLED');

                        bool conflictResolved = false;
                        if (conflictIdx != -1) {
                          final existing = appointments[conflictIdx];
                          if (widget.currentUser.role == 'DOCTOR_SECRETARY' && existing.createdByRole == 'RECEPTIONIST') {
                            appointments[conflictIdx] = AppointmentModel(
                              id: existing.id,
                              doctorId: existing.doctorId,
                              doctorName: existing.doctorName,
                              patientId: existing.patientId,
                              patientName: existing.patientName,
                              patientPhone: existing.patientPhone,
                              appointmentDate: existing.appointmentDate,
                              startTime: existing.startTime,
                              endTime: existing.endTime,
                              visitType: existing.visitType,
                              status: 'WAITING_LIST',
                              totalAmount: existing.totalAmount,
                              paidAmount: existing.paidAmount,
                              remainingAmount: existing.remainingAmount,
                              paymentMethod: existing.paymentMethod,
                              paymentStatus: existing.paymentStatus,
                              createdByRole: existing.createdByRole,
                              isSynced: false,
                            );
                            conflictResolved = true;
                          }
                        }

                        final newAppId = const Uuid().v4();
                        final newApp = AppointmentModel(
                          id: newAppId,
                          doctorId: selectedDoc.id,
                          doctorName: selectedDoc.name,
                          patientId: p.id,
                          patientName: p.fullName,
                          patientPhone: p.phone,
                          appointmentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          startTime: selectedTime,
                          endTime: selectedTime,
                          visitType: visitType,
                          status: (conflictIdx != -1 && widget.currentUser.role == 'RECEPTIONIST') ? 'WAITING_LIST' : 'CONFIRMED',
                          totalAmount: totalFee,
                          paidAmount: paid,
                          remainingAmount: remaining,
                          paymentMethod: paymentMethod,
                          paymentStatus: remaining == 0 ? 'PAID' : (paid > 0 ? 'PARTIALLY_PAID' : 'UNPAID'),
                          createdByRole: widget.currentUser.role,
                          isSynced: false,
                        );

                        try {
                          await Supabase.instance.client.from('patients').upsert(p.toMap());
                          await Supabase.instance.client.from('appointments').upsert(newApp.toMap());
                          newApp.isSynced = true;
                        } catch (e) {
                          debugPrint('Direct upload failed: $e');
                        }

                        setState(() {
                          appointments.insert(0, newApp);
                        });

                        await _saveAllLocally();
                        Navigator.pop(ctx);

                        _showNotification(
                          visitType == 'RETURN_VISIT' ? 'تم تسجيل عودة المريض بنجاح' : 'تم تأكيد الحجز الجديد',
                          'المريض: ${p.fullName} - د. ${selectedDoc.name}',
                        );

                        if (conflictResolved) {
                          _showNotification(
                            'فض النزاع التلقائي',
                            'تم إعطاء الأسبقية لسكرتير الطبيب ونقل موعد الاستقبال لقائمة الانتظار',
                            isWarning: true,
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('تأكيد وحفظ الموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(AppointmentModel item, String newStatus) async {
    setState(() {
      final idx = appointments.indexWhere((a) => a.id == item.id);
      if (idx != -1) {
        appointments[idx] = AppointmentModel(
          id: item.id,
          doctorId: item.doctorId,
          doctorName: item.doctorName,
          patientId: item.patientId,
          patientName: item.patientName,
          patientPhone: item.patientPhone,
          appointmentDate: item.appointmentDate,
          startTime: item.startTime,
          endTime: item.endTime,
          visitType: item.visitType,
          status: newStatus,
          totalAmount: item.totalAmount,
          paidAmount: item.paidAmount,
          remainingAmount: item.remainingAmount,
          paymentMethod: item.paymentMethod,
          paymentStatus: item.paymentStatus,
          createdByRole: item.createdByRole,
          isSynced: false,
        );
      }
    });

    await _saveAllLocally();
    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', item.id);
    } catch (_) {}

    _showNotification('تحديث حالة المريض', 'تم تغيير حالة ${item.patientName} إلى: $newStatus');
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCount = appointments.where((a) => !a.isSynced).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.currentUser.role == 'ADMIN'
              ? 'لوحة إدارة النظام'
              : (widget.currentUser.role == 'DOCTOR_SECRETARY' ? 'عيادة الطبيب المخصص' : 'الاستقبال العام'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'مزامنة السحابة',
            onPressed: isSyncing ? null : () => _syncWithSupabase(),
            icon: isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Badge(
                    label: Text('$unsyncedCount'),
                    isLabelVisible: unsyncedCount > 0,
                    child: const Icon(Icons.cloud_sync_outlined),
                  ),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('cached_current_user');
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGateScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: isOnline ? Colors.green.shade700 : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'سحابي متزامن (مباشر)' : 'محلي أوفلاين (جاري إعادة الاتصال)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.green.shade900 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.currentUser.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        onPressed: () => _openQuickBookingDialog(),
        icon: const Icon(Icons.add),
        label: const Text('حجز سريع', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'التقويم'),
          const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'الانتظار'),
          const NavigationDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared), label: 'المرضى'),
          const NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'أرشيف الأيام'),
          const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'المالية'),
          if (widget.currentUser.role == 'ADMIN' || widget.currentUser.role == 'DOCTOR_SECRETARY')
            const NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'الخدمات والإدارة'),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildCalendarView();
      case 1:
        return _buildQueueView();
      case 2:
        return _buildPatientsView();
      case 3:
        return _buildAuditHistoryView();
      case 4:
        return _buildFinanceView();
      case 5:
        return _buildManagementAndServicesView();
      default:
        return _buildCalendarView();
    }
  }

  // ================= تبويب التقويم =================
  Widget _buildCalendarView() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedCalendarDate);
    final list = currentRoleAppointments.where((a) => a.appointmentDate == selectedDateStr).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final date = DateTime.now().add(Duration(days: index - 2));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == selectedDateStr;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('E', 'ar').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11)),
                        Text(DateFormat('d/M').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1E3A8A),
                    onSelected: (val) {
                      if (val) setState(() => selectedCalendarDate = date);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مواعيد: $selectedDateStr', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${list.length} موعد', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('لا توجد مواعيد مسجلة في هذا اليوم.')),
                ),
              ...list.map((item) {
                Color color = Colors.blue;
                String stText = 'مؤكد';
                if (item.status == 'WAITING') {
                  color = const Color(0xFFD97706);
                  stText = 'في الانتظار';
                } else if (item.status == 'IN_ROOM') {
                  color = const Color(0xFF059669);
                  stText = 'في غرفة الكشف';
                } else if (item.status == 'COMPLETED') {
                  color = const Color(0xFF64748B);
                  stText = 'مكتمل';
                } else if (item.status == 'CANCELLED') {
                  color = const Color(0xFFDC2626);
                  stText = 'ملغى / لم يحضر';
                } else if (item.status == 'WAITING_LIST') {
                  color = Colors.purple;
                  stText = 'قائمة الانتظار السريعة';
                }

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 6, backgroundColor: color),
                                const SizedBox(width: 8),
                                Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                              child: Text(stText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${item.doctorName} • الوقت: ${item.startTime} (${item.visitType == 'RETURN_VISIT' ? 'مراجعة / عودة مجانية' : 'معاينة جديدة'})'),
                        Text(
                          'المدفوع: ${item.paidAmount} ر.ي | المتبقي: ${item.remainingAmount} ر.ي | ${item.paymentMethod}',
                          style: TextStyle(
                            color: item.remainingAmount > 0 ? Colors.red.shade700 : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 16),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            OutlinedButton(onPressed: () => _updateStatus(item, 'WAITING'), child: const Text('في الانتظار', style: TextStyle(fontSize: 11))),
                            OutlinedButton(onPressed: () => _updateStatus(item, 'IN_ROOM'), child: const Text('داخل الكشف', style: TextStyle(fontSize: 11))),
                            OutlinedButton(onPressed: () => _updateStatus(item, 'COMPLETED'), child: const Text('اكتمل', style: TextStyle(fontSize: 11))),
                            OutlinedButton(
                              onPressed: () => _updateStatus(item, 'CANCELLED'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('إلغاء / تغيب', style: TextStyle(fontSize: 11)),
                            ),
                            if (item.remainingAmount > 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                                onPressed: () => _openPayRemainingDialog(item),
                                child: const Text('سداد المتبقي', style: TextStyle(fontSize: 11)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A)),
                              tooltip: 'طباعة وحفظ سند القبض PDF',
                              onPressed: () => _printReceiptPdf(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ================= تبويب طابور الانتظار =================
  Widget _buildQueueView() {
    final waiting = currentRoleAppointments.where((a) => a.status == 'WAITING').toList();
    final inRoom = currentRoleAppointments.where((a) => a.status == 'IN_ROOM').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('نظام طابور الانتظار والنداء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade300)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.meeting_room, color: Colors.green),
                  SizedBox(width: 8),
                  Text('داخل غرفة الطبيب حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              if (inRoom.isEmpty) const Text('لا يوجد مريض داخل الغرفة حالياً', style: TextStyle(color: Colors.grey)),
              ...inRoom.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('مع ${m.doctorName}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _updateStatus(m, 'COMPLETED'),
                  child: const Text('إنهاء الكشف'),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('صالة الانتظار (أسبقية الحضور):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (waiting.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('صالة الانتظار فارغة'))),
        ...waiting.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final m = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                child: Text('$idx'),
              ),
              title: Text(m.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${m.doctorName} • وقته: ${m.startTime}'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                onPressed: () => _updateStatus(m, 'IN_ROOM'),
                child: const Text('إدخال للغرفة'),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= تبويب سجل وبحث المرضى والملف الطبي الشامل =================
  Widget _buildPatientsView() {
    final filtered = patients.where((p) {
      final q = patientSearchQuery.trim().toLowerCase();
      return p.fullName.toLowerCase().contains(q) || p.phone.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل المرضى وملفاتهم الطبية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${patients.length} مريض', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو رقم الجوال...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => patientSearchQuery = val),
        ),
        const SizedBox(height: 12),
        ...filtered.map((p) {
          final patientApps = appointments.where((a) => a.patientPhone == p.phone).toList();
          final cancelled = patientApps.where((a) => a.status == 'CANCELLED').length;
          final noShowRate = patientApps.isEmpty ? 0.0 : (cancelled / patientApps.length) * 100;
          final totalRemaining = patientApps.fold(0.0, (s, a) => s + a.remainingAmount);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: p.gender == 'MALE' ? Colors.blue.shade100 : Colors.pink.shade100,
                child: Icon(Icons.person, color: p.gender == 'MALE' ? Colors.blue : Colors.pink),
              ),
              title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('جوال: ${p.phone} • العمر: ${p.age} • زيارات: ${patientApps.length}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('غياب: ${noShowRate.toStringAsFixed(0)}%', style: TextStyle(color: noShowRate > 20 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      if (totalRemaining > 0)
                        Text('ديون: $totalRemaining ر.ي', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.contact_page_outlined, size: 22, color: Color(0xFF1E3A8A)),
                    tooltip: 'عرض الملف الطبي الشامل',
                    onPressed: () => _openPatientProfileDialog(p),
                  ),
                ],
              ),
              children: [
                if (p.chronicDiseases.isNotEmpty || p.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('الأمراض المزمنة / الحساسية: ${p.chronicDiseases.isNotEmpty ? p.chronicDiseases : p.notes}', style: const TextStyle(color: Colors.brown, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                          onPressed: () => _openQuickBookingDialog(prefilledPatient: p, initialVisitType: 'RETURN_VISIT'),
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('تسجيل عودة مجانية'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openQuickBookingDialog(prefilledPatient: p, initialVisitType: 'NEW_VISIT'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('كشف جديد'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'تعديل بيانات وأمراض المريض',
                        onPressed: () => _openEditPatientDialog(p),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(alignment: Alignment.centerRight, child: Text('سجل الزيارات السابقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                ...patientApps.map((pa) => ListTile(
                  dense: true,
                  title: Text('${pa.appointmentDate} - ${pa.doctorName} (${pa.visitType == 'RETURN_VISIT' ? 'مراجعة' : 'كشف'})'),
                  subtitle: Text('الحالة: ${pa.status} | مدفوع: ${pa.paidAmount} ر.ي | متبقي: ${pa.remainingAmount} ر.ي'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pa.remainingAmount > 0)
                        IconButton(
                          icon: const Icon(Icons.payment, size: 18, color: Colors.green),
                          tooltip: 'سداد المتبقي',
                          onPressed: () => _openPayRemainingDialog(pa),
                        ),
                      IconButton(
                        icon: const Icon(Icons.print, size: 18),
                        onPressed: () => _printReceiptPdf(pa),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _openPatientProfileDialog(PatientModel patient) {
    final patientApps = appointments.where((a) => a.patientPhone == patient.phone).toList();
    final totalRemaining = patientApps.fold(0.0, (s, a) => s + a.remainingAmount);
    final totalPaid = patientApps.fold(0.0, (s, a) => s + a.paidAmount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('جوال: ${patient.phone} | العمر: ${patient.age} سنة', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.healing, color: Colors.brown, size: 18),
                          SizedBox(width: 6),
                          Text('الأمراض المزمنة / فصيلة الدم / الحساسية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(patient.chronicDiseases.isNotEmpty ? patient.chronicDiseases : 'لا توجد أمراض مزمنة مسجلة.', style: const TextStyle(fontSize: 12)),
                      if (patient.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('ملاحظات خاصة: ${patient.notes}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            const Text('إجمالي المدفوعات', style: TextStyle(fontSize: 11, color: Colors.green)),
                            Text('$totalPaid ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            const Text('المتبقي في الذمة', style: TextStyle(fontSize: 11, color: Colors.red)),
                            Text('$totalRemaining ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('أرشيف المواعيد والتشخيصات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                if (patientApps.isEmpty) const Text('لا توجد مواعيد سابقة مسجلة.'),
                ...patientApps.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${a.appointmentDate} - ${a.startTime}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('${a.doctorName} (${a.visitType == "RETURN_VISIT" ? "عودة مجانية" : "كشف"})', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      Text('الحالة: ${a.status}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openEditPatientDialog(patient);
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('تعديل الملف الصحي'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _openEditPatientDialog(PatientModel patient) {
    final nameCtrl = TextEditingController(text: patient.fullName);
    final phoneCtrl = TextEditingController(text: patient.phone);
    final ageCtrl = TextEditingController(text: patient.age.toString());
    final notesCtrl = TextEditingController(text: patient.notes);
    final chronicCtrl = TextEditingController(text: patient.chronicDiseases);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الملف الطبي للمريض والتشخيص'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الجوال')),
              TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر')),
              TextField(controller: chronicCtrl, decoration: const InputDecoration(labelText: 'الأمراض المزمنة / فصيلة الدم')),
              TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات الطبيب وسير العمل')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () async {
              setState(() {
                patient.fullName = nameCtrl.text.trim();
                patient.phone = phoneCtrl.text.trim();
                patient.age = int.tryParse(ageCtrl.text) ?? patient.age;
                patient.notes = notesCtrl.text.trim();
                patient.chronicDiseases = chronicCtrl.text.trim();
              });
              await _saveAllLocally();
              try {
                await Supabase.instance.client.from('patients').upsert(patient.toMap());
              } catch (_) {}
              Navigator.pop(ctx);
              _showNotification('الملف الطبي', 'تم حفظ تعديل الملف الصحي للمريض ${patient.fullName}');
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  // ================= تبويب أرشيف الأيام والتقارير =================
  Widget _buildAuditHistoryView() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedAuditDate);
    final dayApps = currentRoleAppointments.where((a) => a.appointmentDate == selectedDateStr).toList();
    final dayIncome = dayApps.where((a) => a.status != 'CANCELLED').fold(0.0, (s, a) => s + a.paidAmount);
    final dayRemaining = dayApps.where((a) => a.status != 'CANCELLED').fold(0.0, (s, a) => s + a.remainingAmount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('أرشيف حركة الأيام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: selectedAuditDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => selectedAuditDate = d);
              },
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(selectedDateStr),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _metricBox('المرضى', '${dayApps.length}', Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _metricBox('المحصل', '$dayIncome ر.ي', Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _metricBox('المتبقي', '$dayRemaining ر.ي', Colors.red)),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () => _printDailyClosingPdf(selectedAuditDate, dayApps),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('تصدير وحفظ تقرير هذا اليوم PDF'),
        ),
        const SizedBox(height: 16),
        const Text('كشوفات هذا اليوم بالتفصيل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (dayApps.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد سجلات في هذا اليوم'))),
        ...dayApps.map((a) => Card(
          child: ListTile(
            title: Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${a.doctorName} • ${a.startTime} • ${a.status} (${a.visitType == 'RETURN_VISIT' ? 'عودة' : 'كشف'})'),
            trailing: Text('دفع: ${a.paidAmount} ر.ي\nباقي: ${a.remainingAmount} ر.ي', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        )),
      ],
    );
  }

  // ================= تبويب المالية =================
  Widget _buildFinanceView() {
    final list = currentRoleAppointments;
    final totalCash = list.where((a) => a.status != 'CANCELLED' && a.paymentMethod == 'CASH').fold(0.0, (s, a) => s + a.paidAmount);
    final totalNetwork = list.where((a) => a.status != 'CANCELLED' && a.paymentMethod == 'NETWORK').fold(0.0, (s, a) => s + a.paidAmount);
    final totalInsurance = list.where((a) => a.status != 'CANCELLED' && a.paymentMethod == 'INSURANCE').fold(0.0, (s, a) => s + a.paidAmount);
    final totalRemaining = list.where((a) => a.status != 'CANCELLED').fold(0.0, (s, a) => s + a.remainingAmount);
    final grandTotal = totalCash + totalNetwork + totalInsurance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('الإغلاق المالي الشامل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إجمالي الدخل المحصل الفعلي', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('$grandTotal ر.ي', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricBox('نقدي', '$totalCash ر.ي', Colors.green)),
            const SizedBox(width: 6),
            Expanded(child: _metricBox('شبكة/حوالة', '$totalNetwork ر.ي', Colors.blue)),
            const SizedBox(width: 6),
            Expanded(child: _metricBox('تأمين', '$totalInsurance ر.ي', Colors.orange)),
          ],
        ),
        const SizedBox(height: 10),
        _metricBox('إجمالي الديون والآجل المتبقي على المرضى', '$totalRemaining ر.ي', Colors.red),
      ],
    );
  }

  // ================= تبويب إدارة العيادات والخدمات =================
  Widget _buildManagementAndServicesView() {
    final isSecretary = widget.currentUser.role == 'DOCTOR_SECRETARY';
    final currentDocId = isSecretary ? widget.currentUser.linkedDoctorId : null;

    final displayServices = isSecretary
        ? services.where((s) => s.doctorId == currentDocId).toList()
        : services;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isSecretary ? 'خدمات وإجراءات عيادتك' : 'الخدمات والإجراءات الطبية', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () => _openServiceDialog(defaultDocId: currentDocId),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('خدمة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (displayServices.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('لم يتم تحديد خدمات إضافية')),
        ...displayServices.map((s) {
          final doc = doctors.cast<DoctorModel?>().firstWhere((d) => d?.id == s.doctorId, orElse: () => null);
          return Card(
            child: ListTile(
              leading: const Icon(Icons.medical_services, color: Color(0xFF1E3A8A)),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('السعر: ${s.price} ر.ي ${doc != null ? "• عيادة: ${doc.name}" : ""}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () => _openServiceDialog(defaultDocId: s.doctorId, existingService: s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _deleteService(s),
                  ),
                ],
              ),
            ),
          );
        }),

        if (widget.currentUser.role == 'ADMIN') ...[
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة الأطباء والعيادات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                onPressed: () => _openDoctorDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('طبيب جديد'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...doctors.map((d) => Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${d.specialty} • كشف: ${d.consultationFee} ر.ي\n'
                    'الدوام: ${d.workStartTime} إلى ${d.workEndTime}\n'
                    'حجز الاستقبال: ${d.allowReceptionBooking ? "مسموح للاستقبال بالحجز" : "محظور (للسكرتير فقط)"}',
                    style: TextStyle(
                      color: d.allowReceptionBooking ? Colors.green.shade900 : Colors.red.shade900,
                      fontSize: 12,
                    ),
                  ),
                  isThreeLine: true,
                  value: d.allowReceptionBooking,
                  activeColor: const Color(0xFF1E3A8A),
                  onChanged: (val) async {
                    setState(() {
                      final idx = doctors.indexWhere((item) => item.id == d.id);
                      doctors[idx] = DoctorModel(
                        id: d.id,
                        name: d.name,
                        specialty: d.specialty,
                        consultationFee: d.consultationFee,
                        durationMinutes: d.durationMinutes,
                        workStartTime: d.workStartTime,
                        workEndTime: d.workEndTime,
                        allowReceptionBooking: val,
                        isActive: d.isActive,
                      );
                    });
                    await _saveAllLocally();
                    try {
                      await Supabase.instance.client
                          .from('doctors')
                          .update({'allow_reception_booking': val})
                          .eq('id', d.id);
                    } catch (_) {}
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل البيانات والدوام'),
                        onPressed: () => _openDoctorDialog(existingDoctor: d),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('حذف الطبيب'),
                        onPressed: () => _deleteDoctor(d),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة المستخدمين وحسابات الموظفين', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                onPressed: () => _openUserDialog(),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('مستخدم جديد'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...users.map((u) {
            final linkedDoc = doctors.cast<DoctorModel?>().firstWhere((d) => d?.id == u.linkedDoctorId, orElse: () => null);
            final isSelf = u.id == widget.currentUser.id;

            return Card(
              child: ListTile(
                leading: Icon(u.role == 'ADMIN' ? Icons.security : (u.role == 'DOCTOR_SECRETARY' ? Icons.badge : Icons.support_agent)),
                title: Text('${u.name} ${isSelf ? "(أنت - المدير الحالي)" : ""}'),
                subtitle: Text('${u.email}\nالدور: ${u.role}${linkedDoc != null ? ' (مرتبط بـ ${linkedDoc.name})' : ''}'),
                isThreeLine: u.linkedDoctorId != null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'تعديل المستخدم',
                      onPressed: () => _openUserDialog(existingUser: u),
                    ),
                    if (!isSelf)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'حذف الحساب',
                        onPressed: () => _deleteUser(u),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _openDoctorDialog({DoctorModel? existingDoctor}) {
    final nameCtrl = TextEditingController(text: existingDoctor?.name ?? '');
    final specCtrl = TextEditingController(text: existingDoctor?.specialty ?? '');
    final feeCtrl = TextEditingController(text: existingDoctor?.consultationFee.toStringAsFixed(0) ?? '3000');
    final durCtrl = TextEditingController(text: existingDoctor?.durationMinutes.toString() ?? '15');
    final startCtrl = TextEditingController(text: existingDoctor?.workStartTime ?? '09:00:00');
    final endCtrl = TextEditingController(text: existingDoctor?.workEndTime ?? '17:00:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingDoctor == null ? 'إضافة طبيب جديد وعيادة' : 'تعديل بيانات الطبيب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الطبيب')),
              TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'التخصص')),
              TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المعاينة (ر.ي)')),
              TextField(controller: durCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدة الكشف (بالدقائق)')),
              TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'بداية الدوام (09:00:00)')),
              TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'نهاية الدوام (17:00:00)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              if (existingDoctor == null) {
                final newDoc = DoctorModel(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                  consultationFee: double.tryParse(feeCtrl.text) ?? 3000.0,
                  durationMinutes: int.tryParse(durCtrl.text) ?? 15,
                  workStartTime: startCtrl.text.trim(),
                  workEndTime: endCtrl.text.trim(),
                  allowReceptionBooking: true,
                  isActive: true,
                );
                setState(() => doctors.add(newDoc));
                await _saveAllLocally();
                try {
                  await Supabase.instance.client.from('doctors').upsert(newDoc.toMap());
                } catch (_) {}
                _showNotification('إدارة الأطباء', 'تمت إضافة الطبيب ${newDoc.name} بنجاح');
              } else {
                setState(() {
                  existingDoctor.name = nameCtrl.text.trim();
                  existingDoctor.specialty = specCtrl.text.trim();
                  existingDoctor.consultationFee = double.tryParse(feeCtrl.text) ?? existingDoctor.consultationFee;
                  existingDoctor.durationMinutes = int.tryParse(durCtrl.text) ?? existingDoctor.durationMinutes;
                  existingDoctor.workStartTime = startCtrl.text.trim();
                  existingDoctor.workEndTime = endCtrl.text.trim();
                });
                await _saveAllLocally();
                try {
                  await Supabase.instance.client.from('doctors').upsert(existingDoctor.toMap());
                } catch (_) {}
                _showNotification('إدارة الأطباء', 'تم تحديث بيانات الطبيب ${existingDoctor.name}');
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteDoctor(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الطبيب'),
        content: Text('هل أنت متأكد من حذف الطبيب "${doc.name}"؟ سيتم حذف ربطه بالمواعيد والخدمات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() => doctors.removeWhere((d) => d.id == doc.id));
              await _saveAllLocally();
              try {
                await Supabase.instance.client.from('doctors').delete().eq('id', doc.id);
              } catch (_) {}
              Navigator.pop(ctx);
              _showNotification('حذف طبيب', 'تم حذف الطبيب ${doc.name} من النظام');
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  void _openServiceDialog({String? defaultDocId, ClinicServiceModel? existingService}) {
    final nameCtrl = TextEditingController(text: existingService?.name ?? '');
    final priceCtrl = TextEditingController(text: existingService?.price.toStringAsFixed(0) ?? '1500');
    String? assignedDocId = existingService?.doctorId ?? defaultDocId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingService == null ? 'إضافة خدمة / إجراء طبي' : 'تعديل الخدمة الطبية'),
        content: StatefulBuilder(
          builder: (context, setDlgState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الإجراء (معاينة، ضرب إبرة، غيار...)'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر بالريال اليمني'),
              ),
              if (widget.currentUser.role == 'ADMIN') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: assignedDocId,
                  decoration: const InputDecoration(labelText: 'تخصيص لعيادة طبيب محدد (اختياري)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('عام لكافة العيادات')),
                    ...doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setDlgState(() => assignedDocId = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              if (existingService == null) {
                final newSrv = ClinicServiceModel(
                  id: const Uuid().v4(),
                  doctorId: assignedDocId,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0.0,
                  isActive: true,
                );
                setState(() => services.add(newSrv));
                await _saveAllLocally();
                try {
                  await Supabase.instance.client.from('clinic_services').upsert(newSrv.toMap());
                } catch (_) {}
                _showNotification('الخدمات الطبية', 'تمت إضافة الخدمة ${newSrv.name}');
              } else {
                setState(() {
                  existingService.name = nameCtrl.text.trim();
                  existingService.price = double.tryParse(priceCtrl.text) ?? existingService.price;
                });
                await _saveAllLocally();
                try {
                  await Supabase.instance.client.from('clinic_services').upsert(existingService.toMap());
                } catch (_) {}
                _showNotification('الخدمات الطبية', 'تم تحديث الخدمة ${existingService.name}');
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteService(ClinicServiceModel srv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الخدمة'),
        content: Text('هل أنت متأكد من حذف خدمة "${srv.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() => services.removeWhere((s) => s.id == srv.id));
              await _saveAllLocally();
              try {
                await Supabase.instance.client.from('clinic_services').delete().eq('id', srv.id);
              } catch (_) {}
              Navigator.pop(ctx);
              _showNotification('حذف خدمة', 'تم حذف الخدمة ${srv.name}');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _openUserDialog({UserModel? existingUser}) {
    final nameCtrl = TextEditingController(text: existingUser?.name ?? '');
    final emailCtrl = TextEditingController(text: existingUser?.email ?? '');
    final passCtrl = TextEditingController(text: existingUser?.password ?? '123456');
    String role = existingUser?.role ?? 'RECEPTIONIST';
    String? linkedDoctorId = existingUser?.linkedDoctorId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingUser == null ? 'إضافة مستخدم جديد' : 'تعديل المستخدم والصلاحيات'),
        content: StatefulBuilder(
          builder: (context, setDlgState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'كلمة المرور')),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('مدير النظام')),
                    DropdownMenuItem(value: 'DOCTOR_SECRETARY', child: Text('سكرتير طبيب')),
                    DropdownMenuItem(value: 'RECEPTIONIST', child: Text('موظف استقبال')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => role = v);
                  },
                ),
                if (role == 'DOCTOR_SECRETARY') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: linkedDoctorId,
                    decoration: const InputDecoration(labelText: 'الطبيب المرتبط به حصرياً'),
                    items: doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                    onChanged: (v) => setDlgState(() => linkedDoctorId = v),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;

              if (existingUser == null) {
                final newUser = UserModel(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: role,
                  linkedDoctorId: role == 'DOCTOR_SECRETARY' ? linkedDoctorId : null,
                  isActive: true,
                );
                setState(() => users.add(newUser));
                await _saveAllLocally();
                try {
                  await Supabase.instance.client.from('users').upsert(newUser.toMap());
                } catch (_) {}
                _showNotification('إدارة المستخدمين', 'تم إنشاء حساب ${newUser.name}');
              } else {
                setState(() {
                  existingUser.name = nameCtrl.text.trim();
                  existingUser.email = emailCtrl.text.trim();
                  existingUser.password = passCtrl.text.trim();
                  existingUser.role = role;
                  existingUser.linkedDoctorId = role == 'DOCTOR_SECRETARY' ? linkedDoctorId : null;
                });
                await _saveAllLocally();
                try {
                  await Supabase.instance.client.from('users').upsert(existingUser.toMap());
                } catch (_) {}
                _showNotification('إدارة المستخدمين', 'تم تحديث حساب ${existingUser.name}');
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: Text('هل أنت متأكد من حذف حساب "${user.name}" نهائياً من النظام؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() => users.removeWhere((u) => u.id == user.id));
              await _saveAllLocally();
              try {
                await Supabase.instance.client.from('users').delete().eq('id', user.id);
              } catch (_) {}
              Navigator.pop(ctx);
              _showNotification('حذف مستخدم', 'تم حذف حساب ${user.name}');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String title, String val, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color.shade900, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
