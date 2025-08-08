import 'package:flutter/material.dart';
import 'dart:math'; // 반지름 계산을 위해 math 라이브러리 추가

// --- 새로 추가된 부분: 캐릭터 확대 애니메이션 화면 ---
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
      duration: const Duration(milliseconds: 1500), // 애니메이션 지속 시간
      vsync: this,
    );

    // 이미지가 0.1배에서 100배까지 커지는 애니메이션 설정
    _scaleAnimation = Tween<double>(begin: 0.1, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 애니메이션이 완료되면 MainScreen으로 이동
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushAndRemoveUntil(
          context,
          // 부드러운 전환을 위해 FadeTransition 사용
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
              (route) => false,
        );
      }
    });

    // 애니메이션 시작
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
      backgroundColor: Color(0xFFF5F1E8), // 기존 배경색과 동일하게 설정
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


void main() {
  runApp(MyApp());
}

// 전역 상태 관리를 위한 클래스
class AppState {
  static String? selectedCharacterImage;
  static String? selectedCharacterName;
  static String selectedLanguage = '영어'; // 기본값으로 영어 설정
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: InitialScreen(), // 초기 화면으로 변경
    );
  }
}

// 초기 화면 (첫 번째 이미지)
class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2),

              // 캐릭터 이미지들
              Container(
                padding: EdgeInsets.all(20),
                child: Image.asset(
                  'assets/all.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지 로딩 실패 시 대체 UI
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 100,
                        color: Colors.brown,
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 60),

              // 제목
              Text(
                '다국어 언어 학습',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),

              SizedBox(height: 8),

              Text(
                '다국어 능력 향상을 위한 앱',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.brown.shade600,
                ),
              ),

              Spacer(flex: 3),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '회원가입',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE8DCC6),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.brown.shade300),
                    ),
                  ),
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 18,
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

