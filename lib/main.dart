import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:audioplayers/audioplayers.dart';
import 'package:learning_app/api_service.dart';
import 'package:uuid/uuid.dart' show Uuid;
import 'dart:typed_data';
import 'pronunciation_analysis_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:learning_app/models/user_profile.dart';
import 'api_service.dart';
import 'package:learning_app/models/statistics_model.dart';


// 1. 데이터 모델 클래스 (수정 없음)
class WordData {
  final String word;
  final String pronunciation;
  final String definition;
  final String englishExample;
  bool isMemorized;
  bool isFavorite;

  WordData({
    required this.word,
    required this.pronunciation,
    required this.definition,
    required this.englishExample,
    this.isMemorized = false,
    this.isFavorite = false,
  });
}

// 2. 로컬 단어 목록 관리 클래스 (수정 없음)
class Dictionary {
  static final Set<String> _words = {};

  static Future<void> load() async {
    try {
      final fileContents = await rootBundle.loadString('assets/words_alpha.txt');
      final wordList = fileContents.split('\n');
      _words.addAll(wordList.map((word) => word.trim()).where((word) => word.isNotEmpty));
      print('기준 단어 목록 로딩 완료: 총 ${_words.length}개');
    } catch (e) {
      print('words_alpha.txt 파일 로딩 실패: $e');
    }
  }

  static bool contains(String word) {
    return _words.contains(word.toLowerCase());
  }
}

Route _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

// 3. API 호출 함수 (수정 없음)
Future<Map<String, dynamic>?> fetchWordData(String word) async {
  try {
    final translator = GoogleTranslator();
    Translation translation = await translator.translate(word, from: 'en', to: 'ko');
    String koreanMeaning = translation.text;

    final dictUrl = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
    final dictResponse = await http.get(dictUrl);

    Map<String, dynamic> result = {
      'word': word,
      'koreanMeaning': koreanMeaning,
    };

    if (dictResponse.statusCode == 200) {
      final dictData = json.decode(dictResponse.body) as List<dynamic>;
      final firstEntry = dictData.first;

      final phonetics = (firstEntry['phonetics'] as List?)?.firstWhere(
              (p) => p['text'] != null && p['text'].toString().isNotEmpty,
          orElse: () => null
      );
      result['pronunciation'] = phonetics?['text'] ?? '';

      final meanings = firstEntry['meanings'] as List?;
      String example = '';
      if (meanings != null) {
        for (var meaning in meanings) {
          final definitions = meaning['definitions'] as List?;
          if (definitions != null) {
            for (var definition in definitions) {
              if (definition['example'] != null) {
                example = definition['example'];
                break;
              }
            }
            if (example.isNotEmpty) break;
          }
        }
      }
      result['englishExample'] = example.isNotEmpty ? example : '예문을 찾을 수 없습니다';
    } else {
      result['pronunciation'] = '';
      result['englishExample'] = '예문을 찾을 수 없습니다';
    }
    return result;
  } catch (e) {
    print('### 번역 또는 API 호출 중 예외 발생: $e');
    return null;
  }
}

class CharacterAnimationScreen extends StatefulWidget {
  final String imagePath;
  const CharacterAnimationScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _CharacterAnimationScreenState createState() => _CharacterAnimationScreenState();
}

class _CharacterAnimationScreenState extends State<CharacterAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.1, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
              (route) => false,
        );
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색은 Theme에서 관리하므로 직접 지정하지 않습니다.
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            widget.imagePath,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('userSettings');

  await Dictionary.load();
  runApp(MyApp());
}

class AppState {
  static String selectedCharacterImage = 'assets/fox.png';
  static String selectedCharacterName = '여우';
  static String selectedLanguage = '영어';
  static final List<WordData> favoriteWords = [];

  static String? userName;
  static String? userLevel;
  static String? userEmail;
  static String? userId;
  static Map<String, dynamic>? learningGoals;

  static void updateFromProfile(Map<String, dynamic> profileData) {
    userName = profileData['name'];
    userLevel = profileData['assessed_level'];
    userEmail = profileData['email'];
    userId = profileData['user_id'];
    learningGoals = profileData['learning_goals'] as Map<String, dynamic>?;
  }

  static Map<String, dynamic> firstLesson = {}; // 추천 첫 학습
  static List<String> dailyGoals = []; // 오늘의 목표
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1));

    final bool autoLoginEnabled = await _apiService.getAutoLoginPreference();
    print("✅ [앱 시작] 저장된 '자동 로그인' 설정: $autoLoginEnabled");

    if (!autoLoginEnabled) {
      // 1. 자동 로그인이 꺼져있으면 바로 초기 화면으로
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => InitialScreen()));
      return;
    }

    // 2. 자동 로그인이 켜져있으면, 백엔드에 "자동 로그인 가능한가요?" 라고 직접 물어봅니다.
    final response = await _apiService.attemptAutoLogin();

    if (response['status'] == 'ok' && mounted) {
      // 3. 백엔드가 'ok' 사인을 보내면, 홈 화면으로 이동합니다.
      //    이때 백엔드가 보내준 최신 프로필 정보로 AppState를 업데이트합니다.
      AppState.updateFromProfile(response['user_profile']);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      // 4. 백엔드가 'ok' 사인을 보내지 않으면 (토큰 만료 등), 로그아웃 처리 후 초기 화면으로 이동합니다.
      await _apiService.logout();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => InitialScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // =======================================================
    // ▼▼▼ [수정] 앱 전체의 테마를 교체합니다. ▼▼▼
    // =======================================================
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learning App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F4F8),
        fontFamily: 'Pretendard',
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F4F8),
          foregroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 1.5)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        checkboxTheme: CheckboxThemeData(fillColor: MaterialStateProperty.all(Colors.green)),
        tabBarTheme: const TabBarThemeData(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green
        ),
      ),
      home: InitialScreen(),
    );
  }
}

