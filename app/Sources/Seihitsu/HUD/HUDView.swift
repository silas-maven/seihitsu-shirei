import SwiftUI

struct HUDView: View {
    @ObservedObject var vm: HUDViewModel
    @FocusState private var promptFocused: Bool

    private let accent = Color(red: 0.13, green: 0.83, blue: 0.93) // ~ #22d3ee

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            promptRow
            actionRow
            if let ctx = vm.context { ContextChip(attachment: ctx, accent: accent) { vm.clearContext() } }
            Divider().overlay(Color.white.opacity(0.12))
            answerHeader
            answerArea
            footer
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Glass: faint tint + specular top-lit border over the NSVisualEffectView blur.
        .background(
            RoundedRectangle(cornerRadius: HUDController.corner)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: HUDController.corner)
                .strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.06)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: HUDController.corner))
        .foregroundStyle(.white)
        .onAppear { promptFocused = true }
        .onChange(of: vm.focusPulse) { _, _ in promptFocused = true }
    }

    private var promptRow: some View {
        HStack(spacing: 8) {
            Image(systemName: vm.state == .thinking ? "hourglass" : "brain")
                .foregroundStyle(accent)
            TextField(vm.context == nil ? "Ask…" : "What should I do with this?", text: $vm.prompt)
                .textFieldStyle(.plain)
                .focused($promptFocused)
                .onSubmit { vm.submit() }
            if vm.state == .thinking { ProgressView().controlSize(.small) }
        }
        .font(.system(.body, design: .monospaced))
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { vm.requestCapture() } label: {
                Label("Capture", systemImage: "text.viewfinder")
            }
            .foregroundStyle(accent)
            Button { vm.requestReadScreen() } label: {
                Label("Read", systemImage: "eye")
            }
            .foregroundStyle(accent)
            Button { vm.toggleListen() } label: {
                Label(vm.isListening ? "Stop" : "Listen",
                      systemImage: vm.isListening ? "stop.circle.fill" : "mic.fill")
            }
            .foregroundStyle(vm.isListening ? Color.red : accent)
            Spacer()
            if vm.isListening {
                Circle().fill(Color.red).frame(width: 7, height: 7)
                Text("rec").foregroundStyle(.red.opacity(0.9))
            }
            speedControl
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, design: .monospaced))
    }

    /// Answer length/speed. Blitz returns just the answer, for a question with a timer.
    private var speedControl: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 8))
                .foregroundStyle(vm.mode == .blitz ? accent : .white.opacity(0.3))
            ForEach(AnswerMode.allCases, id: \.self) { m in
                Text(m.label)
                    .font(.system(size: 10, weight: vm.mode == m ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(vm.mode == m ? accent : .white.opacity(0.4))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(vm.mode == m ? accent.opacity(0.15) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { vm.mode = m }
            }
        }
        .help("Answer length. Blitz returns just the answer for timed questions (⌥⇧S to cycle).")
    }

    private var answerHeader: some View {
        HStack {
            Text("ANSWER").font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35)).tracking(1.2)
            Spacer()
            if !vm.answer.isEmpty {
                Button { vm.copyAnswer() } label: {
                    Label("Copy", systemImage: "doc.on.doc").font(.system(size: 10, design: .monospaced))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent.opacity(0.9))
            }
        }
    }

    private var answerArea: some View {
        ScrollView {
            Text(vm.answer.isEmpty ? " " : vm.answer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .font(.system(.callout, design: .monospaced))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if !vm.modelName.isEmpty {
                Text(vm.modelName).foregroundStyle(accent.opacity(0.8))
                Text("·").foregroundStyle(.white.opacity(0.25))
            }
            Text(vm.statusLine).lineLimit(1)
            Spacer()
            Text(vm.clickThrough ? "click-through ON" : "⌥Space · ⌥C · ⌥V · ⌥L")
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.white.opacity(0.5))
    }
}

/// A pill showing the captured selection that is waiting for an instruction.
private struct ContextChip: View {
    let attachment: Attachment
    let accent: Color
    let onClear: () -> Void

    private var preview: String {
        let firstLine = attachment.content.split(separator: "\n").first.map(String.init) ?? attachment.content
        return String(firstLine.prefix(60))
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: attachment.kind == .code ? "curlybraces" : "text.quote")
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.kind == .code ? "Code" : "Selection")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Text(preview)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            if let src = attachment.source {
                Text(src).font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
            }
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accent.opacity(0.25), lineWidth: 1))
    }
}
