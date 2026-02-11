# Jenga Claude - Swift macOS 네이티브 앱

## Context
claude-skin(React Ink 터미널 래퍼)의 핵심 기능을 macOS 네이티브 앱으로 재구현.
장기 목표: 대화 컨텍스트를 자유롭게 조작(블록 추가/제거/재배치)하는 UI.
1차 목표: claude --print 모드와 통신하는 기본 채팅 앱.

## 프로젝트 구조
```
/Users/juniq/develop/code/juniqlim/jenga-claude/
├── Package.swift
├── Sources/
│   └── JengaClaude/
│       ├── JengaClaudeApp.swift      # 앱 진입점
│       ├── Views/
│       │   ├── ChatView.swift         # 메인 채팅 UI
│       │   └── MessageView.swift      # 개별 메시지 렌더링
│       ├── Models/
│       │   ├── Message.swift          # 메시지 모델
│       │   └── ClaudeEvent.swift      # NDJSON 이벤트 타입
│       └── Services/
│           └── ClaudeProcess.swift    # claude CLI 프로세스 관리
└── Tests/
    └── JengaClaudeTests/
        ├── ClaudeEventTests.swift     # NDJSON 파싱 테스트
        └── ClaudeProcessTests.swift   # 프로세스 통신 테스트
```

## 구현 단계

### 1단계: 프로젝트 셋업 + NDJSON 파싱 테스트
- Swift Package Manager로 macOS 앱 프로젝트 생성
- ClaudeEvent 모델 정의 (init, assistant, tool_use, result)
- NDJSON 파싱 로직 단위 테스트 작성 → 구현

### 2단계: ClaudeProcess 서비스
- `Process` (Foundation)로 claude CLI 스폰
- `claude --print --output-format stream-json --input-format stream-json --verbose`
- stdin으로 메시지 전송, stdout에서 NDJSON 스트림 읽기
- 통합 테스트: 실제 claude 프로세스와 통신 확인

### 3단계: SwiftUI 채팅 UI
- 단순한 채팅 인터페이스: 메시지 목록 + 입력창
- 스트리밍 응답 실시간 표시
- 마크다운 기본 렌더링

### 4단계: 빌드 및 실행 확인
- `swift build`로 빌드
- `swift run`으로 실행 확인

## 핵심 통신 프로토콜 (claude-skin에서 확인)
```bash
claude --print --output-format stream-json --input-format stream-json --verbose
```
- stdin: `{"type":"user","message":{"role":"user","content":"hello"}}\n`
- stdout: NDJSON 이벤트 스트림 (system/init, assistant, result 등)

## 검증
1. `swift test` - 단위 테스트 (NDJSON 파싱)
2. `swift run` - 앱 실행하여 claude와 실제 대화 확인
