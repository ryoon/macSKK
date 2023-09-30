// SPDX-FileCopyrightText: 2023 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

@testable import macSKK

final class FileDictTests: XCTestCase {
    let fileURL = Bundle(for: FileDictTests.self).url(forResource: "empty", withExtension: "txt")!

    func testAdd() throws {
        let dict = try FileDict(contentsOf: fileURL, encoding: .utf8, readonly: true)
        XCTAssertEqual(dict.entryCount, 0)
        let word = Word("井")
        XCTAssertFalse(dict.hasUnsavedChanges)
        dict.add(yomi: "い", word: word)
        XCTAssertEqual(dict.refer("い", option: nil), [word])
        XCTAssertTrue(dict.hasUnsavedChanges)
    }

    func testDelete() throws {
        let dict = try FileDict(contentsOf: fileURL, encoding: .utf8, readonly: true)
        dict.setEntries(["あr": [Word("有"), Word("在")]], readonly: true)
        XCTAssertFalse(dict.delete(yomi: "あr", word: "或"))
        XCTAssertFalse(dict.hasUnsavedChanges)
        XCTAssertTrue(dict.delete(yomi: "あr", word: "在"))
        XCTAssertTrue(dict.hasUnsavedChanges)
    }

    func testSerialize() throws {
        let dict = try FileDict(contentsOf: fileURL, encoding: .utf8, readonly: false)
        XCTAssertEqual(dict.serialize(),
                       [FileDict.headers[0], FileDict.okuriAriHeader, FileDict.okuriNashiHeader, ""].joined(separator: "\n"))
        dict.add(yomi: "あ", word: Word("亜", annotation: Annotation(dictId: "testDict", text: "亜の注釈")))
        dict.add(yomi: "あ", word: Word("阿", annotation: Annotation(dictId: "testDict", text: "阿の注釈")))
        dict.add(yomi: "あr", word: Word("有", annotation: Annotation(dictId: "testDict", text: "有の注釈")))
        dict.add(yomi: "あr", word: Word("在", annotation: Annotation(dictId: "testDict", text: "在の注釈")))
        var expected = [
            FileDict.headers[0],
            FileDict.okuriAriHeader,
            "あr /在;在の注釈/有;有の注釈/",
            FileDict.okuriNashiHeader,
            "あ /阿;阿の注釈/亜;亜の注釈/",
            "",
        ].joined(separator: "\n")
        XCTAssertEqual(dict.serialize(), expected)
        // 追加したエントリはシリアライズ時は先頭に付く
        dict.add(yomi: "い", word: Word("伊"))
        dict.add(yomi: "いr", word: Word("射"))
        expected = [
            FileDict.headers[0],
            FileDict.okuriAriHeader,
            "いr /射/",
            "あr /在;在の注釈/有;有の注釈/",
            FileDict.okuriNashiHeader,
            "い /伊/",
            "あ /阿;阿の注釈/亜;亜の注釈/",
            "",
        ].joined(separator: "\n")
        XCTAssertEqual(dict.serialize(), expected)
        // 追加更新した場合は順序を変更する。削除更新した場合は順序を変更しない
        XCTAssertTrue(dict.delete(yomi: "あ", word: "亜"))
        dict.add(yomi: "あr", word: Word("或"))
        expected = [
            FileDict.headers[0],
            FileDict.okuriAriHeader,
            "あr /或/在;在の注釈/有;有の注釈/",
            "いr /射/",
            FileDict.okuriNashiHeader,
            "い /伊/",
            "あ /阿;阿の注釈/",
            "",
        ].joined(separator: "\n")
        XCTAssertEqual(dict.serialize(), expected)
    }
}
