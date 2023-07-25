import 'package:appbancodesangue/historico_doacao.dart';
import 'package:appbancodesangue/sobre.dart';
import 'package:flutter/material.dart';
import 'package:appbancodesangue/guia_doacao_sangue.dart';
import 'package:appbancodesangue/registro_doacao.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      //print(e.toString());
      return null;
    }
  }

  bool isUserLoggedIn(){
    return _firebaseAuth.currentUser != null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco de Sangue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 221, 46, 33)),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () {
                  final email = _emailController.text;
                  final password = _passwordController.text;
                  _loginWithEmailAndPassword(context, email, password);
                },
                child: const Text('Login'))
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithEmailAndPassword(BuildContext context, String email, String password) async {
    final userCredential = await _authService.signInWithEmailAndPassword(email, password);
    if (userCredential != null) {
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // ignore: use_build_context_synchronously
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erro'),
              content: const Text('Falha ao fazer login. Verifique suas credenciais'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'))
              ],
            );
          });
    }
  }
}

class HomeScreen extends StatelessWidget {

  final AuthService _authService = AuthService();

  final List<String> _options = [
    'Notícias',
    'Registrar Doação de Sangue',
    'Guia de Doação',
    'Histórico',
    'Sobre'
  ];

  final List<IconData> icons = [
    Icons.article,
    Icons.favorite,
    Icons.fact_check_outlined,
    Icons.history,
    Icons.info
  ];

  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    if(!_authService.isUserLoggedIn()){
      return const LoginPage();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Doação de Sangue'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: _options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return GestureDetector(
            onTap: () {
              if(index == 4){
                Navigator.push(context, 
                MaterialPageRoute(builder: ((context) => SobreScreen()))
                );
              }
              if (index == 3){
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: ((context) => HistoricoDoacoes())
                  ));
              }
              if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuiaDoacaoScreen()),
                );
              }
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormularioDoacao()),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[index]),
                  const SizedBox(height: 8),
                  Text(option)
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
