import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceProvider(),
      child: MaterialApp(
        title: 'FixYa App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoginPage(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    final url = Uri.parse('https://apifixya.onrender.com/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];

      if (token != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServicePage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicePage extends StatefulWidget {
  const ServicePage({Key? key}) : super(key: key);

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final ScrollController _controller = ScrollController();
  late ServiceProvider _serviceProvider;

  @override
  void initState() {
    super.initState();
    _serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent) {
        _serviceProvider.fetchServices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                _serviceProvider.filterServices(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search by description',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ServiceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.services.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  controller: _controller,
                  itemCount: provider.services.length + (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.services.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final service = provider.services[index];
                    return ListTile(
                      title: Text(service['description'] ?? 'No description'),
                      subtitle: Text('Price: \$${service['price'] ?? 0}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _services = [];
  bool isLoading = false;
  int _currentPage = 1;
  String _filter = '';

  List<Map<String, dynamic>> get services => _services
      .where((service) => service['description']
          .toLowerCase()
          .contains(_filter.toLowerCase()))
      .toList();

  Future<void> fetchServices() async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    final url = Uri.parse('https://apifixya.onrender.com/services?page=$_currentPage&size=10');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newServices = List<Map<String, dynamic>>.from(data['data']);
      _services.addAll(newServices);
      _currentPage++;
    }

    isLoading = false;
    notifyListeners();
  }

  void filterServices(String value) {
    _filter = value;
    notifyListeners();
  }
}