// 회원가입 화면 (두 번째 이미지)
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
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Center(
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),

              SizedBox(height: 40),

              // 이메일
              Text(
                '이메일 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: '예) abc@gmail.com',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 비밀번호
              Text(
                '비밀번호 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '영문, 숫자 조합 8~16자',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 비밀번호 확인
              Text(
                '비밀번호 확인 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: '비밀번호를 한 번 더 입력해주세요.',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 이름
              Text(
                '이름 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '예) 홍길동',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // 약관 동의
              _buildCheckboxRow('약관 약관에 모두 동의합니다.', _agreeToTerms, (value) {
                setState(() {
                  _agreeToTerms = value!;
                });
              }),

              _buildCheckboxRow('이용약관 및 정보 동의 자세히보기', _agreeToPrivacy, (value) {
                setState(() {
                  _agreeToPrivacy = value!;
                });
              }),

              _buildCheckboxRow('개인정보 처리방침 및 수집 동의 자세히보기', _agreeToMarketing, (value) {
                setState(() {
                  _agreeToMarketing = value!;
                });
              }),

              _buildCheckboxRow('만 14세 이상입니다 방침 동의', _agreeToAge, (value) {
                setState(() {
                  _agreeToAge = value!;
                });
              }),

              SizedBox(height: 40),

              // 완료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 초기 화면으로 이동
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => InitialScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String text, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.brown.shade400,
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
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

// 로그인 화면 (세 번째 이미지)
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
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Spacer(flex: 2),
            // 제목
            Text(
              '로그인',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),

            SizedBox(height: 60),

            // 이메일
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이메일 *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: '예) abc@gmail.com',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.brown.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.brown.shade300),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // 비밀번호
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '비밀번호 *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '영문, 숫자 조합 8~16자',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.brown.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.brown.shade300),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 레벨 테스트 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LevelTestScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE8DCC6),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
                child: Text(
                  '로그인',
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Spacer(flex: 3),
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

// 레벨 테스트 화면 (네 번째 이미지)
class LevelTestScreen extends StatefulWidget {
  @override
  _LevelTestScreenState createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends State<LevelTestScreen> {
  String? selectedAnswer;

  final List<String> options = [
    'No, he is',
    'No, I don\'t',
    'Yes, he isn\'t',
    'Yes, he is',
    'Yes, he do',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // 진행 표시
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '1 / 10',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),

              SizedBox(height: 40),

              // 질문 제목
              Text(
                '다음 질문에 알맞은\n답을 고르세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 40),

              // 질문
              Text(
                'Is he a teacher?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 40),

              // 선택지들
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: RadioListTile<String>(
                        title: Text(
                          options[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        value: options[index],
                        groupValue: selectedAnswer,
                        onChanged: (value) {
                          setState(() {
                            selectedAnswer = value;
                          });
                        },
                        activeColor: Colors.brown.shade400,
                        tileColor: Color(0xFFE8DCC6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.brown.shade300),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // 다음 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 캐릭터 선택 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CharacterSelectionScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '다음',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 캐릭터 선택 화면 (다섯 번째 이미지)
class CharacterSelectionScreen extends StatefulWidget {
  @override
  _CharacterSelectionScreenState createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  String? selectedCharacter;

  final List<Map<String, dynamic>> characters = [
    {'name': '여우', 'image': 'assets/fox.png', 'color': Colors.orange.shade200, 'icon': Icons.pets},
    {'name': '고양이', 'image': 'assets/cat.png', 'color': Colors.grey.shade400, 'icon': Icons.pets},
    {'name': '부엉이', 'image': 'assets/owl.png', 'color': Colors.orange.shade300, 'icon': Icons.visibility},
    {'name': '곰', 'image': 'assets/bear.png', 'color': Colors.brown.shade300, 'icon': Icons.face},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 40),

              // 제목
              Text(
                '마지막으로 공부를\n함께 하고싶은 캐릭터를\n선택하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 12),

              Text(
                '(추후에 변경 가능합니다)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              SizedBox(height: 60),

              // 캐릭터 선택지들
              Expanded(
                child: ListView.builder(
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: character['color'],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.asset(
                                  character['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      character['icon'],
                                      size: 30,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Text(
                              character['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        value: character['name'],
                        groupValue: selectedCharacter,
                        onChanged: (value) {
                          setState(() {
                            selectedCharacter = value;
                            // 선택된 캐릭터 정보를 전역 상태에 저장
                            final selectedCharacterData = characters.firstWhere(
                                  (char) => char['name'] == value,
                            );
                            AppState.selectedCharacterImage = selectedCharacterData['image'];
                            AppState.selectedCharacterName = selectedCharacterData['name'];
                          });
                        },
                        activeColor: Colors.brown.shade400,
                        tileColor: Color(0xFFE8DCC6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.brown.shade300),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // 완료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // 이 onPressed 부분을 수정합니다.
                  onPressed: () {
                    // 선택된 캐릭터가 있는지 확인
                    if (AppState.selectedCharacterImage != null) {
                      // 새로 만든 애니메이션 화면으로 이동
                      Navigator.pushAndRemoveUntil(
                        context,
                        // 화면 전환 시 기본 애니메이션이 없도록 PageRouteBuilder 사용
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              CharacterAnimationScreen(
                                imagePath: AppState.selectedCharacterImage!,
                              ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return child; // 아무 효과 없이 바로 전환
                          },
                        ),
                            (route) => false,
                      );
                    } else {
                      // 캐릭터가 선택되지 않았을 경우 사용자에게 알림
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('함께 공부할 캐릭터를 선택해주세요!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 메인 화면 (여섯 번째 이미지 - 홈 화면)
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
  }

  // 화면이 다시 보여질 때마다 상태 업데이트
  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {}); // UI 업데이트
  }

  Widget build(BuildContext context) {
    // 선택된 캐릭터 이미지가 있으면 사용, 없으면 기본 여우 이미지 사용
    String characterImage = AppState.selectedCharacterImage ?? 'assets/fox.png';
    String characterName = AppState.selectedCharacterName ?? '홍길동';

    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 프로필 섹션
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFE8DCC6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade300),
              ),
              child: Column(
                children: [
                  // 기존 프로필 행
                  Row(
                    children: [
                      // 캐릭터 이미지
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            characterImage,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.pets,
                                size: 45,
                                color: Colors.brown,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // 이름과 등급
                      Expanded(
                        child: Container(
                          height: 70, // 캐릭터 이미지와 동일한 높이
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // 중앙 정렬
                            children: [
                              Text(
                                characterName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Grade 1',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // 설정 버튼
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsScreen()),
                          );
                        },
                        child: Container(
                          width: 70, // 캐릭터 이미지와 동일한 크기
                          height: 70, // 캐릭터 이미지와 동일한 크기
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 32, // 아이콘 크기도 적절히 조정
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 새로 추가: 현재 공부중인 언어
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '현재 공부중인 언어: ${AppState.selectedLanguage}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 메인 메뉴 그리드 (Expanded로 감싸서 남은 공간 활용)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 35,
                  childAspectRatio: 1.1,
                  children: [
                    // 단어장 버튼 (이미지 사용) - 디버깅용
                    _buildMenuButton(
                      context,
                      title: '단어장',
                      icon: Icons.book,
                      // fallback용 아이콘
                      color: Colors.lightBlue,
                      imagePath: 'assets/vocabulary.png',
                      // 이미지 경로 지정
                      onTap: () {
                        // 디버깅: 이미지 로딩 확인
                        print('단어장 버튼 클릭됨');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              VocabularyScreen()),
                        );
                      },
                    ),

                    // 학습 버튼 (이미지로 변경하려면 imagePath 추가)
                    _buildMenuButton(
                      context,
                      title: '학습',
                      icon: Icons.school,
                      color: Colors.lightBlue,
                      imagePath: 'assets/study.png',
                      // 학습 이미지 추가
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              StudyScreen()),
                        );
                      },
                    ),

                    // 상황별 회화 버튼 (이미지로 변경하려면 imagePath 추가)
                    _buildMenuButton(
                      context,
                      title: '상황별 회화',
                      icon: Icons.chat_bubble_outline,
                      color: Colors.lightBlue,
                      imagePath: 'assets/conversation.png',
                      // 회화 이미지 추가
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              SituationScreen()),
                        );
                      },
                    ),

                    // 커뮤니티 버튼 (이미지 사용)
                    _buildMenuButton(
                      context,
                      title: '커뮤니티',
                      icon: Icons.forum,
                      // fallback용 아이콘
                      color: Colors.lightBlue,
                      imagePath: 'assets/community.png',
                      // 커뮤니티 이미지 사용
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              CommunityScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼 (고정 위치)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.brown.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NoticeScreen()),
                  );
                },
                child: Text(
                  '공지사항',
                  textAlign: TextAlign.center,
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
      ),
    );
  }

  // MainScreen 클래스 내부

  Widget _buildMenuButton(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE8DCC6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 이미지/아이콘 크기 증가 (60 -> 70)
            imagePath != null
                ? Container(
              width: 70,
              height: 70,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon,
                    size: 70,
                    color: Colors.brown.shade700,
                  );
                },
              ),
            )
                : Icon(
              icon,
              size: 70,
              color: Colors.brown.shade700,
            ),
            // 2. 이미지와 텍스트 사이 간격 증가 (12 -> 15)
            SizedBox(height: 15),
            // 3. 텍스트 크기 증가 (16 -> 17)
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 이하 나머지 화면들의 코드는 이전과 동일하게 유지됩니다.
// (VocabularyScreen, StudyScreen, SituationScreen, CommunityScreen 등...)

// 단어장 메인 화면 (수정됨)
class VocabularyScreen extends StatefulWidget {
  @override
  _VocabularyScreenState createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // 단어장 목록의 데이터 구조 변경
  final List<Map<String, dynamic>> _myWordbooks = [];

  final List<String> _pickTags = ['#중고교', '#토익토플', '#가장 많이', '#동물', '#음식', '#식물'];

  // 단어장 생성 함수
  void _createNewWordbook() async {
    final newWordbookName = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WordbookCreateScreen()),
    );

    if (newWordbookName != null && newWordbookName.isNotEmpty) {
      setState(() {
        _myWordbooks.add({'name': newWordbookName, 'words': []});
      });
    }
  }

  // 단어장 상세 화면으로 이동하고, 수정된 데이터를 받아오는 함수
  void _navigateToDetail(int index) async {
    final updatedWords = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordbookDetailScreen(wordbook: _myWordbooks[index]),
      ),
    );

    if (updatedWords != null && updatedWords is List<Map<String, dynamic>>) {
      setState(() {
        _myWordbooks[index]['words'] = updatedWords;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 카운트 계산
    int totalCount = 0;
    int memorizedCount = 0;
    _myWordbooks.forEach((wb) {
      totalCount += (wb['words'] as List).length;
      memorizedCount += (wb['words'] as List).where((w) => w['isMemorized'] == true).length;
    });
    int notMemorizedCount = totalCount - memorizedCount;

    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text('단어장', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.brown.shade700), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: Icon(Icons.menu, color: Colors.brown.shade700), onPressed: () {})],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusCard('전체', totalCount.toString(), Colors.blue.shade700),
              _buildStatusCard('미암기', notMemorizedCount.toString(), Colors.red.shade700),
              _buildStatusCard('암기', memorizedCount.toString(), Colors.green.shade700),
            ],
          ),
          SizedBox(height: 24),
          _buildSectionHeader('단어장 목록', onAdd: _createNewWordbook),
          SizedBox(height: 10),
          _myWordbooks.isEmpty
              ? Text('생성된 단어장이 없습니다.', style: TextStyle(color: Colors.grey.shade600))
              : Column(
            children: List.generate(_myWordbooks.length, (index) {
              return _buildWordbookItem(_myWordbooks[index], index);
            }),
          ),
          SizedBox(height: 30),
          _buildSectionHeader('Pick 단어장', showAddButton: false),
          Text('학습하고 싶은 단어장을 골라보세요', style: TextStyle(color: Colors.grey.shade700)),
          SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: _pickTags.map((tag) => Chip(label: Text(tag))).toList()),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Column(children: [Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)), SizedBox(height: 8), Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color))]))));
  Widget _buildSectionHeader(String title, {bool showAddButton = true, VoidCallback? onAdd}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), if (showAddButton) IconButton(icon: Icon(Icons.add, color: Colors.brown.shade600), onPressed: onAdd)]);
  Widget _buildWordbookItem(Map<String, dynamic> wordbook, int index) => ListTile(
    title: Text(wordbook['name']),
    subtitle: Text('단어 ${wordbook['words'].length}개'),
    leading: Icon(Icons.book, color: Colors.brown.shade400),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => _navigateToDetail(index),
  );
}

