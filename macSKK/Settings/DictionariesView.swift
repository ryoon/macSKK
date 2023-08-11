// SPDX-FileCopyrightText: 2023 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

struct DictionariesView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel

    var body: some View {
        // 辞書のファイル名と有効かどうかのトグル + 詳細表示のiボタン
        // 詳細はシートでエンコーディング、エントリ数が見れる
        // エントリ一覧が検索できてもいいかもしれない
        VStack {
            Form {
                ForEach($settingsViewModel.fileDicts) { fileDict in
                    Toggle(fileDict.id, isOn: fileDict.enabled)
                        .toggleStyle(.switch)
                }
            }
            .formStyle(.grouped)
            Spacer()
        }
    }
}

struct DictionariesView_Previews: PreviewProvider {
    static var previews: some View {
        let dictSettings = [
            DictSetting(filename: "SKK-JISYO.L", enabled: true, encoding: .japaneseEUC),
            DictSetting(filename: "SKK-JISYO.sample.utf-8", enabled: false, encoding: .utf8)
        ]
        let settings = SettingsViewModel(dictSettings: dictSettings)
        return DictionariesView(settingsViewModel: settings)
    }
}
