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
import 'ui/ui_bundle.dart';

final FlutterLocalNotificationsPlugin localNoti = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ---- Local Notifications init ----
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await localNoti.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel','Reminders',
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
      title: 'Healthfluence',
      theme: ThemeData(useMaterial3: true),
      routes: {
        '/main': (_) => const MainNavigationScreen(),
        '/signup': (_) => const SignUpScreen(),
      },
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
        if (snap.data == null) return const SignInPage();

        return OnboardingGate(uid: snap.data!.uid);
      },
    );
  }
}

class OnboardingGate extends StatelessWidget {
  final String uid;
  const OnboardingGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (_, snap) {
     
        debugPrint('OnboardingGate: state=${snap.connectionState} hasData=${snap.hasData} hasError=${snap.hasError}');

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          debugPrint('OnboardingGate: snapshot error -> ${snap.error}');
          return const SignUpScreen();
        }

        final exists = snap.data?.exists ?? false;
        final data = snap.data?.data();
        final done = (data?['onboardingDone'] as bool?) ?? false;

        debugPrint('OnboardingGate resolved: uid=$uid exists=$exists done=$done');

        if (!exists || !done) return const SignUpScreen();
        return const MainNavigationScreen();
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
        email: email.text.trim(), password: pass.text.trim(),
      );
  
    } on FirebaseAuthException {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(), password: pass.text.trim(),
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
