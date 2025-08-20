import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

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
  await Dictionary.load();
  runApp(MyApp());
}

class AppState {
  static String selectedCharacterImage = 'assets/fox.png';
  static String selectedCharacterName = '여우';
  static String selectedLanguage = '영어';
  static final List<WordData> favoriteWords = [];
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
        cardTheme: CardTheme(
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
        tabBarTheme: const TabBarTheme(
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
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  bool _agreeToMarketing = false;
  bool _agreeToAge = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(label: '이메일 *', controller: _emailController, hint: '예) abc@gmail.com'),
              SizedBox(height: 16),
              _buildPasswordField(label: '비밀번호 *', controller: _passwordController, isObscured: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
              SizedBox(height: 16),
              _buildPasswordField(label: '비밀번호 확인 *', controller: _confirmPasswordController, isObscured: _obscureConfirmPassword,
                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
              SizedBox(height: 16),
              _buildTextField(label: '이름 *', controller: _nameController, hint: '예) 홍길동'),
              SizedBox(height: 24),
              _buildCheckboxRow('약관 약관에 모두 동의합니다.', _agreeToTerms, (value) => setState(() => _agreeToTerms = value!)),
              _buildCheckboxRow('이용약관 및 정보 동의 자세히보기', _agreeToPrivacy, (value) => setState(() => _agreeToPrivacy = value!)),
              _buildCheckboxRow('개인정보 처리방침 및 수집 동의 자세히보기', _agreeToMarketing, (value) => setState(() => _agreeToMarketing = value!)),
              _buildCheckboxRow('만 14세 이상입니다 방침 동의', _agreeToAge, (value) => setState(() => _agreeToAge = value!)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => InitialScreen()),
                        (route) => false,
                  );
                },
                child: Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        Checkbox(value: value, onChanged: onChanged), // 스타일은 Theme에서 적용됨
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
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // AppBar를 추가하여 뒤로가기 버튼 자동 생성
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Spacer(flex: 1),
            Text(
              '로그인',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 60),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LevelTestScreen()),
                );
              },
              child: Text('로그인'),
            ),
            Spacer(flex: 2),
          ],
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