// --- 새로 추가된 부분: 단어 검색 및 추가 화면 ---
class WordSearchScreen extends StatefulWidget {
  @override
  _WordSearchScreenState createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _foundWord; // 찾은 단어의 정보를 저장

  // 임시 단어 데이터베이스 (실제 앱에서는 API나 로컬 DB를 사용)
  final Map<String, Map<String, dynamic>> _mockWordDB = {
    'reservation': {
      'word': 'reservation',
      'meanings': ['1. 명사: 예약', '2. 명사: 의구심/거리낌'],
      'pronunciation': '미국식 [ˌrezərˈveɪʃn]',
    },
    'flutter': {
      'word': 'flutter',
      'meanings': ['1. 동사: (빠르고 가볍게) 흔들(리)다', '2. 명사: 설렘, 두근거림'],
      'pronunciation': '미국식 [ˈflʌtər]',
    },
    'apple': {
      'word': 'apple',
      'meanings': ['1. 명사: 사과'],
      'pronunciation': '미국식 [ˈæpl]',
    },
    'code': {
      'word': 'code',
      'meanings': ['1. 명사: 암호, 부호', '2. 명사: 코드, 규범', '3. 동사: 코딩하다'],
      'pronunciation': '미국식 [koʊd]',
    }
  };

  void _searchWord() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _foundWord = _mockWordDB[query];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text('단어 검색', style: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 검색창
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '찾고 싶은 단어를 입력하세요',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchWord,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onSubmitted: (_) => _searchWord(),
              autofocus: true,
            ),
            SizedBox(height: 20),

