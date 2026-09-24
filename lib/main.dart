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
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
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
          background: const Color(0xFFF8FAFC),
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
  final String name;
  final String email;
  final String password;
  final String role;
  final String? linkedDoctorId;
  final bool isActive;

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
  final String name;
  final String specialty;
  final double consultationFee;
  final int durationMinutes;
  final String workStartTime;
  final String workEndTime;
  final bool allowReceptionBooking;
  final bool isActive;

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
    consultationFee: (m['consultation_fee'] as num?)?.toDouble() ?? 50.0,
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
  final String name;
  final double price;
  final bool isActive;

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

  PatientModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.age,
    required this.gender,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'age': age,
    'gender': gender,
    'notes': notes,
  };

  factory PatientModel.fromMap(Map<String, dynamic> m) => PatientModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    fullName: m['full_name'] ?? m['fullName'] ?? '',
    phone: m['phone'] ?? '',
    age: (m['age'] as num?)?.toInt() ?? 25,
    gender: m['gender'] ?? 'MALE',
    notes: m['notes'] ?? '',
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
  final bool isSynced;

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
    'doctor_name': doctorName,
    'patient_id': patientId,
    'patient_name': patientName,
    'patient_phone': patientPhone,
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
    'created_by_role': createdByRole,
    'is_synced': isSynced,
  };

  factory AppointmentModel.fromMap(Map<String, dynamic> m) => AppointmentModel(
    id: m['id']?.toString() ?? const Uuid().v4(),
    doctorId: m['doctor_id']?.toString() ?? '',
    doctorName: m['doctor_name'] ?? '',
    patientId: m['patient_id']?.toString() ?? '',
    patientName: m['patient_name'] ?? '',
    patientPhone: m['patient_phone'] ?? '',
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
    isSynced: m['is_synced'] ?? false,
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

  List<UserModel> users = [];
  List<DoctorModel> doctors = [];
  List<ClinicServiceModel> services = [];
  List<PatientModel> patients = [];
  List<AppointmentModel> appointments = [];
  List<PaymentReceiptModel> payments = [];
  List<AppointmentServiceModel> appointmentServices = [];

  DateTime selectedCalendarDate = DateTime.now();
  DateTime selectedAuditDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _initSupabaseRealtime();
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
      Supabase.instance.client
          .channel('public:clinic_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'appointments',
            callback: (p) => _syncWithSupabase(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime error: $e');
    }
  }

  Future<void> _syncWithSupabase() async {
    if (isSyncing) return;
    setState(() => isSyncing = true);

    try {
      final client = Supabase.instance.client;

      final unsynced = appointments.where((a) => !a.isSynced).toList();
      for (var app in unsynced) {
        await client.from('appointments').upsert({
          'id': app.id,
          'doctor_id': app.doctorId,
          'patient_id': app.patientId,
          'created_by_role': app.createdByRole,
          'appointment_date': app.appointmentDate,
          'start_time': app.startTime,
          'end_time': app.endTime,
          'visit_type': app.visitType,
          'status': app.status,
          'total_amount': app.totalAmount,
          'paid_amount': app.paidAmount,
          'remaining_amount': app.remainingAmount,
          'payment_method': app.paymentMethod,
          'payment_status': app.paymentStatus,
        });
      }

      // مزامنة الدفعات المنفصلة
      for (var pay in payments) {
        await client.from('payments').upsert({
          'id': pay.id,
          'appointment_id': pay.appointmentId,
          'patient_id': pay.patientId,
          'amount': pay.amount,
          'payment_method': pay.paymentMethod,
          'payment_date': pay.paymentDate,
        });
      }

      // مزامنة تفاصيل الخدمات
      for (var asrv in appointmentServices) {
        await client.from('appointment_services').upsert({
          'id': asrv.id,
          'appointment_id': asrv.appointmentId,
          'service_name': asrv.serviceName,
          'price': asrv.price,
        });
      }

      final dRes = await client.from('doctors').select();
      final sRes = await client.from('clinic_services').select();
      final pRes = await client.from('patients').select();
      final aRes = await client.from('appointments').select();
      final uRes = await client.from('users').select();

      setState(() {
        doctors = (dRes as List).map((e) => DoctorModel.fromMap(e)).toList();
        services = (sRes as List).map((e) => ClinicServiceModel.fromMap(e)).toList();
        patients = (pRes as List).map((e) => PatientModel.fromMap(e)).toList();
        users = (uRes as List).map((e) => UserModel.fromMap(e)).toList();

        appointments = (aRes as List).map((m) {
          final d = doctors.cast<DoctorModel?>().firstWhere((doc) => doc?.id == m['doctor_id'], orElse: () => null);
          final p = patients.cast<PatientModel?>().firstWhere((pat) => pat?.id == m['patient_id'], orElse: () => null);
          return AppointmentModel(
            id: m['id'],
            doctorId: m['doctor_id'],
            doctorName: d?.name ?? 'طبيب غير محدد',
            patientId: m['patient_id'],
            patientName: p?.fullName ?? 'مريض غير محدد',
            patientPhone: p?.phone ?? '',
            appointmentDate: m['appointment_date'],
            startTime: m['start_time'],
            endTime: m['end_time'] ?? m['start_time'],
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
        }).toList();
      });

      await _saveAllLocally();
    } catch (e) {
      debugPrint('Sync mode: working locally');
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
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

  // ================= طباعة سند القبض PDF =================
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
                  pw.Text('نوع الزيارة: ${app.visitType == 'NEW_VISIT' ? 'كشف جديد' : 'مراجعة / عودة'}'),
                  if (attachedServices.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('الخدمات والفحوصات المرفقة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...attachedServices.map((s) => pw.Text('- ${s.serviceName}: ${s.price} ريال')),
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
                            pw.Text('${app.totalAmount} ريال', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('المدفوع في هذا السند:'),
                            pw.Text('${receipt?.amount ?? app.paidAmount} ريال', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('المتبقي في الذمة:'),
                            pw.Text('${app.remainingAmount} ريال', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
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

  // ================= طباعة تقرير اليوم PDF =================
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
                    pw.Text('المحصل: $totalIncome ريال', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Text('المتبقي: $totalRemaining ريال', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Table.fromTextArray(
                  headers: ['المريض', 'الطبيب', 'الوقت', 'النوع', 'الحالة', 'المدفوع', 'المتبقي'],
                  data: dayApps.map((a) => [
                    a.patientName,
                    a.doctorName,
                    a.startTime,
                    a.visitType == 'NEW_VISIT' ? 'جديد' : 'عودة',
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

  // ================= نافذة سداد دفعة للمتبقي =================
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
            Text('المبلغ المتبقي الحالي: ${app.remainingAmount} ريال', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
                DropdownMenuItem(value: 'NETWORK', child: Text('شبكة/مدى')),
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
            onPressed: () {
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

              _saveAllLocally();
              _syncWithSupabase();
              Navigator.pop(ctx);
              _printReceiptPdf(app, newReceipt);
            },
            child: const Text('تأكيد السداد وطباعة السند'),
          ),
        ],
      ),
    );
  }

  // ================= الحجز السريع المطور =================
  void _openQuickBookingDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '25');
    final paidCtrl = TextEditingController();

    List<DoctorModel> availableDocs = doctors.where((d) => d.isActive).toList();
    if (widget.currentUser.role == 'RECEPTIONIST') {
      availableDocs = availableDocs.where((d) => d.allowReceptionBooking).toList();
    } else if (widget.currentUser.role == 'DOCTOR_SECRETARY') {
      availableDocs = availableDocs.where((d) => d.id == widget.currentUser.linkedDoctorId).toList();
    }

    if (availableDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عيادات مصرح لك بالحجز لها حالياً')),
      );
      return;
    }

    DoctorModel selectedDoc = availableDocs.first;
    List<String> availableSlots = _generateTimeSlots(selectedDoc);
    String selectedTime = availableSlots.isNotEmpty ? availableSlots.first : '09:00 ص';
    String visitType = 'NEW_VISIT';
    String paymentMethod = 'CASH';

    List<ClinicServiceModel> selectedExtraServices = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double totalFee = (visitType == 'RETURN_VISIT' ? 0.0 : selectedDoc.consultationFee) +
                selectedExtraServices.fold(0.0, (s, item) => s + item.price);

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
                        const Text('حجز موعد طبي متكامل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم المريض الكامل', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'رقم الجوال', prefixIcon: Icon(Icons.phone_outlined)),
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
                      decoration: const InputDecoration(labelText: 'الطبيب والعيادة', prefixIcon: Icon(Icons.medical_services_outlined)),
                      items: availableDocs.map((doc) => DropdownMenuItem(value: doc, child: Text('${doc.name} (${doc.specialty})'))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedDoc = val;
                            availableSlots = _generateTimeSlots(selectedDoc);
                            if (availableSlots.isNotEmpty) selectedTime = availableSlots.first;
                            paidCtrl.text = selectedDoc.consultationFee.toStringAsFixed(0);
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
                            decoration: const InputDecoration(labelText: 'نوع الزيارة'),
                            items: const [
                              DropdownMenuItem(value: 'NEW_VISIT', child: Text('كشف جديد')),
                              DropdownMenuItem(value: 'RETURN_VISIT', child: Text('مراجعة / عودة (مجانية)')),
                              DropdownMenuItem(value: 'CONSULTATION', child: Text('استشارة')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() {
                                  visitType = v;
                                  paidCtrl.text = (visitType == 'RETURN_VISIT' ? 0.0 : selectedDoc.consultationFee).toStringAsFixed(0);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedTime,
                            decoration: const InputDecoration(labelText: 'وقت الحجز (ضمن الدوام)'),
                            items: availableSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedTime = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (services.isNotEmpty) ...[
                      const Text('خدمات وفحوصات إضافية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Wrap(
                        spacing: 6,
                        children: services.map((srv) {
                          final isSelected = selectedExtraServices.contains(srv);
                          return FilterChip(
                            label: Text('${srv.name} (+${srv.price} ر.س)'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedExtraServices.add(srv);
                                } else {
                                  selectedExtraServices.remove(srv);
                                }
                                double total = (visitType == 'RETURN_VISIT' ? 0.0 : selectedDoc.consultationFee) +
                                    selectedExtraServices.fold(0.0, (s, item) => s + item.price);
                                paidCtrl.text = total.toStringAsFixed(0);
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
                            decoration: const InputDecoration(labelText: 'المبلغ المدفوع الآن'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: const InputDecoration(labelText: 'وسيلة الدفع'),
                            items: const [
                              DropdownMenuItem(value: 'CASH', child: Text('نقدي')),
                              DropdownMenuItem(value: 'NETWORK', child: Text('شبكة/مدى')),
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
                      onPressed: () {
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
                        double remaining = (totalFee - paid).clamp(0.0, 99999.0);

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
                          remainingAmo
