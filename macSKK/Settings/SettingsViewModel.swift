// SPDX-FileCopyrightText: 2023 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Combine
import Foundation

// これをObservableObjectにする?
// どうすればUserDefaultsとグローバル変数dictionaryのdictsと同期させる方法がまだよくわかってない
// @AppStorageを使う…?
final class DictSetting: ObservableObject, Identifiable {
    typealias ID = String
    @Published var filename: String
    @Published var enabled: Bool
    @Published var encoding: String.Encoding
    
    var id: String { filename }
    
    init(filename: String, enabled: Bool, encoding: String.Encoding) {
        self.filename = filename
        self.enabled = enabled
        self.encoding = encoding
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    /// CheckUpdaterで取得した最新のリリース。取得前はnil
    @Published var latestRelease: Release? = nil
    /// リリースの確認中かどうか
    @Published var fetchingRelease: Bool = false
    /// すべての利用可能なSKK辞書の設定
    @Published var fileDicts: [DictSetting] = []

    init(dictSettings: [DictSetting] = []) {
        self.fileDicts = dictSettings
        self.fileDicts = [
            DictSetting(filename: "SKK-JISYO.L", enabled: true, encoding: .japaneseEUC),
            DictSetting(filename: "SKK-JISYO.sample.utf-8", enabled: false, encoding: .utf8)
        ]
    }

    /**
     * リリースの確認を行う
     */
    func fetchReleases() async throws {
        fetchingRelease = true
        defer {
            fetchingRelease = false
        }
        latestRelease = try await LatestReleaseFetcher.shared.fetch()
    }
}