            // 검색 결과
            if (_foundWord != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_foundWord!['word'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ...(_foundWord!['meanings'] as List<String>).map((m) => Text(m, style: TextStyle(fontSize: 16))),
                      SizedBox(height: 10),
                      Text(_foundWord!['pronunciation'], style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('이 단어 추가하기'),
                        onPressed: () {
                          // '추가' 버튼을 누르면 찾은 단어 정보를 이전 화면으로 돌려줌
                          Navigator.pop(context, _foundWord);
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(child: Text('검색 결과가 여기에 표시됩니다.')),
              ),
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

// 단어장 상세 화면 (수정됨)
class WordbookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> wordbook;

  const WordbookDetailScreen({Key? key, required this.wordbook}) : super(key: key);

  @override
  _WordbookDetailScreenState createState() => _WordbookDetailScreenState();
}

class _WordbookDetailScreenState extends State<WordbookDetailScreen> {
  late List<Map<String, dynamic>> _words; // 단어장 내 단어 목록

  @override
  void initState() {
    super.initState();
    // 부모 위젯으로부터 전달받은 단어 리스트로 초기화
    _words = List<Map<String, dynamic>>.from(widget.wordbook['words']);
  }

  // 단어 검색 화면으로 이동하고, 추가할 단어를 받아오는 함수
  void _navigateAndAddWord() async {
    final newWord = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WordSearchScreen()),
    );

    if (newWord != null && newWord is Map<String, dynamic>) {
      // 이미 추가된 단어인지 확인
      if (!_words.any((word) => word['word'] == newWord['word'])) {
        setState(() {
          // 'isMemorized' 상태를 추가하여 단어 목록에 저장
          newWord['isMemorized'] = false;
          _words.add(newWord);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 단어장에 있는 단어입니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope를 사용하여 뒤로가기 버튼을 눌렀을 때 수정된 단어 목록을 반환
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _words);
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF5F1E8),
        appBar: AppBar(
          title: Text(
            widget.wordbook['name'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700),
          ),
          backgroundColor: Color(0xFFF5F1E8),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
            onPressed: () => Navigator.pop(context, _words), // 여기도 수정
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _words.isEmpty
              ? Center(child: Text('단어장에 추가된 단어가 없습니다.\n아래 버튼으로 단어를 추가해보세요.'))
              : ListView.builder(
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final wordData = _words[index];
              bool isMemorized = wordData['isMemorized'];

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(wordData['word'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text((wordData['meanings'] as List<String>).first, overflow: TextOverflow.ellipsis),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 뜻 전체
                          ...?(wordData['meanings'] as List<String>?)?.map((m) => Text(m)),
                          SizedBox(height: 8),
                          Text(wordData['pronunciation'], style: TextStyle(fontStyle: FontStyle.italic)),
                          SizedBox(height: 16),
                          // 암기/미암기 버튼
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => wordData['isMemorized'] = false);
                                },
                                child: Text('미암기', style: TextStyle(fontSize: 13, color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isMemorized ? Colors.red.shade400 : Colors.grey,
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => wordData['isMemorized'] = true);
                                },
                                child: Text('암기', style: TextStyle(fontSize: 13, color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMemorized ? Colors.green.shade400 : Colors.grey,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateAndAddWord,
          label: Text('단어 추가'),
          icon: Icon(Icons.add),
        ),
      ),
    );
  }
}

class StudyScreen extends StatefulWidget {
  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  bool isStarred = false;
  bool isBookmarked = false;
  String? selectedAnswer; // 선택된 답변을 저장할 변수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '학습',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 질문 카드
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFE8DCC6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade300),
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

            // 버튼들
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
                      backgroundColor: Colors.orange.shade300,
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
                      backgroundColor: Colors.orange.shade300,
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

            // 별표와 북마크
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

            // 뜻 맞추기 섹션
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

            // 선택지들
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

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('다음 문제로 이동합니다.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade300,
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
          color: isSelected ? Colors.brown.shade300 : Color(0xFFE8DCC6),
          // 선택된 경우 색상 변경
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.brown.shade600 : Colors.brown.shade300,
            width: isSelected ? 2 : 1, // 선택된 경우 테두리 두껍게
          ),
        ),
        child: Row(
          children: [
            // 선택 표시 아이콘
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.brown.shade600 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.brown.shade600 : Colors.grey
                      .shade500,
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
            // 텍스트
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

// 상황별 회화 선택 화면 (이미지 버전)
class SituationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '상황별 회화',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            // 제목
            Text(
              '공부하고 싶은 상황을\n선택해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 40),

            // 상황 선택 그리드
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildSituationButton(
                    context,
                    situation: '공항',
                    imagePath: 'assets/airport.png',
                    fallbackIcon: Icons.flight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConversationScreen(situation: '공항'),
                        ),
                      );
                    },
                  ),
                  _buildSituationButton(
                    context,
                    situation: '식당',
                    imagePath: 'assets/restaurant.png',
                    fallbackIcon: Icons.restaurant,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConversationScreen(situation: '식당'),
                        ),
                      );
                    },
                  ),
                  _buildSituationButton(
                    context,
                    situation: '호텔',
                    imagePath: 'assets/hotel.png',
                    fallbackIcon: Icons.hotel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConversationScreen(situation: '호텔'),
                        ),
                      );
                    },
                  ),
                  _buildSituationButton(
                    context,
                    situation: '길거리',
                    imagePath: 'assets/road.png',
                    fallbackIcon: Icons.location_on,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConversationScreen(situation: '길거리'),
                        ),
                      );
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

  Widget _buildSituationButton(BuildContext context, {
    required String situation,
    String? imagePath,
    IconData? fallbackIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE8DCC6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 하늘색 배경(decoration) 제거 및 크기 조정
            imagePath != null
                ? Container(
              width: 100, // 이미지 크기 증가
              height: 100,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon ?? Icons.help,
                    size: 70,
                    color: Colors.brown.shade700, // 아이콘 색상 변경
                  );
                },
              ),
            )
                : Icon(
              fallbackIcon ?? Icons.help,
              size: 70, // 아이콘 크기 증가
              color: Colors.brown.shade700, // 아이콘 색상 변경
            ),
            SizedBox(height: 15), // 간격 조정
            Text(
              situation,
              style: TextStyle(
                fontSize: 17, // 폰트 크기 증가
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
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

  @override
  Widget build(BuildContext context) {
    // 선택된 캐릭터 이미지 가져오기
    String characterImage = AppState.selectedCharacterImage ?? 'assets/fox.png';

    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '회화 학습',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택한 상황 표시
            Text(
              '선택한 상황: $situation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 30),

            // 대화 목록
            Expanded(
              child: ListView(
                children: [
                  _buildConversationItem(
                    isQuestion: true,
                    characterImage: characterImage,
                  ),
                  _buildConversationItem(
                    isQuestion: false,
                    characterImage: characterImage,
                  ),
                  _buildConversationItem(
                    isQuestion: true,
                    characterImage: characterImage,
                  ),
                  _buildConversationItem(
                    isQuestion: false,
                    characterImage: characterImage,
                  ),
                  _buildConversationItem(
                    isQuestion: false,
                    characterImage: characterImage,
                  ),
                  _buildConversationItem(
                    isQuestion: true,
                    characterImage: characterImage,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('다음 단계로 이동합니다.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade400,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '다음',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem({
    required bool isQuestion,
    required String characterImage,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 아이콘 또는 빈 공간
          Container(
            width: 40,
            height: 40,
            child: isQuestion
                ? Container(
              decoration: BoxDecoration(
                color: Color(0xFF01A9F4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            )
                : null,
          ),

          SizedBox(width: 12),

          // 질문/답변 텍스트
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isQuestion ? Color(0xFFE3F2FD) : Color(0xFFE8DCC6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isQuestion ? Color(0xFF01A9F4) : Colors.brown.shade300,
                ),
              ),
              child: Text(
                isQuestion ? '질문' : '답변',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // 캐릭터 이미지 (답변일 때만)
          Container(
            width: 40,
            height: 40,
            child: !isQuestion
                ? Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  characterImage,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.pets,
                      size: 25,
                      color: Colors.brown,
                    );
                  },
                ),
              ),
            )
                : null,
          ),
        ],
      ),
    );
  }
}

// 커뮤니티 화면 (수정됨)
class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // 모든 게시글을 저장할 리스트
  List<Map<String, dynamic>> _allPosts = [];

  final List<String> _tabs = [
    '자유게시판',
    '질문게시판',
    '정보공유',
    '스터디모집',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 글 작성 화면으로 이동하고, 결과(새 글)를 받아오는 함수
  void _navigateAndCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostWriteScreen()),
    );

    // PostWriteScreen에서 글 데이터가 넘어왔다면
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _allPosts.add(result); // 전체 글 목록에 추가
      });
    }
  }

  // 각 탭에 맞는 게시글 목록을 보여주는 위젯
  Widget _buildPostList(String category) {
    // 현재 카테고리에 맞는 글들만 필터링
    final categoryPosts = _allPosts.where((post) => post['category'] == category).toList();

    if (categoryPosts.isEmpty) {
      return Center(
        child: Text(
          '아직 작성된 글이 없어요.\n첫 번째 글을 작성해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: categoryPosts.length,
      itemBuilder: (context, index) {
        final post = categoryPosts[index];
        // 태그가 리스트 형태이므로 join으로 합쳐서 문자열로 만듦
        final tags = (post['tags'] as List<String>?)?.join(' ') ?? '';

        return GestureDetector(
          onTap: () {
            // 상세 보기 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                if (tags.isNotEmpty)
                  Text(
                    tags,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '커뮤니티',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((String title) => Tab(text: title)).toList(),
          labelColor: Colors.brown.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.brown.shade600,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // 각 탭에 맞는 위젯을 생성
        children: _tabs.map((category) => _buildPostList(category)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndCreatePost,
        label: Text('글 작성'),
        icon: Icon(Icons.edit),
        backgroundColor: Colors.orange.shade400,
      ),
    );
  }
}

// 글 작성 화면 (수정됨)
class PostWriteScreen extends StatefulWidget {
  @override
  _PostWriteScreenState createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  TextEditingController _tagController = TextEditingController();
  String _selectedCategory = '게시판을 선택해주세요.';

  final List<String> categories = [
    '게시판을 선택해주세요.',
    '자유게시판',
    '질문게시판',
    '정보공유',
    '스터디모집',
  ];

  void _submitPost() {
    if (_titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty &&
        _selectedCategory != '게시판을 선택해주세요.') {

      // 태그를 # 기준으로 분리하고 공백 제거
      final tags = _tagController.text
          .split('#')
          .where((tag) => tag.trim().isNotEmpty)
          .map((tag) => '#${tag.trim()}')
          .toList();

      // 새로운 게시글 데이터를 Map 형태로 생성
      final newPost = {
        'category': _selectedCategory,
        'title': _titleController.text,
        'content': _contentController.text,
        'tags': tags, // 리스트 형태로 저장
      };

      // SnackBar를 표시하고, 결과값(newPost)과 함께 이전 화면으로 돌아감
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('글이 등록되었습니다.')),
      );
      Navigator.pop(context, newPost);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카테고리, 제목, 내용을 모두 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '글 작성',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _submitPost, // 등록 버튼 클릭 시 _submitPost 함수 호출
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '등록',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView( // 키보드가 올라올 때 화면이 깨지지 않도록
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 선택 드롭다운
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 16,
                            color: category == '게시판을 선택해주세요.'
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                    isExpanded: true,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 제목 입력
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '제목',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 내용 입력
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: '내용을 입력하세요.',
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 태그 입력
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '#태그입력 #태그2',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.brown.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}

// --- 게시글 상세 보기 화면 (라벨 추가) ---
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
        FocusScope.of(context).unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = (widget.post['tags'] as List<String>?)?.join(' ') ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          widget.post['category'],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView(
                children: [
                  SizedBox(height: 20),
                  // --- '제목' 라벨 추가 ---
                  Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.post['title'],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  if (tags.isNotEmpty)
                    Text(
                      tags,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  SizedBox(height: 24),
                  Divider(color: Colors.brown.shade200, thickness: 1),
                  SizedBox(height: 24),
                  // --- '내용' 라벨 추가 ---
                  Text(
                    '내용',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.post['content'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 30),

                  Divider(color: Colors.brown.shade300, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      '댓글 ${_comments.length}개',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  ),
                  ..._comments.map((comment) => Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.comment, size: 18, color: Colors.grey.shade600),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            comment,
                            style: TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _addComment(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.orange.shade600),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '피드백 작성',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력 섹션
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '제목',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 16),

            // 내용 입력 섹션
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '내용을 입력하세요.',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            // 등록 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.trim().isNotEmpty &&
                      _contentController.text.trim().isNotEmpty) {
                    // 피드백 제출 성공
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('피드백이 성공적으로 제출되었습니다.'),
                        backgroundColor: Colors.brown.shade400,
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    // 입력 값이 없을 때
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('제목과 내용을 모두 입력해주세요.'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade400,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  '등록',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
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
  bool studyNotification = true; // 공부 알림 기본값 켜짐
  bool reminderNotification = true; // 혜택(광고성) 알림 기본값 켜짐

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 공부 알림 설정
            _buildNotificationItem(
              imagePath: 'assets/study.png',
              fallbackIcon: Icons.school,
              title: '공부 알림',
              subtitle: '시작, 현황, 복습 알림',
              value: studyNotification,
              onChanged: (value) {
                setState(() {
                  studyNotification = value;
                });
              },
            ),

            SizedBox(height: 1), // 구분선 효과를 위한 작은 간격

            // 혜택(광고성) 알림 설정
            _buildNotificationItem(
              imagePath: 'assets/bookmark.png',
              fallbackIcon: Icons.bookmark,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 왼쪽 이미지/아이콘
          Container(
            width: 40,
            height: 40,
            child: Image.asset(
              imagePath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 이미지 로딩 실패 시 기본 아이콘 표시
                return Icon(
                  fallbackIcon,
                  size: 30,
                  color: Colors.blue,
                );
              },
            ),
          ),

          SizedBox(width: 16),

          // 중앙 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 오른쪽 토글 스위치
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.blue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade400,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
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
  // 각 질문의 펼침 상태를 관리
  Map<int, bool> expandedStates = {};

  // FAQ 데이터
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
    // 모든 질문을 접힌 상태로 초기화
    for (int i = 0; i < faqs.length; i++) {
      expandedStates[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '자주 찾는 질문',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 텍스트
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Color(0xFFE8DCC6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.brown.shade600,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '궁금한 질문을 선택하면 답변을 확인할 수 있습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FAQ 목록
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  final isExpanded = expandedStates[index] ?? false;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.brown.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 질문 헤더 (항상 보이는 부분)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              expandedStates[index] = !isExpanded;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Q 아이콘
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.brown.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Q',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 12),

                                // 질문 텍스트
                                Expanded(
                                  child: Text(
                                    faq['question'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                // 화살표 아이콘
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

                        // 답변 (펼쳤을 때만 보이는 부분)
                        if (isExpanded) ...[
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // A 아이콘
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 12),

                                // 답변 텍스트
                                Expanded(
                                  child: Text(
                                    faq['answer'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

// 즐겨찾기 화면 클래스 추가
class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // 각 단어의 펼침 상태를 관리
  Map<int, bool> expandedStates = {};

  // 즐겨찾기 단어 데이터
  final List<Map<String, dynamic>> favoriteWords = [
    {
      'word': 'reservation',
      'meanings': [
        '1. 명사: 예약',
        '2. 명사: (개념, 생각에 대한) 의구심/거리낌',
        '3. 명사: (미국에서) 인디언 보호 구역',
      ],
      'related': '동사: reserve, 유의어: book',
      'pronunciation': '발음기호: 미국식 [ rezər | veɪʃn ] 영국식 [ rezə | veɪʃn ]',
    },
    {
      'word': 'flight',
      'meanings': [
        '1. 명사: 비행, 항공편',
        '2. 명사: 도주, 탈출',
        '3. 명사: (계단의) 한 층',
      ],
      'related': '동사: fly, 유의어: journey',
      'pronunciation': '발음기호: 미국식 [ flaɪt ] 영국식 [ flaɪt ]',
    },
    {
      'word': 'teacher',
      'meanings': [
        '1. 명사: 선생님, 교사',
        '2. 명사: 강사',
      ],
      'related': '동사: teach, 유의어: instructor',
      'pronunciation': '발음기호: 미국식 [ tiːtʃər ] 영국식 [ tiːtʃə ]',
    },
  ];

  @override
  void initState() {
    super.initState();
    // 모든 단어를 접힌 상태로 초기화
    for (int i = 0; i < favoriteWords.length; i++) {
      expandedStates[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '즐겨찾기',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: favoriteWords.length,
          itemBuilder: (context, index) {
            final word = favoriteWords[index];
            final isExpanded = expandedStates[index] ?? false;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 단어 헤더 (항상 보이는 부분)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        expandedStates[index] = !isExpanded;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 별표 아이콘
                          Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 12),

                          // 단어
                          Expanded(
                            child: Text(
                              word['word'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          // 화살표 아이콘
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

                  // 상세 정보 (펼쳤을 때만 보이는 부분)
                  if (isExpanded) ...[
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 단어 뜻들
                          ...word['meanings'].map<Widget>((meaning) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              meaning,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          )).toList(),

                          SizedBox(height: 12),

                          // 관련 정보 (동사, 유의어)
                          Text(
                            word['related'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 8),

                          // 발음기호
                          Text(
                            word['pronunciation'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '환경설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 첫 번째 섹션
            _buildSettingButton(
              context,
              icon: Icons.notifications,
              title: '알림 설정',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                );
              },
            ),
            SizedBox(height: 16),

            _buildSettingButton(
              context,
              icon: Icons.language,
              title: '언어 선택',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
                );
              },
            ),
            SizedBox(height: 16),

            // 캐릭터 선택 버튼
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CharacterSelectionSettingsScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8DCC6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.brown.shade300),
                  ),
                  child: Row(
                    children: [
                      // 캐릭터 이미지 (기존 Icons.face 대신)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            AppState.selectedCharacterImage ?? 'assets/fox.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.pets,
                                size: 16,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '캐릭터 선택',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown.shade700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.brown.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _buildSettingButton(
              context,
              icon: Icons.star,
              title: '즐겨찾기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoritesScreen()),
                );
              },
            ),
            SizedBox(height: 32),

            // 두 번째 섹션
            _buildSettingButton(
              context,
              icon: Icons.search,
              title: '자주 찾는 질문',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen()),
                );
              },
            ),
            SizedBox(height: 16),

            _buildSettingButton(
              context,
              icon: Icons.feedback,
              title: '피드백 작성',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen()),
                );
              },
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFFE8DCC6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.brown.shade700,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown.shade700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.brown.shade500,
            ),
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
    {
      'name': '영어',
      'flag': '🇺🇸',
      'color': Color(0xFFE8DCC6),
    },
    {
      'name': '일본어',
      'flag': '🇯🇵',
      'color': Color(0xFFE8DCC6),
    },
    {
      'name': '중국어',
      'flag': '🇨🇳',
      'color': Color(0xFFE8DCC6),
    },
    {
      'name': '불어',
      'flag': '🇫🇷',
      'color': Color(0xFFE8DCC6),
    },
  ];

  @override
  void initState() {
    super.initState();
    // 현재 선택된 언어를 초기값으로 설정
    selectedLanguage = AppState.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '언어 선택',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),

            // 제목
            Text(
              '공부하고 싶은 언어를\n선택하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 40),

            // 언어 선택지들
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final isSelected = selectedLanguage == language['name'];

                  return Container(
                    margin: EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLanguage = language['name'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: language['color'],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.orange.shade600 : Colors.grey.shade400,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 국기 (이모지로 대체)
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  language['flag'],
                                  style: TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),

                            // 라디오 버튼
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
                                  width: 2,
                                ),
                                color: isSelected ? Colors.orange.shade600 : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                                  : null,
                            ),

                            SizedBox(width: 20),

                            // 언어명
                            Expanded(
                              child: Text(
                                language['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedLanguage != null ? () {
                  // 선택된 언어를 AppState에 저장
                  AppState.selectedLanguage = selectedLanguage!;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${selectedLanguage}이(가) 선택되었습니다!'),
                      backgroundColor: Colors.orange.shade600,
                    ),
                  );

                  // 홈 화면으로 돌아가면서 새로고침
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                        (route) => false,
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedLanguage != null
                      ? Colors.orange.shade600
                      : Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '완료',
                  style: TextStyle(
                    color: selectedLanguage != null ? Colors.white : Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    {
      'name': '여우',
      'image': 'assets/fox.png',
      'color': Colors.orange.shade200,
      'icon': Icons.pets,
    },
    {
      'name': '고양이',
      'image': 'assets/cat.png',
      'color': Colors.grey.shade400,
      'icon': Icons.pets,
    },
    {
      'name': '부엉이',
      'image': 'assets/owl.png',
      'color': Colors.orange.shade300,
      'icon': Icons.visibility,
    },
    {
      'name': '곰',
      'image': 'assets/bear.png',
      'color': Colors.brown.shade300,
      'icon': Icons.face,
    },
  ];

  @override
  void initState() {
    super.initState();
    // 현재 선택된 캐릭터를 초기값으로 설정
    selectedCharacter = AppState.selectedCharacterName ?? '여우';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '캐릭터 선택',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),

            // 제목
            Text(
              '변경하고 싶은 캐릭터를\n선택하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 30),

            // 캐릭터 선택지들
            Expanded(
              child: ListView.builder(
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final character = characters[index];
                  final isSelected = selectedCharacter == character['name'];

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCharacter = character['name'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8DCC6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.orange.shade600 : Colors.brown.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 캐릭터 이미지
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: character['color'],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.asset(
                                  character['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      character['icon'],
                                      size: 30,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),

                            SizedBox(width: 12),

                            // 라디오 버튼
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
                                  width: 2,
                                ),
                                color: isSelected ? Colors.orange.shade600 : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                                  : null,
                            ),

                            SizedBox(width: 16),

                            // 캐릭터 이름
                            Expanded(
                              child: Text(
                                character['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedCharacter != null ? () {
                  // 선택된 캐릭터 정보를 전역 상태에 저장
                  final selectedCharacterData = characters.firstWhere(
                        (char) => char['name'] == selectedCharacter,
                  );

                  AppState.selectedCharacterImage = selectedCharacterData['image'];
                  AppState.selectedCharacterName = selectedCharacterData['name'];

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('캐릭터가 ${selectedCharacter}(으)로 변경되었습니다!'),
                      backgroundColor: Colors.orange.shade600,
                    ),
                  );

                  // 홈 화면으로 돌아가면서 새로고침
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                        (route) => false,
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCharacter != null
                      ? Colors.orange.shade600
                      : Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '완료',
                  style: TextStyle(
                    color: selectedCharacter != null ? Colors.white : Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 공지사항 화면 클래스 (기존 NoticeScreen 대체)
class NoticeScreen extends StatefulWidget {
  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  // 각 공지사항의 펼침 상태를 관리
  Map<int, bool> expandedStates = {};

  // 공지사항 데이터
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
      'title': '새로운 기능 업데이트 안내',
      'content': '''이번 업데이트에서 추가된 새로운 기능들을 안내드립니다.

1. 발음 연습 기능 강화
2. 개인화된 학습 추천 시스템
3. 커뮤니티 기능 개선
4. 알림 설정 세분화

더 자세한 내용은 앱 내에서 확인하실 수 있습니다.''',
    },
    {
      'title': '서비스 이용약관 변경 안내',
      'content': '''서비스 이용약관이 일부 변경되었습니다.

주요 변경사항:
- 개인정보 처리방침 개선
- 서비스 이용 규칙 명확화
- 사용자 권리 강화

변경된 약관은 2024년 1월 1일부터 적용됩니다.
자세한 내용은 설정 > 이용약관에서 확인하실 수 있습니다.''',
    },
    {
      'title': '정기 점검 안내',
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
    // 모든 공지사항을 접힌 상태로 초기화
    for (int i = 0; i < notices.length; i++) {
      expandedStates[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '공지사항',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade700,
          ),
        ),
        backgroundColor: Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            final isExpanded = expandedStates[index] ?? false;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 공지사항 헤더 (항상 보이는 부분)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        expandedStates[index] = !isExpanded;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 제목
                          Expanded(
                            child: Text(
                              notice['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // 화살표 아이콘
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

                  // 상세 내용 (펼쳤을 때만 보이는 부분)
                  if (isExpanded) ...[
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        notice['content'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}