import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

const String supabaseUrl = 'https://nlggetwdohewdhnlykxf.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sZ2dldHdkb2hld2Robmx5a3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxOTQxNDUsImV4cCI6MjEwNTc3MDE0NX0.P1Q1A-4aONqrAB_R_-yZ0U5yzHd_SC2nBNrIWWxjUGY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init: $e');
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
          centerTitle: false,
        ),
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ClinicMainDashboard(),
    );
  }
}

// ========================== MODELS ==========================
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // ADMIN, DOCTOR_SECRETARY, RECEPTIONIST
  final bool isActive;

  UserModel({required this.id, required this.name, required this.email, required this.role, required this.isActive});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email, 'role': role, 'isActive': isActive};
  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'] ?? const Uuid().v4(),
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    role: m['role'] ?? 'RECEPTIONIST',
    isActive: m['isActive'] ?? true,
  );
}

class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final int durationMinutes;
  final double fee;
  final bool allowReceptionBooking;
  final String assignedSecretaryId;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.durationMinutes,
    required this.fee,
    required this.allowReceptionBooking,
    required this.assignedSecretaryId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'specialty': specialty,
    'durationMinutes': durationMinutes,
    'fee': fee,
    'allowReceptionBooking': allowReceptionBooking,
    'assignedSecretaryId': assignedSecretaryId,
  };

  factory DoctorModel.fromMap(Map<String, dynamic> m) => DoctorModel(
    id: m['id'] ?? const Uuid().v4(),
    name: m['name'] ?? '',
    specialty: m['specialty'] ?? '',
    durationMinutes: m['durationMinutes'] ?? 15,
    fee: (m['fee'] as num?)?.toDouble() ?? 50.0,
    allowReceptionBooking: m['allowReceptionBooking'] ?? true,
    assignedSecretaryId: m['assignedSecretaryId'] ?? '',
  );
}

class PatientModel {
  final String id;
  final String fullName;
  final String phone;
  final int age;
  final String gender; // MALE, FEMALE
  final String notes;

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
    'fullName': fullName,
    'phone': phone,
    'age': age,
    'gender': gender,
    'notes': notes,
  };

  factory PatientModel.fromMap(Map<String, dynamic> m) => PatientModel(
    id: m['id'] ?? const Uuid().v4(),
    fullName: m['fullName'] ?? '',
    phone: m['phone'] ?? '',
    age: m['age'] ?? 25,
    gender: m['gender'] ?? 'MALE',
    notes: m['notes'] ?? '',
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
  final String status; // CONFIRMED, WAITING, IN_ROOM, COMPLETED, CANCELLED, WAITING_LIST
  final String paymentMethod; // CASH, NETWORK, INSURANCE
  final String paymentStatus; // PAID, PENDING
  final String createdByRole; // ADMIN, DOCTOR_SECRETARY, RECEPTIONIST
  final double fee;
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
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdByRole,
    required this.fee,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'patientId': patientId,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'appointmentDate': appointmentDate,
    'startTime': startTime,
    'status': status,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'createdByRole': createdByRole,
    'fee': fee,
    'isSynced': isSynced,
  };

  factory AppointmentModel.fromMap(Map<String, dynamic> m) => AppointmentModel(
    id: m['id'] ?? const Uuid().v4(),
    doctorId: m['doctorId'] ?? '',
    doctorName: m['doctorName'] ?? '',
    patientId: m['patientId'] ?? '',
    patientName: m['patientName'] ?? '',
    patientPhone: m['patientPhone'] ?? '',
    appointmentDate: m['appointmentDate'] ?? '',
    startTime: m['startTime'] ?? '',
    status: m['status'] ?? 'CONFIRMED',
    paymentMethod: m['paymentMethod'] ?? 'CASH',
    paymentStatus: m['paymentStatus'] ?? 'PAID',
    createdByRole: m['createdByRole'] ?? 'RECEPTIONIST',
    fee: (m['fee'] as num?)?.toDouble() ?? 50.0,
    isSynced: m['isSynced'] ?? false,
  );
}

// ========================== MAIN DASHBOARD ==========================
class ClinicMainDashboard extends StatefulWidget {
  const ClinicMainDashboard({super.key});

  @override
  State<ClinicMainDashboard> createState() => _ClinicMainDashboardState();
}

