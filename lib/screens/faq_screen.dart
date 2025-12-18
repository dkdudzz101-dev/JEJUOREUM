import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = const [
    {
      'question': '앱 사용은 어떻게 시작하나요?',
      'answer': '앱을 다운로드하여 설치한 후, 간단한 가입 절차를 거쳐 계정을 생성할 수 있습니다. 메인 화면의 지시에 따라 기능을 탐색해보세요.',
    },
    {
      'question': '비밀번호를 잊어버렸어요. 어떻게 재설정하나요?',
      'answer': '로그인 화면에서 "비밀번호 찾기"를 클릭하고 등록된 이메일 주소를 입력해주세요. 비밀번호 재설정 링크가 이메일로 전송됩니다.',
    },
    {
      'question': '개인 정보를 변경하고 싶어요. 어디서 할 수 있나요?',
      'answer': '설정 메뉴에서 프로필 정보를 업데이트할 수 있습니다.',
    },
    {
      'question': '공지사항은 어디서 확인하나요?',
      'answer': '메뉴에서 공지사항 항목을 선택하면 최신 공지를 확인할 수 있습니다.',
    },
    {
      'question': '문제가 발생했어요. 누구에게 문의해야 하나요?',
      'answer': '문의하기 메뉴를 통해 고객센터에 문의하실 수 있습니다.',
    },
    {
      'question': '앱이 자주 멈추거나 느려져요. 해결 방법이 있나요?',
      'answer': '앱을 최신 버전으로 업데이트하고, 캐시를 삭제해보세요. 문제가 계속되면 고객센터로 문의해주세요.',
    },
    {
      'question': '앱 알림 설정을 변경하고 싶어요.',
      'answer': '설정 메뉴에서 알림 설정을 변경할 수 있습니다.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '자주 묻는 질문',
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          final isExpanded = _expandedIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded ? AppTheme.primaryBrown : AppTheme.dividerGray,
                width: isExpanded ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq['question']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                              color: AppTheme.textBlack,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppTheme.textGray,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: AppTheme.dividerGray),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textBlack,
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
    );
  }
}
