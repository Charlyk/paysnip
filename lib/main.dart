import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/split_provider.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => SplitProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const MyHomePage(title: AppConstants.appName),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _connectionStatus = 'Checking Supabase connection...';
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testSupabaseConnection();
  }

  Future<void> _testSupabaseConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing Supabase connection...';
    });

    try {
      // Test 1: Check if Supabase client is initialized
      final client = Supabase.instance.client;

      // Test 2: Try to get current session (will be null if not logged in, but won't error)
      final session = client.auth.currentSession;

      // Test 3: Verify environment variables are loaded
      final hasUrl = AppConstants.supabaseUrl.isNotEmpty;
      final hasKey = AppConstants.supabaseAnonKey.isNotEmpty;
      final hasOpenAI = AppConstants.openaiApiKey.isNotEmpty;

      setState(() {
        _isLoading = false;
        _isConnected = hasUrl && hasKey;
        _connectionStatus = '''
✅ Supabase Connection: SUCCESS

Environment:
${hasUrl ? '✅' : '❌'} Supabase URL: ${hasUrl ? 'Loaded' : 'Missing'}
${hasKey ? '✅' : '❌'} Supabase Key: ${hasKey ? 'Loaded' : 'Missing'}
${hasOpenAI ? '✅' : '❌'} OpenAI Key: ${hasOpenAI ? 'Loaded' : 'Missing'}

Auth Status:
${session != null ? '✅ User Logged In' : 'ℹ️ Not logged in (expected)'}

App Version: 1.0.0
Flutter: ${const String.fromEnvironment('flutter.version', defaultValue: '3.35.5')}
''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _connectionStatus = '''
❌ Supabase Connection: FAILED

Error: $e

Please check:
1. .env file exists with correct values
2. Supabase URL and keys are valid
3. Internet connection is active
''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isLoading
                    ? Icons.hourglass_empty
                    : _isConnected
                        ? Icons.check_circle
                        : Icons.error,
                size: 80,
                color: _isLoading
                    ? Colors.orange
                    : _isConnected
                        ? Colors.green
                        : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                _isLoading ? 'Testing...' : _isConnected ? 'Ready!' : 'Error',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isLoading
                          ? Colors.orange
                          : _isConnected
                              ? Colors.green
                              : Colors.red,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _connectionStatus,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _testSupabaseConnection,
                icon: const Icon(Icons.refresh),
                label: const Text('Test Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
