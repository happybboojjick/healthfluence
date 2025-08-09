import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

final FlutterLocalNotificationsPlugin localNoti = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

 
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await localNoti.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel',
    'Reminders',
    description: '정확 알람/리마인더 채널',
    importance: Importance.max,
  );
  await localNoti
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

 
  await localNoti
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

 
  await localNoti
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data != null) return const HomePage();
        return const SignInPage();
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  Future<void> _emailSignIn() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } on FirebaseAuthException {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('로그인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : _emailSignIn,
              child: Text(loading ? 'Loading...' : 'Sign in / Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  Future<void> _requestExactAlarmSetting() async {
    if (!Platform.isAndroid) return;
    final info = await PackageInfo.fromPlatform();
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      data: 'package:${info.packageName}',
    );
    await intent.launch();
  }

  Future<void> _showNow(BuildContext context) async {
    await localNoti.show(
      1,
      '테스트 알림',
      '지금 바로 뜨는 로컬 알림이에요',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _scheduleLocalIn1Min(BuildContext context) async {
    try {
      final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      await localNoti.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '물 한 잔 하기',
        '지금 물 마실 시간이에요',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ 정확 알람
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('1분 뒤 정확 알람 예약됨: ${when.toLocal()}')),
        );
      }
    } catch (e) {
      
      await _requestExactAlarmSetting();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정에서 "정확한 알람" 허용 후 다시 눌러주세요')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = FirebaseFirestore.instance.collection('routines');

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: () => _showNow(context), child: const Text('즉시 알림')),
                ElevatedButton(onPressed: () => _scheduleLocalIn1Min(context), child: const Text('1분 뒤 정확 알람')),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                await routines.add({
                  'title': '아침 물 한 잔',
                  'category': 'hydration',
                  'likes': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                await routines.add({
                  'title': '점심 30분 걷기',
                  'category': 'exercise',
                  'likes': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('샘플 2개 업로드 완료')),
                  );
                }
              },
              child: const Text('샘플 데이터 넣기'),
            ),
            const SizedBox(height: 12),

            const Text('루틴 목록', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

      
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: routines.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(child: Text('데이터가 없어요'));
                  }
                  final docs = snap.data!.docs;
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = docs[i].data();
                      final id = docs[i].id;
                      final title = d['title'] ?? '(제목 없음)';
                      final category = d['category'] ?? '';
                      final likes = (d['likes'] ?? 0) as int;

                      return ListTile(
                        title: Text(title),
                        subtitle: Text(category),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$likes'),
                            IconButton(
                              icon: const Icon(Icons.thumb_up_alt_outlined),
                              onPressed: () async {
                                await docs[i].reference.update({'likes': FieldValue.increment(1)});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.alarm_add_outlined),
                              tooltip: '이 루틴으로 1분 뒤 정확 알람',
                              onPressed: () => _scheduleLocalIn1Min(context),
                            ),
                          ],
                        ),
                        onLongPress: () async {
                          await routines.doc(id).delete();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