class _ClinicMainDashboardState extends State<ClinicMainDashboard> {
  int _currentIndex = 0;
  String currentRole = 'ADMIN'; // ADMIN, DOCTOR_SECRETARY, RECEPTIONIST
  bool isSyncing = false;

  List<UserModel> users = [];
  List<DoctorModel> doctors = [];
  List<PatientModel> patients = [];
  List<AppointmentModel> appointments = [];

  // Active Secretary Doctor Link (For Secretary view)
  String activeSecretaryDoctorId = '';

  @override
  void initState() {
    super.initState();
    _initDefaultData();
  }

  Future<void> _initDefaultData() async {
    final prefs = await SharedPreferences.getInstance();
    final appsData = prefs.getString('clinic_appointments');
    final docsData = prefs.getString('clinic_doctors');
    final usersData = prefs.getString('clinic_users');
    final patientsData = prefs.getString('clinic_patients');

    if (usersData != null) {
      users = (jsonDecode(usersData) as List).map((e) => UserModel.fromMap(e)).toList();
    } else {
      users = [
        UserModel(id: 'u1', name: 'المدير العام', email: 'admin@clinic.com', role: 'ADMIN', isActive: true),
        UserModel(id: 'u2', name: 'منى السكرتيرة', email: 'mona@clinic.com', role: 'DOCTOR_SECRETARY', isActive: true),
        UserModel(id: 'u3', name: 'أحمد الاستقبال', email: 'ahmed@clinic.com', role: 'RECEPTIONIST', isActive: true),
      ];
    }

    if (docsData != null) {
      doctors = (jsonDecode(docsData) as List).map((e) => DoctorModel.fromMap(e)).toList();
    } else {
      doctors = [
        DoctorModel(
          id: 'doc1',
          name: 'د. سامي القحطاني',
          specialty: 'استشاري الباطنية والقلب',
          durationMinutes: 20,
          fee: 150.0,
          allowReceptionBooking: true,
          assignedSecretaryId: 'u2',
        ),
        DoctorModel(
          id: 'doc2',
          name: 'د. ريم الشهري',
          specialty: 'أخصائية طب وجراحة العيون',
          durationMinutes: 15,
          fee: 120.0,
          allowReceptionBooking: false, // لا يسمح للاستقبال بالحجز
          assignedSecretaryId: 'u2',
        ),
      ];
    }
    activeSecretaryDoctorId = doctors.first.id;

    if (patientsData != null) {
      patients = (jsonDecode(patientsData) as List).map((e) => PatientModel.fromMap(e)).toList();
    } else {
      patients = [
        PatientModel(id: 'p1', fullName: 'فيصل المطيري', phone: '0551122334', age: 34, gender: 'MALE', notes: 'حساسية من البنسلين'),
        PatientModel(id: 'p2', fullName: 'نوف العنزي', phone: '0509988776', age: 28, gender: 'FEMALE', notes: 'متابعة دورية'),
      ];
    }

    if (appsData != null) {
      appointments = (jsonDecode(appsData) as List).map((e) => AppointmentModel.fromMap(e)).toList();
    } else {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      appointments = [
        AppointmentModel(
          id: const Uuid().v4(),
          doctorId: 'doc1',
          doctorName: 'د. سامي القحطاني',
          patientId: 'p1',
          patientName: 'فيصل المطيري',
          patientPhone: '0551122334',
          appointmentDate: todayStr,
          startTime: '09:00 ص',
          status: 'WAITING',
          paymentMethod: 'CASH',
          paymentStatus: 'PAID',
          createdByRole: 'RECEPTIONIST',
          fee: 150.0,
          isSynced: true,
        ),
        AppointmentModel(
          id: const Uuid().v4(),
          doctorId: 'doc1',
          doctorName: 'د. سامي القحطاني',
          patientId: 'p2',
          patientName: 'نوف العنزي',
          patientPhone: '0509988776',
          appointmentDate: todayStr,
          startTime: '09:30 ص',
          status: 'CONFIRMED',
          paymentMethod: 'NETWORK',
          paymentStatus: 'PAID',
          createdByRole: 'DOCTOR_SECRETARY',
          fee: 150.0,
          isSynced: true,
        ),
      ];
    }
    setState(() {});
    _saveAllLocally();
  }

