import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'ui/screens/pin_entry_screen.dart';
import 'ui/providers/borsa_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://jvgewbtlvsznaxsqljmn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2Z2V3YnRsdnN6bmF4c3Fsam1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NzU2NzMsImV4cCI6MjA5NDM1MTY3M30.lsFGOI5qx3GBXweVpEDtiuRoVtMwRZ-I9mBV1m4qG9o',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BorsaProvider()),
      ],
      child: const BorsaTerminaliApp(),
    ),
  );
}

class BorsaTerminaliApp extends StatelessWidget {
  const BorsaTerminaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Borsa Terminali',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const PinEntryScreen(),
    );
  }
}
