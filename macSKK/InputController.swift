// SPDX-FileCopyrightText: 2022 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Combine
import Foundation
import InputMethodKit

@objc(InputController)
class InputController: IMKInputController {
    private let stateMachine = StateMachine()
    private let candidates: IMKCandidates
    private let preferenceMenu = NSMenu()
    private var cancellables: Set<AnyCancellable> = []
    private static let notFoundRange = NSRange(location: NSNotFound, length: NSNotFound)

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        candidates = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel)
        super.init(server: server, delegate: delegate, client: inputClient)

        preferenceMenu.addItem(
            withTitle: NSLocalizedString("MenuItemPreference", comment: "Preferences…"),
            action: #selector(showSettings), keyEquivalent: "")
        preferenceMenu.addItem(
            withTitle: NSLocalizedString("MenuItemSaveDict", comment: "Save User Dictionary"),
            action: #selector(saveDict), keyEquivalent: "")

        guard let textInput = inputClient as? IMKTextInput else {
            return
        }

        stateMachine.inputMethodEvent.sink { event in
            switch event {
            case .fixedText(let text):
                textInput.insertText(text, replacementRange: Self.notFoundRange)
            case .markedText(let markedText):
                let attributedText = NSMutableAttributedString(string: markedText.text)
                let cursorRange: NSRange
                if let cursor = markedText.cursor {
                    cursorRange = NSRange(location: cursor, length: 0)
                } else {
                    cursorRange = NSRange(location: markedText.text.count, length: 0)
                }
                attributedText.addAttributes([.cursor: NSCursor.iBeam], range: cursorRange)
                textInput.setMarkedText(
                    attributedText, selectionRange: cursorRange, replacementRange: Self.notFoundRange)
            case .modeChanged(let inputMode):
                textInput.selectMode(inputMode.rawValue)
            }
        }.store(in: &cancellables)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        // 左下座標基準でwidth=1, height=(通常だとフォントサイズ)のNSRect
        var cursorPosition: NSRect = .zero
        if let textInput = sender as? IMKTextInput {
            // カーソル位置あたりを取得する
            textInput.attributes(forCharacterIndex: 0, lineHeightRectangle: &cursorPosition)
            // TODO: 単語登録中など、現在のカーソル位置が0ではないときはそれに合わせて座標を取得したい
            //            if let attributes = textInput.attributes(forCharacterIndex: 0, lineHeightRectangle: &lineRect) {
            //                let rectInfo = "x=\(lineRect.origin.x),y=\(lineRect.origin.y),w=\(lineRect.size.width),h=\(lineRect.size.height)"
            //                logger.log("属性: \(attributes, privacy: .public), rect: \(rectInfo, privacy: .public)")
            //            } else {
            //                logger.log("属性が取得できません")
            //            }
        } else {
            logger.log("IMKTextInputが取得できません")
        }
        guard let keyEvent = convert(event: event) else {
            logger.debug("Can not convert event to KeyEvent")
            return stateMachine.handleUnhandledEvent(event)
        }

        return stateMachine.handle(Action(keyEvent: keyEvent, originalEvent: event, cursorPosition: cursorPosition))
    }

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        guard let value = value as? NSString else { return }
        logger.log("setValue \(value, privacy: .public)")
    }

    override func menu() -> NSMenu! {
        return preferenceMenu
    }

    @objc func showSettings() {
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func saveDict() {
        do {
            try dictionary.save()
        } catch {
            logger.error("ユーザー辞書保存中にエラーが発生しました")
        }
    }

    // MARK: -
    private func isPrintable(_ text: String) -> Bool {
        let printable = [CharacterSet.alphanumerics, CharacterSet.symbols, CharacterSet.punctuationCharacters]
            .reduce(CharacterSet()) { $0.union($1) }
        return !text.unicodeScalars.contains { !printable.contains($0) }
    }

    private func convert(event: NSEvent) -> Action.KeyEvent? {
        // Ctrl-J, Ctrl-Gなどは受け取るが、基本的にはCtrl, Command, Fnが押されていたら無視する
        // Optionは修飾キーを打つかもしれないので許容する
        let modifiers = event.modifierFlags
        let keyCode = event.keyCode
        let charactersIgnoringModifiers = event.charactersIgnoringModifiers
        if modifiers.contains(.control) || modifiers.contains(.command) || modifiers.contains(.function) {
            if modifiers == [.control] {
                if charactersIgnoringModifiers == "j" {
                    return .ctrlJ
                } else if charactersIgnoringModifiers == "g" {
                    return .cancel
                } else if charactersIgnoringModifiers == "h" {
                    return .backspace
                } else if charactersIgnoringModifiers == "b" {
                    return .left
                } else if charactersIgnoringModifiers == "f" {
                    return .right
                }
            }
            // カーソルキーはFn + NumPadがmodifierFlagsに設定されている
            if !modifiers.contains(.control) && !modifiers.contains(.command) && modifiers.contains(.function) {
                if keyCode == 123 {
                    return .left
                } else if keyCode == 124 {
                    return .right
                }
            }

            return nil
        }

        if keyCode == 36 {  // エンター
            return .enter
        } else if keyCode == 123 {
            return .left
        } else if keyCode == 124 {
            return .right
        } else if keyCode == 51 {
            return .backspace
        } else if keyCode == 53 {  // ESC
            return .cancel
        } else if event.characters == " " {
            return .space
        } else if event.characters == ";" {
            return .stickyShift
        } else if let text = charactersIgnoringModifiers {
            if isPrintable(text) {
                return .printable(text)
            }
        }
        return nil
    }
}