  Future<void> _saveAllLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clinic_users', jsonEncode(users.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_doctors', jsonEncode(doctors.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_patients', jsonEncode(patients.map((e) => e.toMap()).toList()));
    await prefs.setString('clinic_appointments', jsonEncode(appointments.map((e) => e.toMap()).toList()));
  }

  // Conflict Resolution & Supabase Sync
  Future<void> _syncToSupabase() async {
    setState(() => isSyncing = true);
    try {
      final unsynced = appointments.where((a) => !a.isSynced).toList();
      if (unsynced.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جميع البيانات متطابقة ومحدثة مع السحابة')),
        );
        setState(() => isSyncing = false);
        return;
      }

      for (var app in unsynced) {
        await Supabase.instance.client.from('appointments').upsert({
          'id': app.id,
          'appointment_date': app.appointmentDate,
          'start_time': app.startTime,
          'end_time': app.startTime,
          'status': app.status,
          'appointment_type': 'CONSULTATION',
        });
      }

      setState(() {
        appointments = appointments.map((a) => AppointmentModel(
          id: a.id,
          doctorId: a.doctorId,
          doctorName: a.doctorName,
          patientId: a.patientId,
          patientName: a.patientName,
          patientPhone: a.patientPhone,
          appointmentDate: a.appointmentDate,
          startTime: a.startTime,
          status: a.status,
          paymentMethod: a.paymentMethod,
          paymentStatus: a.paymentStatus,
          createdByRole: a.createdByRole,
          fee: a.fee,
          isSynced: true,
        )).toList();
      });
      await _saveAllLocally();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('تمت مزامنة المواعيد مع خادم Supabase بنجاح!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: const Text('وضع عدم الاتصال: تم الحفظ محلياً بنجاح وسيتزامن عند توفر الشبكة'),
        ),
      );
    } finally {
      setState(() => isSyncing = false);
    }
  }

  // Color Coding
  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return const Color(0xFF2563EB); // أزرق: مؤكد
      case 'WAITING':
        return const Color(0xFFD97706); // أصفر: في صالة الانتظار
      case 'IN_ROOM':
        return const Color(0xFF059669); // أخضر: في غرفة الطبيب
      case 'COMPLETED':
        return const Color(0xFF64748B); // رمادي: مكتمل
      case 'CANCELLED':
        return const Color(0xFFDC2626); // أحمر: ملغى / لم يحضر
      case 'WAITING_LIST':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'مؤكد';
      case 'WAITING':
        return 'في الانتظار';
      case 'IN_ROOM':
        return 'داخل الكشف';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغى / لم يحضر';
      case 'WAITING_LIST':
        return 'قائمة الانتظار السريعة';
      default:
        return status;
    }
  }

  // Filtered Appointments based on Role
  List<AppointmentModel> get filteredAppointments {
    if (currentRole == 'ADMIN' || currentRole == 'RECEPTIONIST') {
      return appointments;
    }
    // Secretary only sees their assigned doctor's appointments
    return appointments.where((a) => a.doctorId == activeSecretaryDoctorId).toList();
  }

  // No-Show Rate for patient
  double _calculateNoShowRate(String patientPhone) {
    final list = appointments.where((a) => a.patientPhone == patientPhone).toList();
    if (list.isEmpty) return 0.0;
    final noShows = list.where((a) => a.status == 'CANCELLED').length;
    return (noShows / list.length) * 100;
  }

  // Quick Booking with Conflict Resolution
  void _openQuickBookingDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '30');

    // Available doctors filtered for Receptionist
    final availableDoctors = currentRole == 'RECEPTIONIST'
        ? doctors.where((d) => d.allowReceptionBooking).toList()
        : (currentRole == 'DOCTOR_SECRETARY'
            ? doctors.where((d) => d.id == activeSecretaryDoctorId).toList()
            : doctors);

    if (availableDoctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عيادات مصرح لك بالحجز لها حالياً')),
      );
      return;
    }

    DoctorModel selectedDoc = availableDoctors.first;
    String selectedTime = '10:00 ص';
    String paymentMethod = 'CASH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        const Text(
                          'الحجز السريع (أقل من 30 ثانية)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم المريض الكامل',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'رقم الجوال',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'العمر',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<DoctorModel>(
                      value: selectedDoc,
                      decoration: InputDecoration(
                        labelText: 'الطبيب والعيادة',
                        prefixIcon: const Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: availableDoctors.map((doc) {
                        return DropdownMenuItem<DoctorModel>(
                          value: doc,
                          child: Text('${doc.name} (${doc.specialty})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDoc = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedTime,
                            decoration: InputDecoration(
                              labelText: 'الوقت',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['09:00 ص', '09:30 ص', '10:00 ص', '10:30 ص', '11:00 ص', '11:30 ص', '12:00 م', '05:00 م', '05:30 م']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedTime = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: InputDecoration(
                              labelText: 'طريقة الدفع',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'CASH', child: Text('نقدي')),
                              DropdownMenuItem(value: 'NETWORK', child: Text('شبكة/مدى')),
                              DropdownMenuItem(value: 'INSURANCE', child: Text('تأمين طبي')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => paymentMethod = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

                        // Auto register patient if new
                        PatientModel? existingPatient = patients.cast<PatientModel?>().firstWhere(
                          (p) => p?.phone == phoneCtrl.text.trim(),
                          orElse: () => null,
                        );

                        if (existingPatient == null) {
                          existingPatient = PatientModel(
                            id: const Uuid().v4(),
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            age: int.tryParse(ageCtrl.text) ?? 25,
                            gender: 'MALE',
                            notes: 'تم التسجيل عبر الحجز السريع',
                          );
                          patients.add(existingPatient);
                        }

                        // Conflict Resolution Rule:
                        final conflictIdx = appointments.indexWhere((a) =>
                            a.doctorId == selectedDoc.id &&
                            a.startTime == selectedTime &&
                            a.status != 'CANCELLED');

                        bool conflictSecretaryWin = false;
                        if (conflictIdx != -1) {
                          final existing = appointments[conflictIdx];
                          if (currentRole == 'DOCTOR_SECRETARY' && existing.createdByRole == 'RECEPTIONIST') {
                            // Secretary wins -> Reception moved to WAITING_LIST
                            appointments[conflictIdx] = AppointmentModel(
                              id: existing.id,
                              doctorId: existing.doctorId,
                              doctorName: existing.doctorName,
                              patientId: existing.patientId,
                              patientName: existing.patientName,
                              patientPhone: existing.patientPhone,
                              appointmentDate: existing.appointmentDate,
                              startTime: existing.startTime,
                              status: 'WAITING_LIST',
                              paymentMethod: existing.paymentMethod,
                              paymentStatus: existing.paymentStatus,
                              createdByRole: existing.createdByRole,
                              fee: existing.fee,
                              isSynced: false,
                            );
                            conflictSecretaryWin = true;
                          }
                        }

                        final newAppointment = AppointmentModel(
                          id: const Uuid().v4(),
                          doctorId: selectedDoc.id,
                          doctorName: selectedDoc.name,
                          patientId: existingPatient.id,
                          patientName: existingPatient.fullName,
                          patientPhone: existingPatient.phone,
                          appointmentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          startTime: selectedTime,
                          status: (conflictIdx != -1 && currentRole == 'RECEPTIONIST') ? 'WAITING_LIST' : 'CONFIRMED',
                          paymentMethod: paymentMethod,
                          paymentStatus: 'PAID',
                          createdByRole: currentRole,
                          fee: selectedDoc.fee,
                          isSynced: false,
                        );

                        setState(() {
                          appointments.insert(0, newAppointment);
                        });
                        _saveAllLocally();
                        Navigator.pop(ctx);

                        if (conflictSecretaryWin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.deepPurple,
                              content: Text('سياسة فض النزاع: تم منح الأولوية لسكرتير الطبيب وتحويل حجز الاستقبال لقائمة الانتظار السريعة.'),
                            ),
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

  void _updateStatus(AppointmentModel item, String newStatus) {
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
          status: newStatus,
          paymentMethod: item.paymentMethod,
          paymentStatus: item.paymentStatus,
          createdByRole: item.createdByRole,
          fee: item.fee,
          isSynced: false,
        );
      }
    });
    _saveAllLocally();
  }

  // Print Receipt Dialog
  void _showReceiptDialog(AppointmentModel app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('سند قبض مالي', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم السند: ${app.id.substring(0, 8).toUpperCase()}'),
            Text('التاريخ: ${app.appointmentDate} - ${app.startTime}'),
            const Divider(),
            Text('اسم المريض: ${app.patientName}'),
            Text('الطبيب المعالج: ${app.doctorName}'),
            Text('طريقة الدفع: ${app.paymentMethod == 'CASH' ? 'نقدي' : (app.paymentMethod == 'NETWORK' ? 'شبكة/مدى' : 'تأمين طبي')}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المدفوع:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${app.fee} ريال', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال السند للطابعة بنجاح')));
            },
            icon: const Icon(Icons.print),
            label: const Text('طباعة السند'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCount = appointments.where((a) => !a.isSynced).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentRole == 'ADMIN'
              ? 'لوحة إدارة النظام'
              : (currentRole == 'DOCTOR_SECRETARY' ? 'سكرتارية العيادة' : 'الاستقبال العام'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'مزامنة السحابة (Supabase)',
            onPressed: isSyncing ? null : _syncToSupabase,
            icon: isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Badge(
                    label: Text('$unsyncedCount'),
                    isLabelVisible: unsyncedCount > 0,
                    child: const Icon(Icons.cloud_sync_outlined),
                  ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.switch_account),
            tooltip: 'تبديل الدور للتجربة',
            onSelected: (role) => setState(() => currentRole = role),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'ADMIN', child: Text('👤 مدير النظام (Admin)')),
              PopupMenuItem(value: 'DOCTOR_SECRETARY', child: Text('🩺 سكرتير الطبيب (Secretary)')),
              PopupMenuItem(value: 'RECEPTIONIST', child: Text('🛎️ موظف الاستقبال (Receptionist)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Role and Sync Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFEFF6FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الدور الحالي: ${currentRole == 'ADMIN' ? 'مدير النظام' : (currentRole == 'DOCTOR_SECRETARY' ? 'سكرتير الطبيب' : 'الاستقبال')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                if (currentRole == 'DOCTOR_SECRETARY')
                  DropdownButton<String>(
                    value: activeSecretaryDoctorId,
                    isDense: true,
                    underline: const SizedBox(),
                    items: doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (id) {
                      if (id != null) setState(() => activeSecretaryDoctorId = id);
                    },
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: unsyncedCount == 0 ? Colors.green.shade100 : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unsyncedCount == 0 ? 'مكتمل المزامنة' : '$unsyncedCount محلي أوفلاين',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: unsyncedCount == 0 ? Colors.green.shade900 : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBodyContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        onPressed: _openQuickBookingDialog,
        icon: const Icon(Icons.add),
        label: const Text('حجز سريع', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'التقويم'),
          const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'طابور الانتظار'),
          const NavigationDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared), label: 'سجل المرضى'),
          const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'المالية'),
          if (currentRole == 'ADMIN')
            const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'إدارة النظام'),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildCalendarView();
      case 1:
        return _buildQueueView();
      case 2:
        return _buildPatientsView();
      case 3:
        return _buildFinanceView();
      case 4:
        return currentRole == 'ADMIN' ? _buildAdminView() : _buildCalendarView();
      default:
        return _buildCalendarView();
    }
  }

  // ================= 1. CALENDAR VIEW =================
  Widget _buildCalendarView() {
    final list = filteredAppointments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('جدول المواعيد اليومي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('لا توجد مواعيد مسجلة حالياً لهذه العيادة.')),
          ),
        ...list.map((item) {
          final color = _getStatusColor(item.status);
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
                        child: Text(_getStatusText(item.status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${item.doctorName} • الوقت: ${item.startTime}'),
                  Text('جوال: ${item.patientPhone} | الدفع: ${item.paymentMethod} (${item.fee} ريال)', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
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
                        child: const Text('لم يحضر / إلغاء', style: TextStyle(fontSize: 11)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_outlined, size: 20, color: Color(0xFF1E3A8A)),
                        tooltip: 'طباعة السند',
                        onPressed: () => _showReceiptDialog(item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= 2. QUEUE VIEW =================
  Widget _buildQueueView() {
    final waiting = filteredAppointments.where((a) => a.status == 'WAITING').toList();
    final inRoom = filteredAppointments.where((a) => a.status == 'IN_ROOM').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('نظام طابور الانتظار والنداء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Active Inside
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.meeting_room, color: Colors.green),
                  SizedBox(width: 8),
                  Text('المرضى داخل غرفة الكشف حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
        const Text('صالة الانتظار (حسب أسبقية الحضور):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (waiting.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('صالة الانتظار فارغة حالياً'))),
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

  // ================= 3. PATIENTS VIEW =================
  Widget _buildPatientsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل المرضى الموحد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${patients.length} مريض', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ],
        ),
        const SizedBox(height: 12),
        ...patients.map((p) {
          final noShowRate = _calculateNoShowRate(p.phone);
          final visits = appointments.where((a) => a.patientPhone == p.phone).length;

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: p.gender == 'MALE' ? Colors.blue.shade100 : Colors.pink.shade100,
                child: Icon(Icons.person, color: p.gender == 'MALE' ? Colors.blue : Colors.pink),
              ),
              title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('جوال: ${p.phone} • العمر: ${p.age} • زيارات: $visits'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: noShowRate > 20 ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: noShowRate > 20 ? Colors.red : Colors.green),
                ),
                child: Text(
                  'غياب: ${noShowRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: noShowRate > 20 ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= 4. FINANCE & CLOSING VIEW =================
  Widget _buildFinanceView() {
    final list = filteredAppointments;
    final totalCash = list.where((a) => a.status != 'CANCELLED' && a.paymentMethod == 'CASH').fold(0.0, (s, a) => s + a.fee);
    final totalNetwork = list.where((a) => a.status != 'CANCELLED' && a.paymentMethod == 'NETWORK').fold(0.0, (s, a) => s + a.fee);
    final totalInsurance = list.where((a) => a.status != 'CANCELLED' && a.paymentMethod == 'INSURANCE').fold(0.0, (s, a) => s + a.fee);
    final grandTotal = totalCash + totalNetwork + totalInsurance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('التقرير المالي والإغلاق اليومي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إجمالي الإيرادات لليوم', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('$grandTotal ريال', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _metricBox('نقدي', '$totalCash ريال', Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _metricBox('شبكة/مدى', '$totalNetwork ريال', Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _metricBox('تأمين', '$totalInsurance ريال', Colors.orange)),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تقرير ختام الوردية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ListTile(title: const Text('إجمالي المرضى المسجلين'), trailing: Text('${list.length}')),
                ListTile(title: const Text('كشوفات مكتملة'), trailing: Text('${list.where((a) => a.status == 'COMPLETED').length}')),
                ListTile(title: const Text('حالات ملغاة / تغيب'), trailing: Text('${list.where((a) => a.status == 'CANCELLED').length}')),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصدير وحفظ تقرير الختام اليومي بنجاح')));
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('طباعة تقرير الإغلاق المالي'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricBox(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color.shade900, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= 5. ADMIN VIEW (System Administrator) =================
  Widget _buildAdminView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('إدارة الأطباء والعيادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...doctors.map((doc) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: SwitchListTile(
            title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${doc.specialty} • ${doc.fee} ريال • السكرتير المرتبط: ${users.firstWhere((u) => u.id == doc.assignedSecretaryId, orElse: () => users.first).name}'),
            value: doc.allowReceptionBooking,
            onChanged: (val) {
              setState(() {
                final idx = doctors.indexWhere((d) => d.id == doc.id);
                doctors[idx] = DoctorModel(
                  id: doc.id,
                  name: doc.name,
                  specialty: doc.specialty,
                  durationMinutes: doc.durationMinutes,
                  fee: doc.fee,
                  allowReceptionBooking: val,
                  assignedSecretaryId: doc.assignedSecretaryId,
                );
              });
              _saveAllLocally();
            },
          ),
        )),
        const SizedBox(height: 16),
        const Text('إدارة حسابات المستخدمين والصلاحيات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...users.map((u) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              u.role == 'ADMIN' ? Icons.security : (u.role == 'DOCTOR_SECRETARY' ? Icons.badge : Icons.support_agent),
              color: const Color(0xFF1E3A8A),
            ),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${u.email} • الدور: ${u.role}'),
            trailing: Switch(
              value: u.isActive,
              onChanged: (val) {
                setState(() {
                  final idx = users.indexWhere((item) => item.id == u.id);
                  users[idx] = UserModel(id: u.id, name: u.name, email: u.email, role: u.role, isActive: val);
                });
                _saveAllLocally();
              },
            ),
          ),
        )),
      ],
    );
  }
}
