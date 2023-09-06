import 'package:appbancodesangue/historico_doacao.dart';
import 'package:appbancodesangue/noticias.dart';
import 'package:appbancodesangue/questionario/questionario.dart';
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

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

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

  bool isUserLoggedIn() {
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
          seedColor: const Color.fromARGB(255, 221, 46, 33),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) {
              return const LoginPage();
            }
            return HomeScreen();
          }
          return const CircularProgressIndicator(); // Indicador de carregamento
        },
      ),
      debugShowCheckedModeBanner: false,
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
  late Color myColor;
  late Size mediaSize;
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool rememberUser = false;
  String _emailErrorMessage = "";
  String _passwordErrorMessage = "";
bool _isValidEmail(String email) {
  final emailRegExp =
      RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");
  _isEmailValid = emailRegExp.hasMatch(email);
  _emailErrorMessage = _isEmailValid ? "" : "Email inválido.";
  return _isEmailValid;
}
bool _isValidPassword(String password) {
  if (password.isEmpty) {
    _passwordErrorMessage = "A senha é obrigatória.";
    _isPasswordValid = false;
  } else if (password.length < 8) {
    _passwordErrorMessage = "A senha deve ter pelo menos 8 caracteres.";
    _isPasswordValid = false;
  } else {
    _passwordErrorMessage = "";
    _isPasswordValid = true;
  }
  return _isPasswordValid;
}
  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;
    mediaSize = MediaQuery.of(context).size;
     return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("lib/assets/img/doacao.jpeg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned(top: 10, child: _buildTop()),
          Positioned(bottom: 0, child: _buildBottom()),
        ]),
      ),
    );
  }

  Widget _buildTop() {
    return SizedBox(
      width: mediaSize.width,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.vaccines,
            size: 100,
            color: Colors.white,
          ),
          Text(
            "Banco de Sangue",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
                letterSpacing: 2),
          )
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      child: Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        )),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bem Vindo",
          style: TextStyle(
              color: Colors.black, fontSize: 32, fontWeight: FontWeight.w500),
        ),
        _buildGreyText("Por favor informe abaixo suas informações de login"),
        const SizedBox(height: 60),
        _buildGreyText("Email"),
        _buildInputField(_emailController, isEmail: true),
        Text(
          _emailErrorMessage,
          style: TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 40),
        _buildGreyText("Senha"),
        _buildInputField(_passwordController, isPassword: true),
        Text(
          _passwordErrorMessage,
          style: TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 20),
        _buildRememberForgot(),
        const SizedBox(height: 20),
        _buildLoginButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {isPassword = false, isEmail = false}) {
    return TextField(
      controller: controller,
      onChanged: (value) {
         if (isPassword) {
        setState(() {
          _passwordErrorMessage = _isValidPassword(value) ? "" : _passwordErrorMessage;
        });
        } else {
        setState(() {
          _emailErrorMessage = _isValidEmail(value) ? "" : "Email inválido.";
        });
        }
      },
      decoration: InputDecoration(
        suffixIcon: isPassword ? const Icon(Icons.remove_red_eye) : const Icon(Icons.done),
      ),
      obscureText: isPassword,
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
                value: rememberUser,
                onChanged: (value) {
                  setState(() {
                    rememberUser = value!;
                  });
                }),
            _buildGreyText("Relembre-me"),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () {
        final email = _emailController.text;
        final password = _passwordController.text;
        _loginWithEmailAndPassword(context, email, password);
      },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(60),
      ),
      child: const Text("LOGIN"),
    );
  }

  Future<void> _loginWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    final userCredential =
        await _authService.signInWithEmailAndPassword(email, password);
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
              content: const Text(
                  'Falha ao fazer login. Verifique suas credenciais'),
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
    'Sobre',
    'Questionário'
  ];

  final List<IconData> icons = [
    Icons.article,
    Icons.favorite,
    Icons.fact_check_outlined,
    Icons.history,
    Icons.info,
    Icons.question_mark_rounded
  ];

  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!_authService.isUserLoggedIn()) {
      return const LoginPage();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Doação de Sangue'),
         actions: [
    IconButton(
      icon: const Icon(Icons.exit_to_app),
      onPressed: () async {
        await _authService.signOut(); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
    ),
  ],
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
              if (index == 5) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QuestionarioScreen()));
              }
              if (index == 4) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) => const SobreScreen())));
              }
              if (index == 3) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) => HistoricoDoacoes())));
              }
              if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GuiaDoacaoScreen()),
                );
              }
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FormularioDoacao()),
                );
              }
              if (index == 0) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NoticiasScreen()));
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
