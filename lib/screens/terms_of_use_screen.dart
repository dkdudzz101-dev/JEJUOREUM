import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이용약관',
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '제1조 (목적)',
              '이 약관은 제주 오름 앱 (이하 "회사")이 제공하는 모든 서비스(이하 "서비스")의 이용과 관련된 기본 원칙과 사항을 규정함을 목적으로 합니다.',
            ),
            _buildSection(
              '제2조 (정의)',
              '''1. "서비스"라 함은 회원이 단말기(PC, 휴대형 단말기 등의 각종 유무선 장치를 포함)를 이용하여 이용할 수 있는 회사가 제공하는 제반 서비스를 의미합니다.

2. "회원"이라 함은 회사의 서비스에 접속하여 이 약관에 따라 회사와 이용계약을 체결하고 회사가 제공하는 서비스를 이용하는 고객을 말합니다.

3. 이 약관에서 정의하지 않은 용어는 일반적인 관례에 따릅니다.''',
            ),
            _buildSection(
              '제3조 (약관의 게시와 개정)',
              '''1. 회사는 이 약관의 내용을 회원이 쉽게 알 수 있도록 서비스 화면에 게시합니다.

2. 회사는 "약관의 규제에 관한 법률", "정보통신망 이용촉진 및 정보보호 등에 관한 법률(이하 "정보통신망법")" 등 관련법을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.

3. 회사는 약관을 개정할 경우에는 적용일자 및 개정사유를 명시하여 현행약관과 함께 제1항의 방식에 따라 그 개정약관의 적용일자 7일 전부터 적용일자 전일까지 공지합니다. 다만, 회원에게 불리한 내용으로 약관을 변경하는 경우에는 최소한 30일 이상의 사전 유예기간을 두고 공지합니다.

4. 회사가 전항에 따라 개정약관을 공지 또는 통지하면서 회원에게 30일 기간 내에 의사표시를 하지 않으면 의사표시가 표명된 것으로 본다는 뜻을 명확하게 공지 또는 통지하였음에도 회원이 명시적으로 거부의사 표시를 하지 아니한 경우 회원이 개정약관에 동의한 것으로 봅니다.''',
            ),
            _buildSection(
              '제4조 (서비스의 제공)',
              '''1. 회사는 회원에게 다음과 같은 서비스를 제공합니다:
   • 오름 정보 제공 서비스
   • 기타 회사가 추가 개발하거나 다른 회사와의 제휴 계약 등을 통해 회원에게 제공하는 일체의 서비스

2. 서비스 이용시간은 연중무휴 1일 24시간을 원칙으로 합니다.

3. 회사는 서비스를 일정범위로 분할하여 각 범위별로 이용가능시간을 별도로 지정할 수 있습니다.''',
            ),
            _buildSection(
              '제5조 (개인정보 보호 의무)',
              '''1. 회사는 "정보통신망 이용촉진 및 정보보호에 관한 법률" 등 관계 법령이 정하는 바에 따라 회원의 개인정보를 보호하기 위해 노력합니다.

2. 개인정보의 보호 및 사용에 대해서는 관련법 및 회사의 개인정보처리방침이 적용됩니다. 다만, 회사의 공식 사이트 이외의 링크된 사이트에서는 회사의 개인정보처리방침이 적용되지 않습니다.''',
            ),
            _buildSection(
              '제6조 (회원의 의무)',
              '''1. 회원은 다음 행위를 하여서는 안 됩니다:
   • 신청 또는 변경 시 허위내용 등록
   • 타인의 정보 도용
   • 회사가 게시한 정보의 변경
   • 기타 관계 법령 또는 회사가 정한 제반 규정에 위반하는 행위

2. 회원은 본 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항, 회사가 통지하는 사항 등을 확인하고 준수할 의무가 있습니다.''',
            ),
            _buildSection(
              '제7조 (저작권의 귀속 및 이용제한)',
              '''1. 회사가 작성한 저작물에 대한 저작권 기타 지적재산권은 회사에 귀속합니다.

2. 회원은 서비스를 이용함으로써 얻은 정보 중 회사에게 지적재산권이 귀속된 정보를 회사의 사전 승낙없이 복제, 송신, 출판, 배포, 방송 기타 방법에 의하여 영리목적으로 이용하거나 제3자에게 이용하게 하여서는 안됩니다.''',
            ),
            _buildSection(
              '제8조 (분쟁해결)',
              '''1. 서비스 이용과 관련하여 회원에게 발생한 문제에 대한 이의신청은 고객센터를 통해 접수할 수 있습니다.

2. 서비스 이용 중 발생한 손해 등에 대한 책임은 관련 법령에 따릅니다.''',
            ),
            const SizedBox(height: 20),
            const Text(
              '부칙 (이 약관은 2023년 1월 1일부터 적용됩니다.)',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textBlack,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