// 초기 화면
class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2),
              Image.asset(
                'assets/all.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 100,
                      color: Colors.green,
                    ),
                  );
                },
              ),
              SizedBox(height: 60),
              Text(
                '다국어 언어 학습',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '다국어 능력 향상을 위한 앱',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  child: Text('회원가입'), // 스타일은 Theme에서 자동으로 적용됨
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton( // 로그인 버튼은 OutlinedButton으로 변경하여 구분
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// 회원가입 화면
class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  bool _agreeToMarketing = false;
  bool _agreeToAge = false;
  final ApiService _apiService = ApiService();
  // 👈 1. 로딩 상태를 관리할 변수 추가
  bool _isLoading = false;

  // 👈 2. 회원가입 버튼을 눌렀을 때 호출될 함수
  Future<void> _handleRegister() async {
    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    // --- 입력값 검증 ---
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      _showErrorSnackBar('필수 항목(*)을 모두 입력해주세요.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!_agreeToTerms || !_agreeToPrivacy || !_agreeToAge) {
      _showErrorSnackBar('필수 약관에 동의해주세요.');
      return;
    }

    // 로딩 시작
    setState(() => _isLoading = true);

    try {
      // API 서비스 호출
      final response = await _apiService.register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );

      // 2단계: 프로필 생성 API 호출 (회원가입 시에만 호출되어야 함)
      if (response['access_token'] != null) {
        await _apiService.createProfile();
      }

      if (mounted) {
        // 👇 [수정] confirmation_required 값에 따라 분기 처리합니다.
        final bool confirmationRequired = response['confirmation_required'] ?? false;

        if (confirmationRequired) {
          // 1. 이메일 인증이 필요한 경우
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가입 확인 이메일이 전송되었습니다. 메일함을 확인해주세요.'),
              duration: Duration(seconds: 3), // 메시지를 좀 더 길게 표시
            ),
          );
          // 로그인 화면 대신 이전 화면(초기 화면)으로 돌아갑니다.
          Navigator.pop(context);

        } else {
          // 2. 이메일 인증이 필요 없는 경우 (기존 로직)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입에 성공했습니다! 로그인 페이지로 이동합니다.')),
          );
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          });
        }
      }
    } catch (e) {
      if (e is ApiException) {
        _showErrorSnackBar(e.message);
      } else {
        _showErrorSnackBar('알 수 없는 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 에러 메시지를 보여주는 헬퍼 함수
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(label: '이메일 *', controller: _emailController, hint: '예) abc@gmail.com'),
              const SizedBox(height: 16),
              _buildPasswordField(label: '비밀번호 *', controller: _passwordController, isObscured: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
              const SizedBox(height: 16),
              _buildPasswordField(label: '비밀번호 확인 *', controller: _confirmPasswordController, isObscured: _obscureConfirmPassword,
                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
              const SizedBox(height: 16),
              _buildTextField(label: '이름 *', controller: _nameController, hint: '예) 홍길동'),
              const SizedBox(height: 24),
              _buildCheckboxRow('약관 약관에 모두 동의합니다.', _agreeToTerms, (value) => setState(() => _agreeToTerms = value!)),
              _buildCheckboxRow('이용약관 및 정보 동의 자세히보기', _agreeToPrivacy, (value) => setState(() => _agreeToPrivacy = value!)),
              _buildCheckboxRow('개인정보 처리방침 및 수집 동의 자세히보기', _agreeToMarketing, (value) => setState(() => _agreeToMarketing = value!)),
              _buildCheckboxRow('만 14세 이상입니다 방침 동의', _agreeToAge, (value) => setState(() => _agreeToAge = value!)),
              const SizedBox(height: 40),
              // 👈 3. ElevatedButton 수정: 로딩 상태 표시 및 onPressed 연결
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- (이하 _build... 헬퍼 위젯들은 기존과 동일) ---
  Widget _buildTextField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool isObscured, required VoidCallback onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscured,
          decoration: InputDecoration(
            hintText: '영문, 숫자 조합 8~16자',
            suffixIcon: IconButton(
              icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(String text, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// 로그인 화면
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;
  final ApiService _apiService = ApiService();
  // 👈 1. 로딩 상태를 관리할 변수 추가
  bool _isLoading = false;
  bool _autoLogin = false;

  // 👈 2. 로그인 버튼을 눌렀을 때 호출될 함수
  Future<void> _handleLogin() async {
    print("--- _handleLogin 함수 시작됨! ---");
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("✅ [로그인] '자동 로그인' 설정을 저장합니다: $_autoLogin");
      await _apiService.saveAutoLoginPreference(_autoLogin);

      // 1단계: 회원가입 API 호출 (이제 토큰을 반환함)
      final response = await _apiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        if (response['access_token'] != null) {
          final String? assessedLevel = response['assessed_level'];

          if (assessedLevel != null && assessedLevel.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LevelTestScreen(userId: _emailController.text)),
            );
          }
        } else {
          _showErrorSnackBar(response['detail'] ?? '로그인에 실패했습니다.');
        }
      }
    } catch (e) {
      if (e is ApiException) {
        _showErrorSnackBar(e.message);
      } else {
        _showErrorSnackBar('알 수 없는 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 에러 메시지를 보여주는 헬퍼 함수
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // 👇 [수정] Spacer를 SizedBox로 변경하여 고정된 공간을 줍니다.
              const SizedBox(height: 50.0),

              const Text('로그인', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일')),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              // 👇 [추가] 자동 로그인 체크박스 UI
              CheckboxListTile(
                title: const Text('자동 로그인'),
                value: _autoLogin,
                onChanged: (bool? value) {
                  setState(() {
                    _autoLogin = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // 체크박스를 텍스트 왼쪽에 표시
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('로그인'),
              ),
              const SizedBox(height: 100.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class TestQuestion {
  final String id;
  final String text;
  final List<String> options;

  TestQuestion({required this.id, required this.text, required this.options});

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    // 서버에서 받은 options(Map)의 value들만 추출하여 List<String>으로 변환합니다.
    final optionsMap = Map<String, dynamic>.from(json['options'] ?? {});
    final optionsList = optionsMap.values.map((e) => e.toString()).toList();

    return TestQuestion(
      id: json['question_id'] ?? '',
      // 서버 응답에 맞춰 키 이름을 'question'으로 사용합니다.
      text: json['question'] ?? '질문을 불러올 수 없습니다.',
      options: optionsList,
    );
  }
}

// 2. API 통신 서비스 클래스
class LevelTestApiService {
  // ❗️ 중요: FastAPI 서버가 실행 중인 IP 주소로 변경하세요!
  // 예: final String _baseUrl = 'http://192.168.0.5:8000';
  final String _baseUrl = const String.fromEnvironment(
      'AI_BACKEND_URL',
      defaultValue: 'http://10.0.2.2:8000'
  ); // 로컬 테스트용 주소

  // 테스트 시작 API 호출
  Future<Map<String, dynamic>> startTest(String userId, String language) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/level-test/start'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'language': language}),
    );

    if (response.statusCode == 200) {
      // 👇 [디버깅 코드] 서버가 보낸 실제 응답 내용을 확인하기 위해 이 줄을 추가하세요.
      print('서버 응답: ${utf8.decode(response.bodyBytes)}');
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('레벨 테스트를 시작하지 못했습니다.');
    }
  }

  // 답변 제출 API 호출
  Future<Map<String, dynamic>> submitAnswer(String sessionId, String questionId, String answer) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/level-test/answer'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'session_id': sessionId,
        'question_id': questionId,
        'answer': answer,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('답변을 제출하지 못했습니다.');
    }
  }

  // 최종 결과 요청 API 호출
  Future<Map<String, dynamic>> completeAssessment(String userId, String sessionId) async {
    // 👇 [수정됨] user_id와 session_id를 URL에 직접 포함시킵니다.
    final url = Uri.parse('$_baseUrl/api/user/complete-assessment?user_id=$userId&session_id=$sessionId');

    // 디버깅을 위해 추가한 print문
    print('>>> [LevelTestApiService] 서버로 보내는 최종 URL: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      // 👇 [수정됨] body 부분을 삭제하거나 주석 처리합니다.
      // body: json.encode({ ... }),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      print('### 평가 완료 오류: ${response.statusCode} - ${response.body}');
      throw Exception('결과를 불러오지 못했습니다.');
    }
  }
}

// 3. 동적으로 변경된 레벨 테스트 화면
class LevelTestScreen extends StatefulWidget {
  final String userId;
  const LevelTestScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _LevelTestScreenState createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends State<LevelTestScreen> {
  final LevelTestApiService _apiService = LevelTestApiService();
  bool _isLoading = true;
  String? _sessionId;
  TestQuestion? _currentQuestion;
  int _questionNumber = 0;
  int _totalQuestions = 0;
  String? _selectedAnswer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  Future<void> _startTest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.startTest(widget.userId, AppState.selectedLanguage);
      print('서버 응답: ${response.toString()}');

      if (response['success'] == true && response['data'] != null) {
        // 👇 'data'를 한 번만 참조하도록 수정합니다.
        final responseData = response['data'];

        final sessionId = responseData['session_id'];
        final currentQuestion = TestQuestion.fromJson(responseData['current_question']);
        final totalQuestions = int.tryParse(responseData['total_questions'].toString().split('-').first) ?? 15;

        setState(() {
          _sessionId = sessionId;
          _currentQuestion = currentQuestion;
          _questionNumber = 1;
          _totalQuestions = totalQuestions;
          _isLoading = false;
        });

      } else {
        setState(() {
          _errorMessage = response['error']?.toString() ?? '알 수 없는 서버 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('### _startTest 오류: $e');
      print('### 스택 트레이스: $stackTrace'); // 더 자세한 오류 확인을 위해 추가
      setState(() {
        _errorMessage = '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAndNext() async {
    if (_selectedAnswer == null || _sessionId == null || _currentQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답을 선택해주세요!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.submitAnswer(
        _sessionId!,
        _currentQuestion!.id,
        _selectedAnswer!,
      );

      if (response['success'] == true) {
        final responseData = response['data']; // 👈 data를 한 번만 참조합니다.

        // 👇 'status' 키를 확인하여 테스트 완료 여부를 판단합니다.
        if (responseData['status'] == 'completed') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LevelTestResultScreen(
                userId: widget.userId,
                sessionId: _sessionId!,
              ),
            ),
          );
        } else {
          // 다음 문제 표시
          setState(() {
            _currentQuestion = TestQuestion.fromJson(responseData['next_question']);
            _questionNumber++;
            _selectedAnswer = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['error'] ?? '답변 처리 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("### _submitAndNext 오류: $e");
      setState(() {
        _errorMessage = '서버와 통신 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레벨 테스트')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text('오류 발생', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    if (_currentQuestion == null) {
      return const Center(child: Text('문제를 불러오지 못했습니다.'));
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text('$_questionNumber / $_totalQuestions',
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ),
        const SizedBox(height: 40),
        Text('다음 질문에 알맞은\n답을 고르세요',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Text(_currentQuestion!.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Expanded(
          child: ListView.builder(
            // 👇 optionsList 대신 다시 options를 사용
            itemCount: _currentQuestion!.options.length,
            itemBuilder: (context, index) {
              final option = _currentQuestion!.options[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<String>(
                  title: Text(option, style: const TextStyle(fontSize: 16)),
                  value: option,
                  groupValue: _selectedAnswer,
                  onChanged: (value) => setState(() => _selectedAnswer = value),
                  activeColor: Colors.green,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitAndNext,
          child: Text(_questionNumber == _totalQuestions ? '결과 보기' : '다음'),
        ),
      ],
    );
  }
}

// =======================================================
// ▼▼▼ [추가] 아래 LevelTestResultScreen 클래스를 새로 추가합니다. ▼▼▼
// =======================================================
class LevelTestResultScreen extends StatefulWidget {
  final String userId;
  final String sessionId;

  const LevelTestResultScreen({
    Key? key,
    required this.userId,
    required this.sessionId,
  }) : super(key: key);

  @override
  _LevelTestResultScreenState createState() => _LevelTestResultScreenState();
}

class _LevelTestResultScreenState extends State<LevelTestResultScreen> {
  // 👈 1. ApiService 인스턴스를 가져옵니다.
  final ApiService _apiService = ApiService();
  final LevelTestApiService _levelTestApiService = LevelTestApiService(); // 기존 서비스도 유지

  bool _isLoading = true;
  Map<String, dynamic>? _resultData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAndSaveResults(); // 👈 2. 결과를 가져오고 저장하는 함수를 호출하도록 변경
  }

  // 👈 3. 결과를 가져온 후, DB에 저장하는 로직을 통합한 새 함수
  Future<void> _fetchAndSaveResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. AI_WAWA 서버에서 레벨 테스트 결과 가져오기
      final response = await _levelTestApiService.completeAssessment(widget.userId, widget.sessionId);
      print('### 결과 API 응답: ${response.toString()}');

      if (response['success'] == true && response['data'] != null) {
        final responseData = response['data'];
        final userProfile = responseData['user_profile'] ?? {};
        final assessedLevel = userProfile['assessed_level'];

        // 2. BackEnd_WAWA 서버로 결과 전송하여 DB에 저장
        //    실제 user_id는 Supabase의 UUID를 사용해야 하지만, 현재 구조상 email을 user_id로 사용합니다.
        if (assessedLevel != null) {
          // ❗️ 이 부분에 /auth/update-level API를 호출하는 로직이 필요합니다.
          // ❗️ ApiService에 해당 함수를 추가해야 합니다. (아래 4단계 참고)
          await _apiService.updateUserLevel(
            userId: widget.userId, // 로그인 시 사용한 ID (현재는 이메일)
            assessedLevel: assessedLevel,
          );
        }

        setState(() {
          _resultData = responseData;
        });

      } else {
        _handleError(response['error']?.toString() ?? '결과를 불러오는 데 실패했습니다.');
      }
    } catch (e) {
      _handleError('서버에 연결할 수 없습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 에러 처리 헬퍼 함수
  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (build 메서드는 기존과 동일)
    return Scaffold(
      appBar: AppBar(title: const Text('테스트 결과'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_resultData == null) {
      return const Center(child: Text('결과 데이터가 없습니다.'));
    }

    final userProfile = _resultData!['user_profile'] ?? {};
    final level = userProfile['assessed_level'] ?? 'N/A';
    final strengths = List<String>.from(userProfile['strengths'] ?? []);
    final weaknesses = List<String>.from(userProfile['areas_to_improve'] ?? []);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 80),
        const SizedBox(height: 20),
        Text('테스트 완료!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('당신의 언어 레벨은...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            level,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800),
          ),
        ),
        const SizedBox(height: 24),
        if (strengths.isNotEmpty) ...[
          Text('👍 강점: ${strengths.join(', ')}'),
          const SizedBox(height: 8),
        ],
        if (weaknesses.isNotEmpty) ...[
          Text('💪 개선점: ${weaknesses.join(', ')}'),
        ],
        const Spacer(flex: 3),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          },
          child: const Text('학습 시작하러 가기'),
        ),
        const Spacer(),
      ],
    );
  }
}

// 캐릭터 선택 화면
class CharacterSelectionScreen extends StatefulWidget {
  @override
  _CharacterSelectionScreenState createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  String? selectedCharacter;

  final List<Map<String, dynamic>> characters = [
    {'name': '여우', 'image': 'assets/fox.png'},
    {'name': '고양이', 'image': 'assets/cat.png'},
    {'name': '부엉이', 'image': 'assets/owl.png'},
    {'name': '곰', 'image': 'assets/bear.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('캐릭터 선택')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 40),
              Text(
                '마지막으로 공부를\n함께 하고싶은 캐릭터를\n선택하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('(추후에 변경 가능합니다)', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              SizedBox(height: 60),
              Expanded(
                child: ListView.builder(
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.all(12),
                        title: Row(
                          children: [
                            Image.asset(character['image'], width: 50, height: 50, errorBuilder: (c, e, s) => Icon(Icons.pets, size: 40)),
                            SizedBox(width: 20),
                            Text(character['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        value: character['name'],
                        groupValue: selectedCharacter,
                        onChanged: (value) {
                          setState(() {
                            selectedCharacter = value;
                            final selectedData = characters.firstWhere((c) => c['name'] == value);
                            AppState.selectedCharacterImage = selectedData['image'];
                            AppState.selectedCharacterName = selectedData['name'];
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (AppState.selectedCharacterImage.isNotEmpty) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, a, b) => CharacterAnimationScreen(imagePath: AppState.selectedCharacterImage),
                        transitionsBuilder: (context, a, b, child) => child,
                      ),
                          (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('함께 공부할 캐릭터를 선택해주세요!')),
                    );
                  }
                },
                child: Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 메인 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  late TabController _communityTabController;
  final List<String> _communityTabs = ['자유게시판', '질문게시판', '정보공유', '스터디모집'];
  static const List<String> _titles = ['Learning', '단어장', '학습', '상황별 회화', '커뮤니티'];

  // ▼▼▼ [수정] Future를 직접 관리하여 중복 호출을 방지합니다. ▼▼▼
  Future<void>? _homeScreenDataFuture;

  @override
  void initState() {
    super.initState();
    _communityTabController = TabController(length: _communityTabs.length, vsync: this);
    // ▼▼▼ [수정] initState에서 Future를 딱 한 번만 실행시킵니다. ▼▼▼
    _homeScreenDataFuture = _loadHomeScreenData();
  }

  Future<void> _loadHomeScreenData() async {
    try {
      final profileData = await _apiService.getUserProfile();

      if (mounted) {
        // AppState 업데이트는 setState 밖에서 처리
        AppState.userName = profileData['name'];
        AppState.userLevel = profileData['assessed_level'];
        AppState.userEmail = profileData['email'];
        AppState.userId = profileData['user_id'];
        AppState.learningGoals = profileData['learning_goals'] as Map<String, dynamic>?;

        // 화면 갱신을 위해 setState 호출
        setState(() {});
      }
    } catch (e) {
      print("홈 화면 데이터 로딩 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateStateWithProfileData(Map<String, dynamic> profileData) {
    print("✅ [3단계] _updateStateWithProfileData 함수 호출됨!");
    if (mounted) {
      print("  ➡️ 변경 전 AppState.learningGoals: ${AppState.learningGoals}");
      setState(() {
        AppState.userName = profileData['name'];
        AppState.userLevel = profileData['assessed_level'];
        AppState.userEmail = profileData['email'];
        AppState.userId = profileData['user_id'];
        AppState.learningGoals = profileData['learning_goals'] as Map<String, dynamic>?;
      });
      print("  ➡️ 변경 후 AppState.learningGoals: ${AppState.learningGoals}");
    }
  }

  // ▼▼▼ [수정] 새로고침 함수는 Future를 새로 할당하고 setState를 호출합니다. ▼▼▼
  void refreshHomeScreen() {
    setState(() {
      _homeScreenDataFuture = _loadHomeScreenData();
    });
  }

  // (didChangeDependencies 함수는 완전히 삭제합니다.)

  @override
  void dispose() {
    _communityTabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == 4 && index != 4) {
      _communityTabController.animateTo(0);
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ [수정] FutureBuilder를 사용하여 데이터 로딩 상태를 명확하게 관리합니다. ▼▼▼
    return FutureBuilder(
      future: _homeScreenDataFuture,
      builder: (context, snapshot) {
        // 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 에러 발생 시 (네트워크 등)
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('오류가 발생했습니다: ${snapshot.error}')));
        }

        // 로딩 완료 후
        final List<Widget> _pages = <Widget>[
          HomePageContent(onNavigate: refreshHomeScreen),
          VocabularyScreen(),
          StudyScreen(),
          SituationScreen(),
          CommunityScreen(tabController: _communityTabController),
        ];

        return Scaffold(
          drawer: MyInfoDrawer(onRefresh: refreshHomeScreen),
          appBar: AppBar(
            leading: Builder(
              builder: (innerContext) {
                return IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: '내 정보 보기',
                  onPressed: () {
                    Scaffold.of(innerContext).openDrawer();
                  },
                );
              },
            ),
            title: Text(_titles[_selectedIndex]),
            bottom: _selectedIndex == 4
                ? TabBar(
              controller: _communityTabController,
              tabs: _communityTabs.map((String title) => Tab(text: title)).toList(),
            )
                : null,
            actions: [
              if (_selectedIndex == 0) ...[
                IconButton(icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber), onPressed: () {}),
                const Center(child: Text('0', style: TextStyle(fontSize: 16))),
                IconButton(icon: const Icon(Icons.star_border, color: Colors.blueAccent), onPressed: () {}),
                const Center(child: Text('0', style: TextStyle(fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black54),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                  },
                ),
                const SizedBox(width: 8),
              ]
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: '단어장'),
              BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: '학습'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '상황별 회화'),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: '커뮤니티'),
            ],
          ),
        );
      },
    );
  }
}

class HomePageContent extends StatefulWidget {
  final VoidCallback onNavigate;
  const HomePageContent({super.key, required this.onNavigate});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print("✅ [5단계] HomePageContent UI 다시 빌드됨! 현재 goals: ${AppState.learningGoals}");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProfileSection(),
          const SizedBox(height: 20),
          _buildTodayLearningButton(),
          const SizedBox(height: 20),
          _buildVocabularyTestSection(),
          const SizedBox(height: 20),
          _buildVocabularyAnalysisSection(),
          const SizedBox(height: 20),
          _buildAttendanceCheckSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final userName = AppState.userName;
    final userLevel = AppState.userLevel;
    final goals = AppState.learningGoals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(userName ?? AppState.selectedCharacterName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Image.asset(AppState.selectedCharacterImage, width: 100, height: 100, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 100)),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontFamily: 'Pretendard'),
                          children: <TextSpan>[
                            const TextSpan(text: '학습 언어: '),
                            TextSpan(
                              text: AppState.selectedLanguage,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (userLevel != null)
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontFamily: 'Pretendard'),
                            children: <TextSpan>[
                              const TextSpan(text: '레벨: '),
                              TextSpan(
                                text: userLevel,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: goals != null && goals.isNotEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("오늘의 목표", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if ((goals['conversation_goal'] ?? 0) > 0)
                    _buildGoalIndicator(
                      icon: Icons.chat_bubble_outline,
                      color: Colors.orange,
                      title: '회화',
                      progress: 0,
                      goal: goals['conversation_goal'] ?? 0,
                      unit: '분',
                    ),

                  // 👇 [수정] 0보다 클 때만 보이도록 if문 추가
                  if ((goals['grammar_goal'] ?? 0) > 0)
                    const SizedBox(height: 12),
                  if ((goals['grammar_goal'] ?? 0) > 0)
                    _buildGoalIndicator(
                      icon: Icons.menu_book_outlined,
                      color: Colors.blue,
                      title: '문법',
                      progress: 0,
                      goal: goals['grammar_goal'] ?? 0,
                      unit: '회',
                    ),

                  // 👇 [수정] 0보다 클 때만 보이도록 if문 추가
                  if ((goals['pronunciation_goal'] ?? 0) > 0)
                    const SizedBox(height: 12),
                  if ((goals['pronunciation_goal'] ?? 0) > 0)
                    _buildGoalIndicator(
                      icon: Icons.mic_none,
                      color: Colors.green,
                      title: '발음',
                      progress: 0,
                      goal: goals['pronunciation_goal'] ?? 0,
                      unit: '회',
                    ),
                ],
              )
                  : Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GoalSettingScreen())
                    ).then((newProfile) {
                      print("✅ [1단계] GoalSettingScreen에서 newProfile 받음: $newProfile");
                      // 👇 [수정] 이 부분을 변경합니다.
                      if (newProfile != null && newProfile is Map<String, dynamic>) {
                        // 부모 위젯(HomeScreen)의 상태 업데이트 함수를 직접 호출합니다.
                        // 이렇게 하면 불필요한 API 호출 없이 즉시 UI가 바뀝니다.
                        final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                        print("✅ [2단계] HomeScreenState 찾음: ${homeScreenState != null}");
                        homeScreenState?._updateStateWithProfileData(newProfile);
                      }
                      // widget.onNavigate(); // <-- 기존의 불필요한 호출은 삭제합니다.
                    });
                  },
                  child: const Column( // 기존 목표 설정 유도 UI
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_outlined, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text(
                        '학습 목표를 설정하고\n나만의 계획을 시작해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLearningButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecommendedStudyScreen()),
        );
      },
      icon: const Icon(Icons.book),
      label: const Text('오늘의 학습', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildVocabularyTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.bar_chart, color: Colors.green, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('나의 영어 어휘력은 어느 정도일까?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('새로운 단어 3문제 더 풀고 알아보러 가기', style: TextStyle(color: Colors.grey))
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyAnalysisSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('어휘 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: const [
                    CircleAvatar(radius: 5, backgroundColor: Colors.blueAccent),
                    SizedBox(width: 4),
                    Text('복습 정답률', style: TextStyle(color: Colors.grey)),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('새로 배운 단어: 0', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('이미 아는 단어: 0', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('복습 단어: 0', style: TextStyle(color: Colors.grey))
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 60,
                  width: 20,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(color: Colors.grey.shade300),
                      Container(height: 50, color: Colors.lightBlueAccent)
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  children: const [
                    Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('%', style: TextStyle(color: Colors.grey))
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCheckSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(_createSlideRoute(const AttendancePage())),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('출석 체크', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildDayCircle('월'),
              _buildDayCircle('화', isChecked: true),
              _buildDayCircle('수'),
              _buildDayCircle('목'),
              _buildDayCircle('금'),
              _buildDayCircle('토'),
              _buildDayCircle('일'),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCircle(String day, {bool isChecked = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isChecked ? Colors.lightBlueAccent : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isChecked
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(day, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildGoalIndicator({
    required IconData icon,
    required Color color,
    required String title,
    required int progress,
    required int goal,
    required String unit,
  }) {
    final double progressPercent = goal > 0 ? progress / goal : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              '$progress / $goal $unit',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progressPercent,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
      ],
    );
  }
}

class MyInfoDrawer extends StatelessWidget {
  final VoidCallback onRefresh;

  const MyInfoDrawer({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final String characterImage = AppState.selectedCharacterImage;
    final String? displayName = AppState.userName;
    final String? displayEmail = AppState.userEmail;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(displayName ?? AppState.selectedCharacterName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(displayEmail ?? '이메일 정보 없음'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage(characterImage),
              backgroundColor: Colors.white,
            ),
            decoration: BoxDecoration(color: Colors.green.shade700),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필 관리'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('나의 학습 통계'),
            onTap: () {
              Navigator.pop(context);
              // 👇 [수정] StatisticsScreen으로 이동하는 코드를 추가합니다.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('학습 목표 설정'),
            onTap: () {
              final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
              ).then((newProfile) {
                if (newProfile != null && newProfile is Map<String, dynamic>) {
                  homeScreenState?._updateStateWithProfileData(newProfile);
                }
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              await ApiService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => InitialScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ApiService _apiService = ApiService();
  late Future<StatisticsResponse> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _apiService.getStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 학습 통계'),
      ),
      body: FutureBuilder<StatisticsResponse>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildOverallStatsCard(stats.overallStats),
              const SizedBox(height: 20),
              if (stats.progressStats != null)
                _buildProgressStatsCard(stats.progressStats!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallStatsCard(OverallStats overall) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 누적 학습량', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.orange),
              title: const Text('총 회화 학습'),
              trailing: Text('${overall.totalConversationDuration} 분', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: Colors.blue),
              title: const Text('총 문법 연습'),
              trailing: Text('${overall.totalGrammarCount} 회', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none, color: Colors.green),
              title: const Text('총 발음 연습'),
              trailing: Text('${overall.totalPronunciationCount} 회', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatsCard(ProgressStats progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 목표 달성률', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildProgressIndicator('회화', progress.conversationProgress, Colors.orange),
            const SizedBox(height: 16),
            _buildProgressIndicator('문법', progress.grammarProgress, Colors.blue),
            const SizedBox(height: 16),
            _buildProgressIndicator('발음', progress.pronunciationProgress, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String title, double value, Color color) {
    final percentage = value.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text('${percentage.toStringAsFixed(1)} %', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 10,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userName = AppState.userName;
    final String? userEmail = AppState.userEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 관리')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(context, name: userName, email: userEmail),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  // 👈 3. _buildProfileHeader 위젯이 이름과 이메일을 파라미터로 받도록 수정합니다.
  Widget _buildProfileHeader(BuildContext context, {String? name, String? email}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(AppState.selectedCharacterImage),
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 16),
        Text(
          // 전달받은 이름이 있으면 표시하고, 없으면 '사용자'로 표시
          name ?? '사용자',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          // 전달받은 이메일이 있으면 표시하고, 없으면 안내 문구 표시
          email ?? '이메일 정보 없음',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // _buildInfoCard 위젯은 이미 AppState를 사용하고 있으므로 수정할 필요가 없습니다.
  Widget _buildInfoCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('나의 레벨'),
            trailing: Text(AppState.userLevel ?? '테스트 미완료', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('학습 언어'),
            trailing: Text(AppState.selectedLanguage, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // _buildDangerZone 위젯은 수정할 필요가 없습니다.
  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.shade50,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.password, color: Colors.red.shade700),
            title: Text('비밀번호 변경', style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              // TODO: 비밀번호 변경 로직
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
            title: Text('회원 탈퇴', style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              // TODO: 회원 탈퇴 로직
            },
          ),
        ],
      ),
    );
  }
}

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출석 체크')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_available, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text('출석 체크 페이지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('이곳에 달력이나 출석 관련 기능을 구현할 수 있습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ▼▼▼ [추가] 오늘의 학습 추천 화면 ▼▼▼
class RecommendedStudyScreen extends StatelessWidget {
  const RecommendedStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AppState에서 추천 학습 데이터 가져오기
    final firstLesson = AppState.firstLesson;
    final dailyGoals = AppState.dailyGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 추천 학습'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 첫 수업 추천 카드
          if (firstLesson.isNotEmpty) ...[
            Text('🚀 바로 시작해보세요!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.play_circle_fill, color: Colors.green, size: 40),
                title: Text(firstLesson['title'] ?? '추천 학습'),
                subtitle: Text(firstLesson['preview'] ?? '흥미로운 첫 학습을 시작해보세요.'),
                onTap: () {
                  // TODO: 실제 학습 콘텐츠 화면으로 연결
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${firstLesson['title']} 학습을 시작합니다!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 일일 목표 목록
          if (dailyGoals.isNotEmpty) ...[
            Text('🎯 오늘의 목표', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (var goal in dailyGoals)
              Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text("✔️  $goal", style: const TextStyle(fontSize: 16)),
                ),
              ),
          ] else
          // 추천 데이터가 없을 경우
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('추천 학습을 보려면\n먼저 레벨 테스트를 완료해주세요!', textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}

// 단어장 메인 화면
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  _VocabularyScreenState createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Map<String, dynamic>> _myWordbooks = [
    {'name': '기본 단어장', 'words': <WordData>[]}
  ];
  bool _isLoading = false;
  String _loadingMessage = '';
  final _searchController = TextEditingController();
  List<WordData> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _performSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }
    List<WordData> results = [];
    for (var wordbook in _myWordbooks) {
      for (var wordData in (wordbook['words'] as List<WordData>)) {
        if (wordData.word.toLowerCase().contains(query.toLowerCase())) {
          results.add(wordData);
        }
      }
    }
    setState(() {
      _searchResults = results;
    });
  }

  final Map<String, String> _pickWordbooks = {'#토익/토플': 'assets/TOEIC:TOEFL.txt'};

  Future<void> _createWordbookFromFile(String wordbookName, String assetPath) async {
    if (_myWordbooks.any((wb) => wb['name'] == wordbookName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("'$wordbookName' 단어장은 이미 존재합니다.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = '단어장을 생성하는 중...';
    });

    try {
      final String fileContents = await rootBundle.loadString(assetPath);
      final List<String> lines = fileContents.split('\n').where((line) => line.trim().isNotEmpty).toList();
      final List<WordData> newWords = [];

      for (final line in lines) {
        final match = RegExp(r'(.+?)\s*\((.+)\)').firstMatch(line);

        if (match != null && match.groupCount == 2) {
          final String englishWord = match.group(1)!.trim();
          final String koreanMeaning = match.group(2)!.trim();

          newWords.add(WordData(
            word: englishWord,
            definition: koreanMeaning,
            pronunciation: '',
            englishExample: '',
          ));
        }
      }

      setState(() {
        _myWordbooks.add({'name': wordbookName, 'words': newWords});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("'$wordbookName' 단어장 생성이 완료되었습니다!")),
      );

    } catch (e) {
      print('파일 처리 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("단어장 생성 중 오류가 발생했습니다.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  void _navigateToDetail(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordbookDetailScreen(wordbook: _myWordbooks[index]),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  Future<void> _showCreateWordbookDialog() async {
    final TextEditingController nameController = TextEditingController();

    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 단어장 생성'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(hintText: '단어장 이름을 입력하세요'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('생성'),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(nameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _myWordbooks.add({'name': newName, 'words': <WordData>[]});
      });
    }
  }

  Future<void> _showDeleteWordbookConfirmDialog(int index) async {
    final wordbookToDelete = _myWordbooks[index];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('단어장 삭제'),
          content: Text("'${wordbookToDelete['name']}' 단어장을 삭제하시겠습니까?\n단어장 안의 모든 단어가 함께 삭제됩니다."),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _myWordbooks.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin 사용을 위해 반드시 호출

    int totalCount = 0;
    int memorizedCount = 0;
    _myWordbooks.forEach((wb) {
      final words = wb['words'] as List<WordData>;
      totalCount += words.length;
      memorizedCount += words.where((w) => w.isMemorized).length;
    });
    int notMemorizedCount = totalCount - memorizedCount;

    final bool isSearching = _searchController.text.isNotEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '모든 단어장에서 검색...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: isSearching
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: isSearching
                    ? _searchResults.isEmpty
                    ? Center(child: Text("'${_searchController.text}'에 대한 검색 결과가 없습니다."))
                    : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final word = _searchResults[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(word.word, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(word.definition),
                      ),
                    );
                  },
                )
                    : ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildClickableStatusCard(
                          title: '전체',
                          count: totalCount,
                          color: Colors.blue.shade700,
                          onTap: () {
                            List<WordData> allWords = [];
                            _myWordbooks.forEach((wb) => allWords.addAll(wb['words'] as List<WordData>));
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                FilteredWordsScreen(title: '전체 단어', words: allWords),
                            ));
                          },
                        ),
                        _buildClickableStatusCard(
                          title: '미암기',
                          count: notMemorizedCount,
                          color: Colors.red.shade700,
                          onTap: () {
                            List<WordData> notMemorizedWords = [];
                            _myWordbooks.forEach((wb) {
                              notMemorizedWords.addAll((wb['words'] as List<WordData>).where((w) => !w.isMemorized));
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                FilteredWordsScreen(title: '미암기 단어', words: notMemorizedWords),
                            ));
                          },
                        ),
                        _buildClickableStatusCard(
                          title: '암기',
                          count: memorizedCount,
                          color: Colors.green.shade700,
                          onTap: () {
                            List<WordData> memorizedWords = [];
                            _myWordbooks.forEach((wb) {
                              memorizedWords.addAll((wb['words'] as List<WordData>).where((w) => w.isMemorized));
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                FilteredWordsScreen(title: '암기한 단어', words: memorizedWords),
                            ));
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildSectionHeader('단어장 목록'),
                    SizedBox(height: 10),
                    if (_myWordbooks.isEmpty)
                      Center(child: Text('생성된 단어장이 없습니다.', style: TextStyle(color: Colors.grey.shade600)))
                    else
                      ..._myWordbooks.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> wordbook = entry.value;
                        return _buildWordbookItem(wordbook, index);
                      }).toList(),
                    SizedBox(height: 30),
                    _buildSectionHeader('Pick 단어장', showAddButton: false),
                    Text('버튼을 눌러 추천 단어장을 자동으로 생성하세요', style: TextStyle(color: Colors.grey.shade700)),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _pickWordbooks.entries.map((entry) {
                        return ElevatedButton(
                          child: Text(entry.key),
                          onPressed: _isLoading ? null : () {
                            _createWordbookFromFile(entry.key, entry.value);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClickableStatusCard({
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
                SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showAddButton = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (showAddButton)
          IconButton(
            icon: Icon(Icons.add, color: Colors.green),
            onPressed: _showCreateWordbookDialog,
          ),
      ],
    );
  }

  Widget _buildWordbookItem(Map<String, dynamic> wordbook, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(wordbook['name']),
        subtitle: Text('단어 ${(wordbook['words'] as List<WordData>).length}개'),
        leading: Icon(Icons.book, color: Colors.green.shade300),
        onTap: () => _navigateToDetail(index),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
          tooltip: '단어장 삭제',
          onPressed: () {
            _showDeleteWordbookConfirmDialog(index);
          },
        ),
      ),
    );
  }
}

// --- 새로 추가된 부분: 단어 검색 및 추가 화면 ---
class WordSearchScreen extends StatefulWidget {
  @override
  _WordSearchScreenState createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  final _searchController = TextEditingController();
  WordData? _foundWord;
  bool _isLoading = false;

  void _searchWord() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() { _isLoading = true; _foundWord = null; });

    if (Dictionary.contains(query)) {
      final apiResult = await fetchWordData(query);
      if (mounted) {
        if (apiResult != null) {
          _foundWord = WordData(
            word: apiResult['word'] ?? query,
            pronunciation: apiResult['pronunciation'] ?? '',
            definition: apiResult['koreanMeaning'] ?? '한글 뜻을 찾을 수 없습니다',
            englishExample: apiResult['englishExample'] ?? '예문 없음',
          );
          // --- 여기까지 수정 ---
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("API에서 단어 정보를 불러오지 못했습니다.")));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$query'은(는) 사전에 없는 단어입니다.")));
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('단어 정보 검색')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: '영단어를 입력하세요',
                  suffixIcon:
                  IconButton(icon: Icon(Icons.search), onPressed: _searchWord),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8))),
              onSubmitted: (_) => _searchWord(),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else if (_foundWord != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_foundWord!.word, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(_foundWord!.pronunciation, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                      Divider(height: 24),
                      Text('뜻:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(_foundWord!.definition, style: TextStyle(fontSize: 16)),

                      // --- 이 부분이 추가됩니다 ---
                      SizedBox(height: 16),
                      Text('예문:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        _foundWord!.englishExample,
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                      ),
                      // --- 여기까지 추가 ---

                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, _foundWord),
                        child: Text('이 단어 추가하기'),
                      )
                    ],
                  ),
                ),
              )
            else
              Expanded(child: Center(child: Text('단어를 검색해 주세요.'))),
          ],
        ),
      ),
    );
  }
}

// --- 새로 추가된 부분: 단어장 생성 화면 ---
class WordbookCreateScreen extends StatefulWidget {
  @override
  _WordbookCreateScreenState createState() => _WordbookCreateScreenState();
}

class _WordbookCreateScreenState extends State<WordbookCreateScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _createWordbook() {
    if (_nameController.text.trim().isNotEmpty) {
      Navigator.pop(context, _nameController.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('단어장 이름을 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '새 단어장 만들기',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '단어장 이름',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createWordbook,
                child: Text('완료'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordbookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> wordbook;
  const WordbookDetailScreen({Key? key, required this.wordbook}) : super(key: key);

  @override
  _WordbookDetailScreenState createState() => _WordbookDetailScreenState();
}

class _WordbookDetailScreenState extends State<WordbookDetailScreen> {
  late List<WordData> _words;
  late String _wordbookName;

  @override
  void initState() {
    super.initState();
    _words = widget.wordbook['words'] as List<WordData>;
    _wordbookName = widget.wordbook['name'] as String;
  }

  void _navigateAndAddWord() async {
    final newWord = await Navigator.push<WordData>(
      context,
      MaterialPageRoute(builder: (context) => WordSearchScreen()),
    );

    if (newWord != null) {
      setState(() {
        if (!_words.any((w) => w.word.toLowerCase() == newWord.word.toLowerCase())) {
          _words.add(newWord);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("'${newWord.word}'는 이미 단어장에 있습니다.")));
        }
      });
    }
  }

  // ▼▼▼ [수정] 생략되었던 함수 본문 내용 추가 ▼▼▼
  Future<void> _showDeleteConfirmDialog(int index) async {
    final wordToDelete = _words[index];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('단어 삭제'),
          content: Text("'${wordToDelete.word}' 단어를 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  // 로컬 리스트에서 단어 삭제
                  _words.removeAt(index);
                  // 전역 즐겨찾기 목록에서도 해당 단어 삭제
                  AppState.favoriteWords.remove(wordToDelete);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wordbookName),
      ),
      body: _words.isEmpty
          ? Center(
        child: Text(
          '단어장에 추가된 단어가 없습니다.\n아래 버튼으로 단어를 추가해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 80.0),
        itemCount: _words.length,
        itemBuilder: (context, index) {
          final wordData = _words[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: Icon(
                wordData.isMemorized ? Icons.check_circle : Icons.radio_button_unchecked_sharp,
                color: wordData.isMemorized ? Colors.green : Colors.grey,
                size: 28,
              ),
              title: Text(wordData.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              // ▼▼▼ [오류 수정] Padding 위젯에 빠져있던 padding 속성과 child를 추가했습니다. ▼▼▼
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wordData.pronunciation.isNotEmpty)
                      Text(
                        wordData.pronunciation,
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      wordData.definition,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    if (wordData.englishExample.isNotEmpty && wordData.englishExample != '예문을 찾을 수 없습니다') ...[
                      const Divider(height: 16),
                      Text(
                        wordData.englishExample,
                        style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  wordData.isMemorized = !wordData.isMemorized;
                });
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      wordData.isFavorite ? Icons.star : Icons.star_border,
                      color: wordData.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        wordData.isFavorite = !wordData.isFavorite;
                        if (wordData.isFavorite) {
                          AppState.favoriteWords.add(wordData);
                        } else {
                          AppState.favoriteWords.remove(wordData);
                        }
                      });
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmDialog(index);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddWord,
        label: const Text('단어 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class FilteredWordsScreen extends StatefulWidget {
  final String title;
  final List<WordData> words;

  const FilteredWordsScreen({
    Key? key,
    required this.title,
    required this.words,
  }) : super(key: key);

  @override
  State<FilteredWordsScreen> createState() => _FilteredWordsScreenState();
}

class _FilteredWordsScreenState extends State<FilteredWordsScreen> {
  late List<WordData> _words;

  @override
  void initState() {
    super.initState();
    _words = widget.words;
  }

  Future<void> _showDeleteConfirmDialog(int index) async {
    // (이 함수는 기존과 동일합니다)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _words.isEmpty
          ? Center(
        child: Text(
          '표시할 단어가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 80.0),
        itemCount: _words.length,
        itemBuilder: (context, index) {
          final wordData = _words[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: Icon(
                wordData.isMemorized ? Icons.check_circle : Icons.radio_button_unchecked_sharp,
                color: wordData.isMemorized ? Colors.green : Colors.grey,
                size: 28,
              ),
              title: Text(wordData.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              // ▼▼▼ [오류 수정] Padding 위젯에 빠져있던 padding 속성과 child를 추가했습니다. ▼▼▼
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wordData.pronunciation.isNotEmpty)
                      Text(
                        wordData.pronunciation,
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      wordData.definition,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    if (wordData.englishExample.isNotEmpty && wordData.englishExample != '예문을 찾을 수 없습니다') ...[
                      const Divider(height: 16),
                      Text(
                        wordData.englishExample,
                        style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  wordData.isMemorized = !wordData.isMemorized;
                });
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      wordData.isFavorite ? Icons.star : Icons.star_border,
                      color: wordData.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        wordData.isFavorite = !wordData.isFavorite;
                        if (wordData.isFavorite) {
                          AppState.favoriteWords.add(wordData);
                        } else {
                          AppState.favoriteWords.remove(wordData);
                        }
                      });
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmDialog(index);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _handleError(String message) {
    // 화면에 오류 메시지를 표시하고 로딩 상태를 중지하는 역할을 합니다.
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoadingAnalysis = false; // 모든 로딩 상태를 false로 설정
        _isLoadingClone = false;
        _isLoadingCorrection = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _isRecorderReady = false;
  bool _isPlayerReady = false;
  String? _audioPath;

  bool _isLoadingClone = false;
  bool _isLoadingCorrection = false;
  bool _isLoadingAnalysis = false;
  bool _isVoiceCloned = false;

  String? _errorMessage;
  String? _userId = "user_123_test";

  PronunciationAnalysisResult? _analysisResult;
  bool isStarred = false;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _initRecorderAndPlayer();
  }

  Future<void> _initRecorderAndPlayer() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _errorMessage = '마이크 권한이 필요합니다.');
      return;
    }
    await _recorder.openRecorder();
    await _player.openPlayer();
    setState(() {
      _isRecorderReady = true;
      _isPlayerReady = true;
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  // 녹음 시작/중지 및 분석/복제 실행
  Future<void> _toggleRecording() async {
    final ApiService _apiService = ApiService();
    if (!_isRecorderReady) return;

    if (_recorder.isRecording) {
      // 녹음 중지
      await _recorder.stopRecorder();
      setState(() {});

      if (_audioPath != null) {
        setState(() {
          _isLoadingAnalysis = true; // 로딩 상태 시작
          _isLoadingClone = true; // 클론 로딩 상태도 시작
          _errorMessage = null;
          _analysisResult = null;
        });

        try {
          // [핵심] 분석과 음성 등록을 동시에 병렬로 실행합니다.
          await Future.wait([
            // 작업 1: 분석 및 DB 저장
            _apiService.analyzeAndSavePronunciation(
              audioPath: _audioPath!,
              targetText: 'Can I book a flight to LA now?',
            ).then((response) {
              if (mounted && response['success'] == true) {
                setState(() {
                  _analysisResult = PronunciationAnalysisResult.fromJson(response);
                });
              } else {
                _handleError(response['error'] ?? '분석/저장에 실패했습니다.');
              }
            }),

            // 작업 2: 음성 등록 (Voice Clone)
            _cloneUserVoice(_audioPath!),

          ]);

          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ 분석 및 음성 등록이 완료되었습니다!')),
            );
          }

        } catch (e) {
          _handleError('오류가 발생했습니다: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isLoadingAnalysis = false; // 모든 로딩 상태 종료
              _isLoadingClone = false;
            });
          }
        }
      }
    } else {
      // 녹음 시작 (기존과 동일)
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/user_pronunciation.m4a';
      setState(() {
        _isVoiceCloned = false;
        _analysisResult = null;
      });

      await _recorder.startRecorder(toFile: _audioPath, codec: Codec.aacMP4);
      setState(() {});
    }
  }

  // 발음 분석 API를 호출하는 새 함수
  Future<void> _analyzePronunciation(String path) async {
    try {
      const String baseUrl = String.fromEnvironment(
          'AI_BACKEND_URL',
          defaultValue: 'http://10.0.2.2:8000'
      );
      final url = Uri.parse('$baseUrl/api/pronunciation/analyze');

      final file = File(path);
      final audioBytes = await file.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_base64': base64Audio,
          'target_text': 'Can I book a flight to LA now?',
          'user_level': 'B1',
          'language': 'en',
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (responseBody['success']) {
          setState(() {
            _analysisResult = PronunciationAnalysisResult.fromJson(responseBody);
          });
        } else {
          setState(() => _errorMessage = responseBody['error'] ?? '발음 분석에 실패했습니다.');
        }
      } else {
        setState(() => _errorMessage = '발음 분석 실패 (서버 오류: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = '발음 분석 중 오류 발생: $e');
    } finally {
      setState(() => _isLoadingAnalysis = false);
    }
  }

  // 음성 복제 함수
  Future<void> _cloneUserVoice(String path) async {

    print("--- [1/4] _cloneUserVoice 함수 시작됨 ---");

    try {
      const String baseUrl = String.fromEnvironment(
          'AI_BACKEND_URL',
          defaultValue: 'http://10.0.2.2:8000'
      );
      final url = Uri.parse('$baseUrl/api/voice/clone');

      final file = File(path);
      final audioBytes = await file.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      print("--- [2/4] AI 서버로 음성 등록 요청을 보냅니다... ---");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'voice_sample_base64': base64Audio,
        }),
      ).timeout(const Duration(seconds: 45));

      print("--- [3/4] AI 서버 응답 수신 ---");
      print("상태 코드: ${response.statusCode}");
      print("응답 내용: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (responseBody['success']) {
          setState(() => _isVoiceCloned = true);
          print("--- [4/4] 성공: _isVoiceCloned 스위치가 true로 변경됨! ---");
        } else {
          setState(() => _errorMessage = responseBody['error'] ?? '음성 복제에 실패했습니다.');
        }
      } else {
        setState(() => _errorMessage = '음성 복제 실패 (서버 오류: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = '음성 복제 중 오류 발생: $e');
      print("--- [4/4] 실패: catch 블록에서 오류 발생: $e ---");
    } finally {
      setState(() => _isLoadingClone = false);
    }
  }

  // 교정된 발음 듣기 함수
  Future<void> _getAndPlayCorrection() async {
    if (_audioPath == null || !_isVoiceCloned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 발음을 녹음하고 음성을 등록해주세요.')),
      );
      return;
    }
    if (!_isPlayerReady || _player.isPlaying) return;

    setState(() {
      _isLoadingCorrection = true;
      _errorMessage = null;
    });

    try {
      const String baseUrl = String.fromEnvironment(
          'AI_BACKEND_URL',
          defaultValue: 'http://10.0.2.2:8000'
      );
      final url = Uri.parse('$baseUrl/api/pronunciation/personalized-correction');

      final file = File(_audioPath!);
      final audioBytes = await file.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'target_text': 'Can I book a flight to LA now?',
          'user_audio_base64': base64Audio,
          'user_level': 'B1',
          'language': 'en',
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (responseBody['success']) {
          final correctedAudioBase64 = responseBody['data']['corrected_audio_base64'];
          await _playAudioFromBase64(correctedAudioBase64);
        } else {
          setState(() => _errorMessage = responseBody['error'] ?? '교정된 발음 생성에 실패했습니다.');
        }
      } else {
        setState(() => _errorMessage = '발음 교정 실패 (서버 오류: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = '발음 교정 중 오류 발생: $e');
    } finally {
      setState(() => _isLoadingCorrection = false);
    }
  }

  // Base64 오디오 재생 함수
  Future<void> _playAudioFromBase64(String base64String) async {
    try {
      Uint8List audioBytes = base64Decode(base64String);
      await _player.startPlayer(
        fromDataBuffer: audioBytes,
        codec: Codec.mp3,
        whenFinished: () => setState(() {}),
      );
    } catch (e) {
      setState(() => _errorMessage = "재생 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isRecording = _recorder.isRecording;
    final bool isBusy = _isLoadingClone || _isLoadingCorrection || _isLoadingAnalysis;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                children: [
                  const Text(
                    'Can I book a flight\nto LA now?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Icon(Icons.volume_up, size: 24, color: Colors.grey.shade700),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : _toggleRecording,
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    label: Text(
                      isRecording ? '녹음 중지' : '내 발음 녹음',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecording ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy || isRecording ? null : _getAndPlayCorrection, // 녹음 중일 때도 비활성화
                    child: const Text('교정 발음 듣기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingAnalysis || _isLoadingClone)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text("음성 분석 및 등록 중...")]),
              ),
            if (_isLoadingCorrection)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text("교정된 발음 생성 중...")]),
              ),
            if (_errorMessage != null && !isBusy && !isRecording)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isStarred = !isStarred),
                  child: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: isStarred ? Colors.orange : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => isBookmarked = !isBookmarked),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_analysisResult != null && !_isLoadingAnalysis)
              _buildAnalysisResultCard(_analysisResult!),

          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResultCard(PronunciationAnalysisResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📊 발음 분석 결과", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Center(
              child: _buildScoreIndicator("종합 점수", result.overallScore, Colors.blue),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreIndicator("음높이", result.pitchScore, Colors.orange),
                _buildScoreIndicator("리듬", result.rhythmScore, Colors.green),
                _buildScoreIndicator("강세", result.stressScore, Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            _buildFeedbackSection("상세 피드백", Icons.comment, result.detailedFeedback),
            const SizedBox(height: 16),
            _buildFeedbackSection("개선 제안", Icons.lightbulb, result.suggestions),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String title, double score, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: score / 100.0,
                strokeWidth: 8,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFeedbackSection(String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text("• $item", style: const TextStyle(fontSize: 14)),
        )).toList(),
      ],
    );
  }
}


class SituationScreen extends StatefulWidget {
  const SituationScreen({super.key});

  @override
  State<SituationScreen> createState() => _SituationScreenState();
}

class _SituationScreenState extends State<SituationScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ▼▼▼ [수정] 1. API 키와 UI 데이터를 관리하기 위한 Map들을 정의합니다. ▼▼▼
  // 서버로 보낼 API 키 (영어)
  final Map<String, String> _situationApiKeys = {
    '공항': 'airport',
    '식당': 'restaurant',
    '호텔': 'hotel',
    '길거리': 'street',
  };

  // 화면에 표시될 이미지 경로
  final Map<String, String> _situationImagePaths = {
    '공항': 'assets/airport.png',
    '식당': 'assets/restaurant.png',
    '호텔': 'assets/hotel.png',
    '길거리': 'assets/road.png',
  };

  // 이미지가 없을 경우를 대비한 대체 아이콘
  final Map<String, IconData> _situationFallbackIcons = {
    '공항': Icons.flight_takeoff,
    '식당': Icons.restaurant_menu_outlined,
    '호텔': Icons.hotel_outlined,
    '길거리': Icons.signpost_outlined,
  };


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '공부하고 싶은 상황을\n선택해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              // ▼▼▼ [수정] 2. Map 데이터를 기반으로 버튼 목록을 동적으로 생성합니다. ▼▼▼
              children: _situationApiKeys.keys.map((String situationName) {
                // '공항', '식당' ...
                final String apiKey = _situationApiKeys[situationName]!;
                final String imagePath = _situationImagePaths[situationName]!;
                final IconData fallbackIcon = _situationFallbackIcons[situationName]!;

                return _buildSituationButton(
                  context,
                  situation: situationName, // UI에 표시될 이름 (예: '공항')
                  imagePath: imagePath,
                  fallbackIcon: fallbackIcon,
                  onTap: () {
                    print('선택: $situationName, API Key: $apiKey'); // 디버깅 로그
                    // ▼▼▼ [수정] 3. ConversationScreen으로 이동할 때 한글 이름이 아닌 '영어 API 키'를 전달합니다. ▼▼▼
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(situation: apiKey),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // _buildSituationButton 위젯은 기존 코드와 동일하게 재사용합니다.
  Widget _buildSituationButton(BuildContext context, {
    required String situation,
    String? imagePath,
    IconData? fallbackIcon,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon ?? Icons.help_outline,
                    size: 60,
                    color: Colors.green,
                  );
                },
              )
            else
              Icon(
                fallbackIcon ?? Icons.help_outline,
                size: 60,
                color: Colors.green,
              ),
            const SizedBox(height: 12),
            Text(
              situation,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  String conversationText;
  final String? educationalText;
  final bool isUser;
  bool isExpanded;

  ChatMessage({
    required this.conversationText,
    this.educationalText,
    this.isUser = false,
    this.isExpanded = false,
  });
}

class ConversationScreen extends StatefulWidget {
  final String situation;

  const ConversationScreen({super.key, required this.situation});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final String _baseUrl = const String.fromEnvironment(
      'AI_BACKEND_URL',
      defaultValue: 'http://10.0.2.2:8000'
  );
  String? _sessionId;
  bool _isLoading = true;
  String _loadingMessage = 'AI와 연결하는 중...';

  // 👈 2. 대화 데이터 리스트의 타입을 Map에서 ChatMessage 클래스로 변경
  final List<ChatMessage> _messages = [];

  FlutterSoundRecorder? _recorder;
  final AudioPlayer _player = AudioPlayer(playerId: 'conversation_player');
  bool _isRecording = false;
  String? _recordingPath;
  final FlutterTts _flutterTts = FlutterTts();

  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
    _playerStateSubscription = _player.onPlayerStateChanged.listen((PlayerState state) {
      print('[AudioPlayer][Conversation] 상태 변경: $state');
    });
    _player.onLog.listen((String log) {
      print('[AudioPlayer][Conversation] 상세 로그: $log');
    }, onError: (Object e) {
      print('[AudioPlayer][Conversation] 로그 에러: $e');
    });
  }

  Future<void> _initialize() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = '마이크 권한이 필요합니다.';
      });
      return;
    }
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _startNewConversation();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;

    // 👇 3단계: dispose가 호출될 때 리스너를 취소(cancel)합니다.
    _playerStateSubscription?.cancel();
    _player.dispose();

    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.speak(text);
  }

  // 👈 3. AI 응답 텍스트를 파싱하여 _messages 리스트에 추가하는 헬퍼 함수
  void _addAiResponseMessage(String fullResponseText) {
    const separator = '\n\n======== Recommended ========\n\n';
    final parts = fullResponseText.split(separator);
    final conversationText = parts[0].trim();
    final educationalText = parts.length > 1 ? parts[1].trim() : null;

    setState(() {
      _messages.add(ChatMessage(
        conversationText: conversationText,
        educationalText: educationalText,
        isUser: false,
      ));
    });
  }

  Future<void> _startNewConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/conversation/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'flutter_user_01',
          'situation': widget.situation,
          'difficulty': 'beginner',
          // 👇 [수정] 'en'을 AppState.selectedLanguage로 변경합니다.
          'language': AppState.selectedLanguage == '영어' ? 'en' :
          AppState.selectedLanguage == '일본어' ? 'ja' :
          AppState.selectedLanguage == '중국어' ? 'zh' :
          AppState.selectedLanguage == '불어' ? 'fr' : 'en',
          'mode': 'auto',
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success']) {
          final data = body['data'];
          _sessionId = data['session_id'];
          _addAiResponseMessage(data['ai_message']); // 👈 헬퍼 함수 사용
        } else {
          _handleError(body['error'] ?? '대화 시작에 실패했습니다.');
        }
      } else {
        _handleError('서버에 연결할 수 없습니다. (코드: ${response.statusCode})');
      }
    } catch (e) {
      _handleError('네트워크 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendVoiceMessage(String path) async {
    if (_sessionId == null) return;

    final userMessage = ChatMessage(
        conversationText: '🎤 (음성 메시지를 보냈습니다)', isUser: true);
    setState(() {
      _isLoading = true;
      _loadingMessage = '음성을 분석하는 중...';
      _messages.add(userMessage);
    });

    try {
      final audioBytes = await File(path).readAsBytes();
      final audioBase64 = base64Encode(audioBytes);
      final response = await http.post(
        Uri.parse('$_baseUrl/api/conversation/voice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _sessionId,
          'audio_base64': audioBase64,
          // 👇 [수정] 'en'을 AppState.selectedLanguage로 변경합니다.
          'language': AppState.selectedLanguage == '영어' ? 'en' :
          AppState.selectedLanguage == '일본어' ? 'ja' :
          AppState.selectedLanguage == '중국어' ? 'zh' :
          AppState.selectedLanguage == '불어' ? 'fr' : 'en',
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success']) {
          final data = body['data'];
          setState(() {
            userMessage.conversationText = '🗣️ "${data['recognized_text']}"';
          });
          _addAiResponseMessage(data['ai_message']);

          // ▼▼▼ [수정된 부분] ▼▼▼
          // AI가 보낸 전체 메시지에서 실제 대화 부분만 추출합니다.
          final conversationText = (data['ai_message'] as String).split('\n\n======== Recommended ========')[0].trim();
          // 추출한 텍스트를 앱에서 직접 음성으로 재생합니다.
          _speak(conversationText);
          // ▲▲▲ [수정된 부분] ▲▲▲

        } else {
          setState(() =>
          userMessage.conversationText = '⚠️ 전송 실패: ${body['error']}');
          _handleError(body['error'] ?? '음성 처리에 실패했습니다.');
        }
      } else {
        setState(() =>
        userMessage.conversationText = '⚠️ 서버 오류 (코드: ${response.statusCode})');
        _handleError('서버 응답 오류가 발생했습니다.');
      }
    } catch (e) {
      setState(() => userMessage.conversationText = '⚠️ 네트워크 오류');
      _handleError('음성 전송 중 오류 발생: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTextMessage() async {
    if (_textController.text.isEmpty || _sessionId == null) return;
    final userMessageText = _textController.text;
    _textController.clear();

    setState(() {
      _isLoading = true;
      _loadingMessage = 'AI가 답변을 생각하는 중...';
      _messages.add(
          ChatMessage(conversationText: '🗣️ "$userMessageText"', isUser: true));
    });

    try {
      final response = await http.post(
          Uri.parse('$_baseUrl/api/conversation/text'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'session_id': _sessionId!,
            'message': userMessageText,
            // 👇 [수정] 'en'을 AppState.selectedLanguage로 변경합니다.
            'language': AppState.selectedLanguage == '영어' ? 'en' :
            AppState.selectedLanguage == '일본어' ? 'ja' :
            AppState.selectedLanguage == '중국어' ? 'zh' :
            AppState.selectedLanguage == '불어' ? 'fr' : 'en',
          })
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        if (responseBody['success']) {
          final data = responseBody['data'];
          _addAiResponseMessage(data['ai_message']);

          // ▼▼▼ [수정된 부분] ▼▼▼
          // AI가 보낸 전체 메시지에서 실제 대화 부분만 추출합니다.
          final conversationText = (data['ai_message'] as String).split('\n\n======== Recommended ========')[0].trim();
          // 추출한 텍스트를 앱에서 직접 음성으로 재생합니다.
          _speak(conversationText);
          // ▲▲▲ [수정된 부분] ▲▲▲

        } else {
          _handleError(responseBody['error'] ?? '메시지 처리에 실패했습니다.');
        }
      } else {
        _handleError('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('메시지 전송 중 오류 발생: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/flutter_sound.m4a';
    await _recorder!.startRecorder(toFile: _recordingPath, codec: Codec.aacMP4);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() => _isRecording = false);
    if (_recordingPath != null) {
      _sendVoiceMessage(_recordingPath!);
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
      _loadingMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    String characterImage = 'assets/fox.png';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('회화 학습'),
        backgroundColor: const Color(0xFFF3F4F8),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(
                vertical: 16.0, horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              '#${widget.situation}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800),
            ),
          ),
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_loadingMessage)
              ],
            ))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // 👈 4. ListView 빌드 로직을 새 데이터 모델에 맞게 수정
                if (message.isUser) {
                  return _buildUserMessageBubble(message);
                } else {
                  // AI 메시지는 대화 말풍선과 교육 박스를 Column으로 묶어서 표시
                  return Column(
                    children: [
                      _buildAiMessageBubble(message),
                      if (message.educationalText != null)
                        _buildEducationalBox(message, index), // 👈 새 위젯 호출
                    ],
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? Colors.red.shade700 : Colors.green
                            .shade800),
                    onPressed: _isLoading ? null : (_isRecording
                        ? _stopRecording
                        : _startRecording),
                    style: IconButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.green.shade800),
                    onPressed: _isLoading ? null : _sendTextMessage,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 👈 5. 말풍선 위젯들을 역할에 맞게 3개로 분리/수정
  Widget _buildUserMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(message.conversationText, style: const TextStyle(
                fontSize: 15, color: Colors.black87, height: 1.4)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: AssetImage(AppState.selectedCharacterImage),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: Text(message.conversationText,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.black87, height: 1.4))),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.volume_up, color: Colors.green.shade600,
                        size: 22),
                    onPressed: () => _speak(message.conversationText),
                    splashRadius: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalBox(ChatMessage message, int index) {
    return Container(
      margin: const EdgeInsets.only(left: 32, bottom: 16),
      child: InkWell( // InkWell로 감싸서 탭 이벤트를 받음
        onTap: () {
          setState(() {
            // 해당 메시지의 isExpanded 상태를 반전시킴
            _messages[index].isExpanded = !_messages[index].isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 항상 보이는 헤더 부분
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text("Recommended", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // 펼침/접힘 상태에 따라 아이콘 변경
                  Icon(message.isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
              // isExpanded가 true일 때만 보이는 상세 내용
              if (message.isExpanded) ...[
                const Divider(height: 20),
                Text(
                  message.educationalText!,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// 커뮤니티 화면 (수정됨)
class CommunityScreen extends StatefulWidget {
  final TabController tabController;
  const CommunityScreen({Key? key, required this.tabController}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _allPosts = [];
  final List<String> _tabs = ['자유게시판', '질문게시판', '정보공유', '스터디모집'];

  void _navigateAndCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostWriteScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _allPosts.add(result);
      });
    }
  }

  Widget _buildPostList(String category) {
    final categoryPosts = _allPosts.where((post) => post['category'] == category).toList();

    if (categoryPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            '아직 작성된 글이 없어요.\n오른쪽 아래 버튼으로 첫 글을 작성해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
          ),
        ),
      );
    }

    // ▼▼▼ [수정] ListView에 패딩을 추가하고, 게시글 아이템을 Card로 변경 ▼▼▼
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: categoryPosts.length,
      itemBuilder: (context, index) {
        final post = categoryPosts[index];
        final tags = (post['tags'] as List<String>?)?.join(' ') ?? '';

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (tags.isNotEmpty)
                    Text(
                      tags,
                      style: TextStyle(fontSize: 14, color: Colors.blueAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        TabBarView(
          controller: widget.tabController,
          children: _tabs.map((category) => _buildPostList(category)).toList(),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _navigateAndCreatePost,
            label: Text('글 작성'),
            icon: Icon(Icons.edit_outlined),
            // ▼▼▼ [수정] FAB 색상을 앱 테마와 통일 ▼▼▼
            // backgroundColor는 앱 전체 테마(MyApp)에서 자동으로 적용됨
          ),
        ),
      ],
    );
  }
}

// 글 작성 화면 (오류 수정 및 디자인 통일) -> 이 클래스 전체를 아래 코드로 교체하세요.
class PostWriteScreen extends StatefulWidget {
  const PostWriteScreen({super.key});

  @override
  _PostWriteScreenState createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  // 1. 상태 변수: 컨트롤러 및 카테고리 목록
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  // '게시판 선택' 플레이스홀더를 제거하고, 실제 카테고리만 목록에 포함합니다.
  final List<String> _categories = ['자유게시판', '질문게시판', '정보공유', '스터디모집'];
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    // 첫 번째 카테고리를 기본 선택값으로 설정합니다.
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    // 2. 컨트롤러 해제
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // 3. 게시글 제출 로직
  void _submitPost() {
    // 키보드를 내립니다.
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 제목과 내용이 비어있는지 확인합니다.
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 모두 입력해주세요.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; // 비어있으면 함수 종료
    }

    // 태그를 파싱합니다.
    final tags = _tagController.text
        .split('#')
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => '#${tag.trim()}')
        .toList();

    // 결과 데이터를 Map 형태로 생성합니다.
    final newPost = {
      'category': _selectedCategory,
      'title': title,
      'content': content,
      'tags': tags,
    };

    // 성공 메시지를 보여주고 이전 화면으로 돌아갑니다.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('게시글이 성공적으로 등록되었습니다!')),
    );
    Navigator.pop(context, newPost);
  }

  // 4. 화면 UI 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게시글 작성'),
        actions: [
          // 등록 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _submitPost,
              child: const Text('등록', style: TextStyle(fontSize: 16)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // 각 입력 필드를 명확하게 구분하기 위해 Column 사용
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 카테고리 선택 ---
            const Text(
              '카테고리 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // DropdownButton을 FormField로 감싸 앱 테마와 일관성 유지
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              // InputDecoration은 앱 전체 테마가 적용됩니다.
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 24),

            // --- 제목 입력 ---
            _buildTextField(
              controller: _titleController,
              label: '제목',
              hint: '제목을 입력하세요',
            ),
            const SizedBox(height: 24),

            // --- 내용 입력 ---
            _buildTextField(
              controller: _contentController,
              label: '내용',
              hint: '학습에 대한 질문이나 공유하고 싶은 이야기를 자유롭게 작성해보세요.',
              maxLines: 8,
            ),
            const SizedBox(height: 24),

            // --- 태그 입력 ---
            _buildTextField(
              controller: _tagController,
              label: '태그 (선택)',
              hint: '#태그1 #학습법 형식으로 입력',
              prefixIcon: const Icon(Icons.tag, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // 반복되는 TextField UI를 위한 헬퍼 위젯
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    Icon? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            // alignLabelWithHint는 여러 줄 TextField에서 hint 텍스트를 상단에 정렬합니다.
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

// --- 게시글 상세 보기 화면 (라벨 및 테마 수정) ---
class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<String> _comments = [];

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add(_commentController.text.trim());
        _commentController.clear();
        FocusScope.of(context).unfocus(); // 댓글 등록 후 키보드 내리기
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = (widget.post['tags'] as List<String>?)?.join(' ') ?? '';

    // ▼▼▼ [수정] Scaffold 배경색을 앱 기본 테마 색상으로 변경 ▼▼▼
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        // ▼▼▼ [수정] AppBar의 개별 스타일을 제거하여 앱 전체 테마를 따르도록 함 ▼▼▼
        title: Text(widget.post['category']),
        // backgroundColor와 leading 아이콘 색상 등은 앱 테마에서 자동으로 적용됩니다.
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  // Card로 감싸서 내용 영역을 시각적으로 구분
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- '제목' 라벨 ---
                          Text(
                            '제목',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.post['title'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (tags.isNotEmpty)
                            Text(
                              tags,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 20),
                          // ▼▼▼ [수정] Divider 색상을 회색 계열로 변경 ▼▼▼
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 20),
                          // --- '내용' 라벨 ---
                          Text(
                            '내용',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.post['content'],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6, // 줄 간격
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- 댓글 섹션 ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                    child: Text(
                      '댓글 ${_comments.length}개',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 댓글이 없을 경우 안내 메시지 표시
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          '아직 댓글이 없습니다.\n첫 댓글을 남겨보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._comments.map((comment) => Card(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: ListTile(
                        leading: const Icon(Icons.account_circle, color: Colors.grey),
                        title: Text(comment),
                      ),
                    )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- 댓글 입력창 ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // 카드 색상과 동일하게
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          filled: true,
                          fillColor: Colors.grey.shade200, // 입력창 배경색
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (value) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ▼▼▼ [수정] 아이콘 버튼 색상을 테마 색상으로 변경 ▼▼▼
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.green, // 테마 색상으로 변경
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 피드백 화면 클래스
class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ [수정] 배경색을 앱 테마와 통일 ▼▼▼
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('피드백 작성'),
        // ▼▼▼ [수정] AppBar 배경색도 통일 ▼▼▼
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // ▼▼▼ [수정] 제목 입력창 스타일을 앱 테마와 통일 ▼▼▼
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요.',
                // InputDecoration 스타일은 앱 전체 테마(MyApp)에서 적용됨
              ),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),

            // 내용 입력창
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '소중한 의견을 남겨주세요.',
                  alignLabelWithHint: true, // hintText가 위로 정렬되도록 함
                ),
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            SizedBox(height: 24),

            // ▼▼▼ [수정] 등록 버튼 스타일을 앱 테마와 통일 ▼▼▼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // onPressed 로직은 변경 없음
                onPressed: () {
                  if (_titleController.text.trim().isNotEmpty &&
                      _contentController.text.trim().isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('피드백이 성공적으로 제출되었습니다.'),
                        // backgroundColor는 SnackBarTheme으로 관리하거나 직접 지정
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('제목과 내용을 모두 입력해주세요.'),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  }
                },
                child: Text('등록'),
                // ElevatedButton 스타일은 앱 전체 테마(MyApp)에서 자동으로 적용됨
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

// 알림 설정 화면 클래스
class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool studyNotification = true;
  bool reminderNotification = true;

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ [수정] 배경색을 앱 테마와 통일 ▼▼▼
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('알림 설정'),
        // ▼▼▼ [수정] AppBar 배경색도 통일 ▼▼▼
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // ▼▼▼ [수정] UI를 Card 형태로 변경하여 통일성 부여 ▼▼▼
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildNotificationItem(
                    imagePath: 'assets/study.png',
                    fallbackIcon: Icons.school_outlined,
                    title: '공부 알림',
                    subtitle: '시작, 현황, 복습 알림',
                    value: studyNotification,
                    onChanged: (value) {
                      setState(() {
                        studyNotification = value;
                      });
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  _buildNotificationItem(
                    imagePath: 'assets/bookmark.png',
                    fallbackIcon: Icons.card_giftcard_outlined,
                    title: '혜택 (광고성) 알림',
                    subtitle: null,
                    value: reminderNotification,
                    onChanged: (value) {
                      setState(() {
                        reminderNotification = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String imagePath,
    required IconData fallbackIcon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // Container를 ListTile로 변경하여 더 깔끔한 UI 구성
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Image.asset(
        imagePath,
        width: 32,
        height: 32,
        errorBuilder: (context, error, stackTrace) {
          // ▼▼▼ [수정] 아이콘 색상을 테마에 맞게 변경 ▼▼▼
          return Icon(fallbackIcon, size: 30, color: Colors.green);
        },
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        // ▼▼▼ [수정] Switch 색상을 테마에 맞게 변경 ▼▼▼
        activeColor: Colors.white,
        activeTrackColor: Colors.green,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade400,
      ),
    );
  }
}

// 자주 찾는 질문(FAQ) 화면 클래스
class FAQScreen extends StatefulWidget {
  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  Map<int, bool> expandedStates = {};

  // ▼▼▼ [수정] 사라졌던 FAQ 데이터 목록을 복원했습니다. ▼▼▼
  final List<Map<String, dynamic>> faqs = [
    {
      'question': '언어를 변경하려면 어떻게 해야 하나요?',
      'answer': '''언어 변경은 다음과 같이 진행하실 수 있습니다:

1. 홈 화면 우상단 설정(⚙️) 버튼을 누르세요
2. '언어 선택' 메뉴를 선택하세요
3. 원하는 언어(영어, 일본어, 중국어, 불어)를 선택하세요
4. '완료' 버튼을 눌러 변경을 저장하세요

변경된 언어는 즉시 홈 화면에 반영됩니다.''',
    },
    {
      'question': '캐릭터를 변경할 수 있나요?',
      'answer': '''네, 언제든지 캐릭터를 변경하실 수 있습니다:

1. 홈 화면 우상단 설정(⚙️) 버튼을 누르세요
2. '캐릭터 선택' 메뉴를 선택하세요
3. 원하는 캐릭터(여우, 고양이, 부엉이, 곰)를 선택하세요
4. '완료' 버튼을 눌러 변경을 저장하세요

변경된 캐릭터는 홈 화면과 회화 학습에서 확인하실 수 있습니다.''',
    },
    {
      'question': '단어장에서 즐겨찾기는 어떻게 추가하나요?',
      'answer': '''단어를 즐겨찾기에 추가하는 방법:

1. 단어장 메뉴로 이동하세요
2. 검색하거나 원하는 단어를 찾으세요
3. 단어 옆에 있는 별(⭐) 아이콘을 누르세요
4. 별이 노란색으로 변하면 즐겨찾기에 추가됩니다

추가된 즐겨찾기는 설정 > 즐겨찾기에서 확인할 수 있습니다.''',
    },
    {
      'question': '알림 설정을 변경하고 싶어요',
      'answer': '''알림 설정은 다음과 같이 변경할 수 있습니다:

1. 홈 화면 설정(⚙️) > 알림 설정으로 이동하세요
2. 두 가지 알림 옵션이 있습니다:
   - 공부 알림: 학습 시작, 현황, 복습 알림
   - 혜택(광고성) 알림: 이벤트 및 프로모션 알림
3. 각 항목의 토글 버튼을 눌러 켜거나 끄세요

설정은 즉시 적용됩니다.''',
    },
    {
      'question': '레벨 테스트를 다시 볼 수 있나요?',
      'answer': '''현재 버전에서는 초기 레벨 테스트만 제공됩니다.

레벨 테스트는 회원가입 후 처음 로그인할 때 한 번 진행되며,
이를 바탕으로 사용자의 학습 수준을 파악합니다.

추후 업데이트에서 재테스트 기능을 추가할 예정입니다.
그때까지는 학습 메뉴를 통해 지속적으로 실력을 향상시켜 주세요!''',
    },
    {
      'question': '발음 연습은 어떻게 하나요?',
      'answer': '''발음 연습 기능 사용법:

1. 홈 화면에서 '학습' 메뉴를 선택하세요
2. 학습 문장이 나타나면 스피커(🔊) 아이콘을 눌러 들어보세요
3. '내 발음 녹음' 버튼을 눌러 따라 말해보세요
4. '조회해서 듣기' 버튼으로 정답을 다시 들을 수 있습니다

반복 연습을 통해 발음 실력을 향상시킬 수 있습니다.''',
    },
    {
      'question': '상황별 회화에서 상황을 추가할 수 있나요?',
      'answer': '''현재는 4가지 기본 상황을 제공합니다:
- 공항 🛫
- 식당 🍽️
- 호텔 🏨
- 길거리 📍

각 상황별로 실용적인 회화 표현들을 학습할 수 있습니다.

더 많은 상황별 회화(쇼핑, 병원, 학교 등)는
향후 업데이트를 통해 추가될 예정입니다.''',
    },
    {
      'question': '커뮤니티에서 글을 삭제하려면?',
      'answer': '''작성한 글을 삭제하는 방법:

1. 커뮤니티에서 삭제하고 싶은 글을 찾으세요
2. 본인이 작성한 글의 경우 수정/삭제 옵션이 표시됩니다
3. 삭제 버튼을 누르고 확인하세요

※ 삭제된 글은 복구할 수 없으니 신중하게 결정해 주세요.
부적절한 내용의 글은 신고 기능을 이용해 주세요.''',
    },
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < faqs.length; i++) {
      expandedStates[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이 부분의 UI 코드는 이전과 동일하게 유지됩니다.
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('자주 찾는 질문'),
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '궁금한 질문을 선택하면 답변을 확인할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  final isExpanded = expandedStates[index] ?? false;
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              expandedStates[index] = !isExpanded;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('Q', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    faq['question'],
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: Container(),
                          secondChild: Column(
                            children: [
                              Divider(height: 1, indent: 16, endIndent: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        faq['answer'],
                                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
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

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // ▼▼▼ [수정] 하드코딩된 데이터 제거 ▼▼▼
  // final List<Map<String, dynamic>> favoriteWords = [ ... ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('즐겨찾기'),
        backgroundColor: Color(0xFFF3F4F8),
      ),
      // ▼▼▼ [수정] AppState.favoriteWords 목록을 기반으로 화면 구성 ▼▼▼
      body: AppState.favoriteWords.isEmpty
      // 즐겨찾기 목록이 비어있을 때
          ? Center(
        child: Text(
          '단어장의 별(⭐)을 눌러\n즐겨찾기를 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
        ),
      )
      // 즐겨찾기 목록이 있을 때
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: AppState.favoriteWords.length,
        itemBuilder: (context, index) {
          final wordData = AppState.favoriteWords[index];

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(wordData.word, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(wordData.definition),
              ),
              // 즐겨찾기 페이지에서 바로 해제할 수 있는 버튼
              trailing: IconButton(
                icon: Icon(Icons.star, color: Colors.amber),
                onPressed: () {
                  setState(() {
                    // 단어 자체의 상태도 false로 변경
                    wordData.isFavorite = false;
                    // 전역 목록에서 제거
                    AppState.favoriteWords.remove(wordData);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('환경설정'),
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 첫 번째 섹션
            _buildSettingButton(
              context,
              icon: Icons.notifications_outlined,
              title: '알림 설정',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                );
              },
            ),
            SizedBox(height: 12),
            _buildSettingButton(
              context,
              icon: Icons.language_outlined,
              title: '언어 선택',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
                );
              },
            ),
            SizedBox(height: 12),
            _buildCharacterButton(context),
            SizedBox(height: 12),
            _buildSettingButton(
              context,
              icon: Icons.star_outline,
              title: '즐겨찾기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoritesScreen()),
                );
              },
            ),
            SizedBox(height: 24),

            // 두 번째 섹션
            _buildSettingButton(
              context,
              icon: Icons.help_outline,
              title: '자주 찾는 질문',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen()),
                );
              },
            ),
            SizedBox(height: 12),
            _buildSettingButton(
              context,
              icon: Icons.feedback_outlined,
              title: '피드백 작성',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen()),
                );
              },
            ),
            SizedBox(height: 12),

            // ▼▼▼ [수정] 공지사항 버튼 추가 ▼▼▼
            _buildSettingButton(
              context,
              icon: Icons.campaign_outlined,
              title: '공지사항',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoticeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterButton(BuildContext context) {
    // 이 위젯의 코드는 이전과 동일합니다.
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CharacterSelectionSettingsScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  AppState.selectedCharacterImage ?? 'assets/fox.png',
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.pets, size: 18, color: Colors.green);
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                '캐릭터 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingButton(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // 이 위젯의 코드는 이전과 동일합니다.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade700),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// 언어 선택 화면
class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? selectedLanguage;

  final List<Map<String, dynamic>> languages = [
    {'name': '영어', 'flag': '🇺🇸'},
    {'name': '일본어', 'flag': '🇯🇵'},
    {'name': '중국어', 'flag': '🇨🇳'},
    {'name': '불어', 'flag': '🇫🇷'},
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = AppState.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ [수정] 배경색을 앱 테마와 통일 ▼▼▼
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('언어 선택'),
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              '공부하고 싶은 언어를\n선택하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final isSelected = selectedLanguage == language['name'];

                  return GestureDetector(
                    onTap: () => setState(() => selectedLanguage = language['name']),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        // ▼▼▼ [수정] 항목 배경색을 흰색으로 변경 ▼▼▼
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // ▼▼▼ [수정] 선택 시 테두리 색상을 테마 색상으로 변경 ▼▼▼
                          color: isSelected ? Colors.green : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(child: Text(language['flag'], style: TextStyle(fontSize: 28))),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              language['name'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          // 라디오 버튼 모양 개선
                          if (isSelected)
                            Icon(Icons.check_circle, color: Colors.green)
                          else
                            Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // onPressed 로직은 그대로 유지
                onPressed: selectedLanguage != null ? () {
                  AppState.selectedLanguage = selectedLanguage!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${selectedLanguage}이(가) 선택되었습니다!')),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                        (route) => false,
                  );
                } : null,
                child: Text('완료'),
                // 스타일은 앱 전체 테마(MyApp)에서 자동으로 적용됨
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 캐릭터 선택 설정 화면
class CharacterSelectionSettingsScreen extends StatefulWidget {
  @override
  _CharacterSelectionSettingsScreenState createState() => _CharacterSelectionSettingsScreenState();
}

class _CharacterSelectionSettingsScreenState extends State<CharacterSelectionSettingsScreen> {
  String? selectedCharacter;

  final List<Map<String, dynamic>> characters = [
    {'name': '여우', 'image': 'assets/fox.png'},
    {'name': '고양이', 'image': 'assets/cat.png'},
    {'name': '부엉이', 'image': 'assets/owl.png'},
    {'name': '곰', 'image': 'assets/bear.png'},
  ];

  @override
  void initState() {
    super.initState();
    selectedCharacter = AppState.selectedCharacterName ?? '여우';
  }

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ [수정] 배경색을 앱 테마와 통일 ▼▼▼
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('캐릭터 선택'),
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              '함께 공부할 캐릭터를\n선택하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final character = characters[index];
                  final isSelected = selectedCharacter == character['name'];

                  return GestureDetector(
                    onTap: () => setState(() => selectedCharacter = character['name']),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        // ▼▼▼ [수정] 항목 배경색을 흰색으로 변경 ▼▼▼
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // ▼▼▼ [수정] 선택 시 테두리 색상을 테마 색상으로 변경 ▼▼▼
                          color: isSelected ? Colors.green : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            character['image'],
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              return CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.pets, color: Colors.green),
                              );
                            },
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              character['name'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: Colors.green)
                          else
                            Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // onPressed 로직은 그대로 유지
                onPressed: selectedCharacter != null ? () {
                  final selectedCharacterData = characters.firstWhere(
                        (char) => char['name'] == selectedCharacter,
                  );

                  AppState.selectedCharacterImage = selectedCharacterData['image'];
                  AppState.selectedCharacterName = selectedCharacterData['name'];

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('캐릭터가 ${selectedCharacter}(으)로 변경되었습니다!')),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                        (route) => false,
                  );
                } : null,
                child: Text('완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // 사용자가 설정할 값들을 저장하는 변수들
  double _currentLevel = 1.0;
  double _goalLevel = 2.0;
  String _frequencyType = 'daily'; // 'daily' or 'interval'
  double _frequencyValue = 1.0;
  double _sessionDuration = 30.0;
  final Map<String, bool> _preferredStyles = {
    'conversation': true,
    'grammar': false,
    'pronunciation': false,
  };

  Future<void> _saveGoal() async {
    setState(() => _isLoading = true);

    final selectedStyles = _preferredStyles.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedStyles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선호 학습 방식을 하나 이상 선택해주세요.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userId = AppState.userId;
      if (userId == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
      }

      // ▼▼▼ [핵심 수정] API 호출 후 반환된 데이터를 newPlan 변수에 저장합니다. ▼▼▼
      final newProfile = await _apiService.createLearningPlan(
        userId: userId,
        currentLevel: _currentLevel.toInt(),
        goalLevel: _goalLevel.toInt(),
        frequencyType: _frequencyType,
        frequencyValue: _frequencyValue.toInt(),
        sessionDuration: _sessionDuration.toInt(),
        preferredStyles: selectedStyles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학습 목표가 성공적으로 저장되었습니다!')),
        );
        // ▼▼▼ [수정] 이전 화면으로 돌아갈 때, 방금 받은 newProfile 데이터를 함께 전달합니다. ▼▼▼
        Navigator.pop(context, newProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학습 목표 설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSliderSection('현재 레벨', _currentLevel, (val) => setState(() => _currentLevel = val)),
          _buildSliderSection('목표 레벨', _goalLevel, (val) => setState(() => _goalLevel = val)),
          const Divider(height: 40),
          _buildFrequencySection(),
          const Divider(height: 40),
          _buildSliderSection('1회 학습 시간 (분)', _sessionDuration, (val) => setState(() => _sessionDuration = val), min: 10, max: 120, divisions: 11),
          const Divider(height: 40),
          _buildStyleSection(),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _saveGoal,
            child: const Text('목표 저장하기'),
          ),
        ],
      ),
    );
  }

  // UI를 그리는 헬퍼 위젯들
  Widget _buildSliderSection(String title, double value, ValueChanged<double> onChanged, {double min = 1, double max = 10, int? divisions = 9}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${value.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Slider(value: value, min: min, max: max, divisions: divisions, label: value.toInt().toString(), onChanged: onChanged),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('학습 빈도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: const Text('매일'),
          value: 'daily',
          groupValue: _frequencyType,
          onChanged: (val) => setState(() => _frequencyType = val!),
        ),
        RadioListTile<String>(
          title: const Text('일 간격'),
          value: 'interval',
          groupValue: _frequencyType,
          onChanged: (val) => setState(() => _frequencyType = val!),
        ),
        _buildSliderSection(
            _frequencyType == 'daily' ? '하루에 몇 번?' : '며칠에 한 번?',
            _frequencyValue,
                (val) => setState(() => _frequencyValue = val),
            max: 5,
            divisions: 4
        ),
      ],
    );
  }

  Widget _buildStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('선호 학습 방식 (1개 이상 선택)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ..._preferredStyles.keys.map((style) => CheckboxListTile(
          title: Text(style),
          value: _preferredStyles[style],
          onChanged: (val) => setState(() => _preferredStyles[style] = val!),
        )).toList(),
      ],
    );
  }
}

class NoticeScreen extends StatefulWidget {
  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  Map<int, bool> expandedStates = {};

  final List<Map<String, dynamic>> notices = [
    {
      'title': '저희 앱을 사용해주셔서 감사합니다.',
      'content': '''안녕하세요. 다국어 언어 학습 앱 개발진입니다.
다시 한 번 저희 앱을 사용해주셔서 감사드립니다!

저희는 사용자분들이 더욱 효과적으로 언어를 학습할 수 있도록 지속적으로 앱을 개선하고 있습니다.

앞으로도 더 나은 서비스로 찾아뵙겠습니다.
감사합니다.''',
    },
    {
      'title': '새로운 기능 업데이트 안내 (v1.1.0)',
      'content': '''이번 업데이트에서 추가된 새로운 기능들을 안내드립니다.

1. 발음 연습 기능 강화
2. 개인화된 학습 추천 시스템
3. 커뮤니티 기능 개선
4. 알림 설정 세분화

더 자세한 내용은 앱 내에서 확인하실 수 있습니다.''',
    },
    {
      'title': '서비스 이용약관 변경 안내 (2024.01.01 시행)',
      'content': '''서비스 이용약관이 일부 변경되었습니다.

주요 변경사항:
- 개인정보 처리방침 개선
- 서비스 이용 규칙 명확화
- 사용자 권리 강화

변경된 약관은 2024년 1월 1일부터 적용됩니다.
자세한 내용은 설정 > 이용약관에서 확인하실 수 있습니다.''',
    },
    {
      'title': '서버 정기 점검 안내 (2024.01.15)',
      'content': '''서비스 안정성 향상을 위한 정기 점검을 실시합니다.

점검 일시: 2024년 1월 15일 (월) 02:00 ~ 06:00
점검 내용: 서버 안정화 및 성능 개선

점검 시간 중에는 일시적으로 서비스 이용이 제한될 수 있습니다.
이용에 불편을 드려 죄송합니다.''',
    },
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < notices.length; i++) {
      expandedStates[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ [수정] 배경색을 앱 테마와 통일 ▼▼▼
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('공지사항'),
        // ▼▼▼ [수정] AppBar 배경색도 통일 ▼▼▼
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            final isExpanded = expandedStates[index] ?? false;

            // Container를 Card로 변경하여 앱의 다른 카드들과 디자인 일관성 유지
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        expandedStates[index] = !isExpanded;
                      });
                    },
                    child: Container(
                      // Card 자체 패딩을 사용하기 위해 내부 컨테이너 배경색은 제거
                      color: Colors.transparent,
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 상세 내용이 펼쳐질 때 애니메이션 효과 추가
                  AnimatedCrossFade(
                    firstChild: Container(), // 접혔을 때의 위젯 (빈 컨테이너)
                    secondChild: Column( // 펼쳤을 때의 위젯
                      children: [
                        Divider(height: 1, indent: 16, endIndent: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          width: double.infinity, // 내용이 왼쪽 정렬되도록 너비 확장
                          child: Text(
                            notice['content'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}