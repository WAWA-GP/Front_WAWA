import 'package:flutter/material.dart';

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
                  onPressed: () {
                    // 홈 화면으로 이동
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
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
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
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
                            MaterialPageRoute(builder: (context) => SettingsScreen()),
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
                      icon: Icons.book, // fallback용 아이콘
                      color: Colors.lightBlue,
                      imagePath: 'assets/vocabulary.png', // 이미지 경로 지정
                      onTap: () {
                        // 디버깅: 이미지 로딩 확인
                        print('단어장 버튼 클릭됨');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VocabularyScreen()),
                        );
                      },
                    ),

                    // 학습 버튼 (이미지로 변경하려면 imagePath 추가)
                    _buildMenuButton(
                      context,
                      title: '학습',
                      icon: Icons.school,
                      color: Colors.lightBlue,
                      imagePath: 'assets/study.png', // 학습 이미지 추가
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudyScreen()),
                        );
                      },
                    ),

                    // 상황별 회화 버튼 (이미지로 변경하려면 imagePath 추가)
                    _buildMenuButton(
                      context,
                      title: '상황별 회화',
                      icon: Icons.chat_bubble_outline,
                      color: Colors.lightBlue,
                      imagePath: 'assets/conversation.png', // 회화 이미지 추가
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SituationScreen()),
                        );
                      },
                    ),

                    // 커뮤니티 버튼 (이미지 사용)
                    _buildMenuButton(
                      context,
                      title: '커뮤니티',
                      icon: Icons.forum, // fallback용 아이콘
                      color: Colors.lightBlue,
                      imagePath: 'assets/community.png', // 커뮤니티 이미지 사용
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CommunityScreen()),
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

  Widget _buildMenuButton(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? imagePath, // 이미지 경로 추가 (선택적)
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
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: imagePath != null
                  ? Container(
                width: 40,
                height: 40,
                child: Image.asset(
                  imagePath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain, // 이미지 비율 유지하면서 컨테이너에 맞춤
                  // color 속성 제거 - 배경 투명도 유지
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지 로딩 실패 시 기본 아이콘으로 대체
                    return Icon(
                      icon, // 전달받은 icon 사용
                      size: 50, // 아이콘 크기도 증가
                      color: Colors.white,
                    );
                  },
                ),
              )
                  : Icon(
                icon, // 이미지가 없으면 아이콘 사용
                size: 50, // 아이콘 크기 증가
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
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

// 각 메뉴별 페이지들
class VocabularyScreen extends StatefulWidget {
  @override
  _VocabularyScreenState createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  TextEditingController _searchController = TextEditingController();
  bool isStarred = false;
  bool isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(
          '단어장',
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
            // 검색창
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'reservation',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // 단어 정보
            Row(
              children: [
                Text(
                  'reservation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
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
            SizedBox(height: 16),

            // 단어 뜻
            Text(
              '1. 명사: 예약',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 4),
            Text(
              '2. 명사: (개념, 생각에 대한) 의구심/거리낌',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 4),
            Text(
              '3. 명사: (미국에서) 인디언 보호 구역',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 16),

            // 동사, 유의어
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(text: '동사: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'reserve, '),
                  TextSpan(text: '유의어: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'book'),
                ],
              ),
            ),
            SizedBox(height: 8),

            // 발음기호
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(text: '발음기호: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '미국식 [ '),
                  TextSpan(text: 'rézər', style: TextStyle(fontStyle: FontStyle.italic)),
                  TextSpan(text: ' | '),
                  TextSpan(text: 'véɪʃn', style: TextStyle(fontStyle: FontStyle.italic)),
                  TextSpan(text: ' ] 영국식 [ '),
                  TextSpan(text: 'rézə', style: TextStyle(fontStyle: FontStyle.italic)),
                  TextSpan(text: ' | '),
                  TextSpan(text: 'veɪʃn', style: TextStyle(fontStyle: FontStyle.italic)),
                  TextSpan(text: ' ]'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                          builder: (context) => ConversationScreen(situation: '공항'),
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
                          builder: (context) => ConversationScreen(situation: '식당'),
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
                          builder: (context) => ConversationScreen(situation: '호텔'),
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
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: imagePath != null
                  ? Container(
                width: 60,
                height: 60,
                child: Image.asset(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지 로딩 실패 시 기본 아이콘으로 대체
                    return Icon(
                      fallbackIcon ?? Icons.help,
                      size: 32,
                      color: Colors.white,
                    );
                  },
                ),
              )
                  : Icon(
                fallbackIcon ?? Icons.help,
                size: 32,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              situation,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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

class CommunityScreen extends StatelessWidget {
  final List<Map<String, String>> posts = [
    {'title': '글 제목', 'content': '글 내용'},
    {'title': '글 제목', 'content': '글 내용'},
    {'title': '글 제목', 'content': '글 내용'},
    {'title': '글 제목', 'content': '글 내용'},
    {'title': '글 제목', 'content': '글 내용'},
  ];

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
      ),
      body: Stack(
        children: [
          // 게시글 목록
          ListView.builder(
            padding: EdgeInsets.only(bottom: 80), // 글 작성 버튼을 위한 여백
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      posts[index]['title']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      posts[index]['content']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 글 작성 버튼
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostWriteScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '글 작성',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

// 글 작성 화면
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
          Container(
            margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _contentController.text.isNotEmpty &&
                    _selectedCategory != '게시판을 선택해주세요.') {
                  // 글 작성 완료 처리
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('글이 등록되었습니다.')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('모든 항목을 입력해주세요.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
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
            Text(
              '제목',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown.shade300),
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            SizedBox(height: 16),

            // 내용 입력
            Text(
              '내용을 입력하세요.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown.shade300),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // 하단 태그 입력 섹션
            Text(
              '#태그 입력 (#으로 구분, 최대 10개)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown.shade300),
              ),
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            SizedBox(height: 24),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty &&
                      _contentController.text.isNotEmpty &&
                      _selectedCategory != '게시판을 선택해주세요.') {
                    // 글 작성 완료 처리
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('글이 등록되었습니다.')),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('모든 항목을 입력해주세요.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
          ],
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