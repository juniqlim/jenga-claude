# Next Step

## 추구미 (추구하는 미래상)

단축키만으로 대화 블록을 자유롭게 조작하는 앱. 마우스 없이 키보드만으로 대화 컨텍스트를 젠가처럼 쌓고, 빼고, 재배치한다.

## 현재 상태

1~4단계 기본 구현 완료. claude --print와 통신하는 macOS 채팅 앱이 동작함.

**동작하는 것:**
- NDJSON 파싱 (단위 테스트 통과)
- claude CLI 프로세스 스폰 및 양방향 통신
- 스트리밍 응답 실시간 표시
- 메시지 히스토리 UI
- 대화 컨텍스트 유지 (히스토리를 새 세션에 포함하여 전송)

**깨져있던 것 (수정 완료):**
- ClaudeProcessTests: stateless 아키텍처에 맞게 갱신됨

## 방금 완료한 작업

텍스트 드래그 선택 구현 (NSTextView 전환):
- `MessageAttributedStringBuilder`: [Message] + streamingText → NSAttributedString 변환
- `ConversationTextView`: NSScrollView + NSTextView를 감싸는 NSViewRepresentable
- `ChatView`: ScrollView+LazyVStack+MessageView → ConversationTextView로 교체
- `MessageView` 삭제 (더 이상 사용하지 않음)
- 여러 메시지에 걸쳐 드래그 선택 가능해짐

## 다음 단계 후보

### A. 삭제 모드 토글 (체크박스)
현재 ⌘1~9 단축키는 동작하지만 시각적 표시가 없음. 모드 토글 방식으로 해결:
- 평소: NSTextView로 드래그 선택
- 삭제 모드 진입 (단축키): 기존 방식(개별 메시지 + 체크박스)으로 전환
- ⌘1~9로 체크박스 토글, 체크된 메시지 일괄 삭제

### B. React Ink(터미널) 버전
터미널 UI가 추구미에 더 맞을 수 있음. 버튼 없이 단축키만으로 조작. 텍스트 선택도 터미널 네이티브로 해결.
- 대화 길어질 때: `d` 키로 삭제 모드 진입 → 화살표로 블록 선택 → Enter 삭제 → Esc 복귀 (vim 스타일)
- 하단에 키 힌트 텍스트로 표시 (`⌘1:삭제 ⌘2:삭제 ...`)

### C. 마크다운 렌더링
assistant 응답에 기본 마크다운 렌더링 적용. (코드 블록, 볼드, 리스트 등)

### D. 새 대화 시작
히스토리를 초기화하고 새 대화를 시작하는 단축키 추가.

### E. 모델 변경
대화 중 사용할 모델을 변경하는 기능. claude --print의 --model 플래그를 활용.
- 단축키로 모델 선택 (예: ⌘M → 모델 목록 표시)
- 현재 선택된 모델을 UI에 표시
- 모델별 다른 동작 확인 (opus, sonnet, haiku 등)
