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

대화 컨텍스트 유지 기능 구현:
- `ConversationFormatter`: 히스토리 + 새 메시지를 프롬프트로 포맷
- `ClaudeProcess.send(message:history:)`: 히스토리 파라미터 추가
- `ChatView`: 메시지 전송 시 이전 대화 히스토리를 함께 전달
- 단위 테스트 3개 추가 (ConversationFormatterTests)
- 깨져있던 통합 테스트 수정 (ClaudeProcessTests)

## 다음 단계 후보

### A. 마크다운 렌더링
assistant 응답에 기본 마크다운 렌더링 적용. (코드 블록, 볼드, 리스트 등)

### B. Jenga 핵심 - 블록 조작 UI
장기 목표인 대화 블록 추가/제거/재배치 UI 설계 및 구현 시작.

### C. 새 대화 시작 버튼
히스토리를 초기화하고 새 대화를 시작하는 UI 추가.
