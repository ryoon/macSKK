// SPDX-FileCopyrightText: 2023 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

/// 変換候補ビュー
/// とりあえず10件ずつ縦に表示、スペースで次の10件が表示される
struct CandidatesView: View {
    @ObservedObject var candidates: CandidatesViewModel
    /// 一行の高さ
    static let lineHeight: CGFloat = 20
    @State private var selectedIndex: Int = 0
    private let font: Font = .body

    var body: some View {
        // Listではスクロールが生じるためForEachを使用
        List(selection: $selectedIndex) {
            ForEach(candidates.candidates.indices, id: \.self) { index in
                let candidate = candidates.candidates[index]
                HStack {
                    Text("\(index + 1)")
                        .font(font)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        .frame(width: 16)
                    Text(candidate.word)
                        .font(font)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                }
                .listRowInsets(EdgeInsets())
                .frame(height: Self.lineHeight)
                // .border(Color.red) // Listの謎のInsetのデバッグ時に使用する
                .contentShape(Rectangle())
            }
            /* popoverだと候補ウィンドウを表示してないときに表示しづらいので別ビューにする予定
            .popover(
                isPresented: .constant(candidate == candidates.selected?.word && candidate.annotation != nil),
                arrowEdge: .trailing
            ) {
                VStack {
                    if let systemAnnotation = candidates.selected?.systemAnnotation {
                        Text(systemAnnotation)
                            .frame(idealWidth: 300, maxHeight: .infinity)
                            .padding()
                    } else {
                        Text(candidate.annotation!)
                            .frame(idealWidth: 300, maxHeight: .infinity)
                            .padding()
                    }
                }
            }
            */
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, Self.lineHeight)
        .scrollDisabled(true)
        .frame(width: minWidth(), height: CGFloat(candidates.candidates.count) * Self.lineHeight)
        .onChange(of: selectedIndex) { selectedIndex in
            let candidate = candidates.candidates[selectedIndex]
            if candidates.selected?.word == candidate {
                candidates.doubleSelected = candidate
            }
            candidates.selected = SelectedWord(word: candidate, systemAnnotation: nil)
        }
    }

    // 最長のテキストを表示するために必要なビューのサイズを返す
    private func minWidth() -> CGFloat {
        let width = candidates.candidates.map { candidate -> CGFloat in
            let size = candidate.word.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: Self.lineHeight),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [.font: NSFont.preferredFont(forTextStyle: .body)])
            // 未解決の余白(8px) + 添字(16px) + 余白(4px) + テキスト + 余白(4px) + 未解決の余白(24px)
            // @see https://forums.swift.org/t/swiftui-list-horizontal-insets-macos/52985/5
            return 16 + 4 + size.width + 4 + 22
        }.max()
        return width ?? 0
    }
}

struct CandidatesView_Previews: PreviewProvider {
    private static let words: [Word] = (1..<9).map {
        Word(String(repeating: "例文\($0)", count: $0), annotation: "注釈\($0)")
    }

    static var previews: some View {
        let viewModel = CandidatesViewModel(candidates: words)
        viewModel.selected = SelectedWord(word: words.first!, systemAnnotation: String(repeating: "これはシステム辞書の注釈です。", count: 10))
        return CandidatesView(candidates: viewModel)
    }
}