// 레벨 테스트 화면
class LevelTestScreen extends StatefulWidget {
  @override
  _LevelTestScreenState createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends State<LevelTestScreen> {
  String? selectedAnswer;
  final List<String> options = ['No, he is', 'No, I don\'t', 'Yes, he isn\'t', 'Yes, he is', 'Yes, he do'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('레벨 테스트')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text('1 / 10', style: TextStyle(fontSize: 16, color: Colors.black54)),
              ),
              SizedBox(height: 40),
              Text('다음 질문에 알맞은\n답을 고르세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              Text('Is he a teacher?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return Card( // Card로 감싸서 테마 적용
                      margin: EdgeInsets.only(bottom: 12),
                      child: RadioListTile<String>(
                        title: Text(options[index], style: TextStyle(fontSize: 16)),
                        value: options[index],
                        groupValue: selectedAnswer,
                        onChanged: (value) => setState(() => selectedAnswer = value),
                        activeColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CharacterSelectionScreen()),
                  );
                },
                child: Text('다음'),
              ),
            ],
          ),
        ),
      ),
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
  late TabController _communityTabController;
  final List<String> _communityTabs = ['자유게시판', '질문게시판', '정보공유', '스터디모집'];
  static const List<String> _titles = ['나', '단어장', '학습', '상황별 회화', '커뮤니티'];

  @override
  void initState() {
    super.initState();
    _communityTabController = TabController(length: _communityTabs.length, vsync: this);
  }

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
    final List<Widget> _pages = <Widget>[
      HomePageContent(),
      VocabularyScreen(),
      StudyScreen(),
      SituationScreen(),
      CommunityScreen(tabController: _communityTabController),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: _selectedIndex > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _onItemTapped(0))
            : IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
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
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin 사용을 위해 반드시 호출
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

  // ▼▼▼ [수정] 이 메서드가 변경되었습니다. ▼▼▼
  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. 캐릭터 이미지와 텍스트를 Column으로 묶음
            Column(
              children: [
                // 캐릭터 이름 표시
                Text(
                  AppState.selectedCharacterName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // 캐릭터 이미지
                Image.asset(
                  AppState.selectedCharacterImage,
                  width: 100,
                  height: 100,
                  errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 100),
                ),
                SizedBox(height: 12),
                // 2. 현재 학습 언어 텍스트 추가
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontFamily: 'Pretendard', // 앱 기본 폰트 지정
                    ),
                    children: <TextSpan>[
                      TextSpan(text: '학습 언어: '),
                      TextSpan(
                        text: AppState.selectedLanguage, // AppState에서 선택된 언어 가져오기
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green, // 테마 색상으로 강조
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 오른쪽 학습 진행도 부분은 그대로 유지됩니다.
            Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: const [
                      CircularProgressIndicator(value: 0.0, strokeWidth: 8, backgroundColor: Color(0xFFE0E0E0), valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
                      Center(child: Text('0%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('어휘 학습', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Text('하루 목표: ', style: TextStyle(color: Colors.grey)),
                    Text('20개', style: TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_drop_down, color: Colors.grey)
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // 나머지 헬퍼 메서드들은 변경점이 없습니다.
  Widget _buildTodayLearningButton() {
    return ElevatedButton.icon(
      onPressed: () {},
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('출석 체크', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildDayCircle('월'),
                  _buildDayCircle('화', isChecked: true),
                  _buildDayCircle('수'),
                  _buildDayCircle('목'),
                  _buildDayCircle('금'),
                  _buildDayCircle('토'),
                  _buildDayCircle('일')
                ],
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCircle(String day, {bool isChecked = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: isChecked ? Colors.lightBlueAccent : Colors.grey.shade200, shape: BoxShape.circle),
      child: Center(child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 18) : Text(day, style: const TextStyle(color: Colors.grey))),
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

  bool isStarred = false;
  bool isBookmarked = false;
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin 사용을 위해 반드시 호출

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              children: [
                Text(
                  'Can I book a flight\nto LA now?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Icon(
                  Icons.volume_up,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('내 발음 녹음을 선택했습니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '내 발음 녹음',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('조회해서 듣기를 선택했습니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '조회해서 듣기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isStarred = !isStarred;
                  });
                },
                child: Icon(
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred ? Colors.orange : Colors.grey,
                ),
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isBookmarked = !isBookmarked;
                  });
                },
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '뜻 맞추기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildAnswerOption('지금 LA로 가는 항공편 예약할 수 있나요'),
                _buildAnswerOption('나는 LA에서 비행기를 탈 수 있어요'),
                _buildAnswerOption('나는 지금 LA에 도착했어요'),
                _buildAnswerOption('나는 LA로 가는 항공편을 예약했어요'),
                _buildAnswerOption('지금 LA행 비행기가 출발했어요'),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('다음 문제로 이동합니다.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String text) {
    bool isSelected = selectedAnswer == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAnswer = text;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.brown.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.black : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade500,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin 사용을 위해 반드시 호출
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 20),
          Text(
            '공부하고 싶은 상황을\n선택해주세요',
            textAlign: TextAlign.center,
            // ▼▼▼ [수정] 글자 스타일을 앱 테마에 맞게 조정 ▼▼▼
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSituationButton(
                  context,
                  situation: '공항',
                  imagePath: 'assets/airport.png',
                  fallbackIcon: Icons.flight_takeoff,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(situation: '공항'),
                      ),
                    );
                  },
                ),
                _buildSituationButton(
                  context,
                  situation: '식당',
                  imagePath: 'assets/restaurant.png',
                  fallbackIcon: Icons.restaurant_menu_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(situation: '식당'),
                      ),
                    );
                  },
                ),
                _buildSituationButton(
                  context,
                  situation: '호텔',
                  imagePath: 'assets/hotel.png',
                  fallbackIcon: Icons.hotel_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(situation: '호텔'),
                      ),
                    );
                  },
                ),
                _buildSituationButton(
                  context,
                  situation: '길거리',
                  imagePath: 'assets/road.png',
                  fallbackIcon: Icons.signpost_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(situation: '길거리'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ▼▼▼ [수정] 버튼 위젯 전체를 Card와 InkWell을 사용하여 개선 ▼▼▼
  Widget _buildSituationButton(BuildContext context, {
    required String situation,
    String? imagePath,
    IconData? fallbackIcon,
    required VoidCallback onTap,
  }) {
    // Card 위젯을 사용하여 앱의 다른 카드들과 디자인 통일
    return Card(
      clipBehavior: Clip.antiAlias, // InkWell 효과가 카드 모양에 맞게 적용됨
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imagePath != null
                ? Image.asset(
              imagePath,
              width: 80, // 이미지 크기 조정
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  fallbackIcon ?? Icons.help_outline,
                  size: 60,
                  // 아이콘 색상을 테마 색상으로 변경
                  color: Colors.green,
                );
              },
            )
                : Icon(
              fallbackIcon ?? Icons.help_outline,
              size: 60,
              color: Colors.green,
            ),
            SizedBox(height: 12),
            Text(
              situation,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                // 텍스트 색상을 검은색 계열로 변경
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 회화 학습 화면 (세 번째 이미지)
class ConversationScreen extends StatelessWidget {
  final String situation;

  ConversationScreen({required this.situation});

  // 대화 내용을 담을 샘플 데이터
  final List<Map<String, dynamic>> conversationData = [
    {'isQuestion': true, 'text': '실례합니다, 체크인 카운터는 어디에 있나요?'},
    {'isQuestion': false, 'text': '저쪽입니다. 입구 바로 옆에 있어요.'},
    {'isQuestion': true, 'text': '감사합니다. 그리고 제 짐을 부치고 싶어요.'},
    {'isQuestion': false, 'text': '네, 여권과 항공권을 보여주시겠어요?'},
    {'isQuestion': true, 'text': '여기 있습니다.'},
  ];

  @override
  Widget build(BuildContext context) {
    String characterImage = AppState.selectedCharacterImage ?? 'assets/fox.png';

    // ▼▼▼ [수정] 배경색을 앱 테마와 통일 ▼▼▼
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text('회화 학습'),
        // ▼▼▼ [수정] AppBar 배경색도 통일 ▼▼▼
        backgroundColor: Color(0xFFF3F4F8),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // ▼▼▼ [수정] 상황 안내 UI 개선 ▼▼▼
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '#$situation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            // 대화 목록
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 16),
                itemCount: conversationData.length,
                itemBuilder: (context, index) {
                  final message = conversationData[index];
                  return _buildConversationItem(
                    isQuestion: message['isQuestion'],
                    text: message['text'],
                    characterImage: characterImage,
                  );
                },
              ),
            ),
            // ▼▼▼ [수정] 버튼 스타일 및 색상 변경 ▼▼▼
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('다음 단계로 이동합니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600, // 초록색 계열로 변경
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '다음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ▼▼▼ [수정] 실제 대화창처럼 보이도록 위젯 전체 재구성 ▼▼▼
  Widget _buildConversationItem({
    required bool isQuestion,
    required String text,
    required String characterImage,
  }) {
    // isQuestion(AI 질문)이면 왼쪽, 아니면(캐릭터 답변) 오른쪽 정렬
    final alignment = isQuestion ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bubbleColor = isQuestion ? Colors.green.shade50 : Colors.white;
    final textColor = Colors.black87;

    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: 280), // 말풍선 최대 너비
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: isQuestion ? Radius.circular(4) : Radius.circular(20),
          bottomRight: isQuestion ? Radius.circular(20) : Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: textColor, height: 1.4),
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (isQuestion)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 24),
                SizedBox(width: 8),
                bubble,
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                bubble,
                SizedBox(width: 8),
                // CircleAvatar로 캐릭터 이미지 표시
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: AssetImage(characterImage),
                ),
              ],
            ),
        ],
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