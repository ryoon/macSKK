// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

struct WorkaroundView: View {
    @StateObject var settingsViewModel: SettingsViewModel

    var body: some View {
        let applications = settingsViewModel.workaroundApplications
        VStack {
            Form {
                if applications.isEmpty {
                    Text("Unregistered")
                } else {
                    Section {
                        List(applications) { application in
                            HStack {
                                if let icon = application.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "questionmark.square")
                                        .font(.system(size: 32))
                                        .fontWeight(.light)
                                        .frame(width: 32, height: 32)
                                }
                                VStack(alignment: .leading) {
                                    Text(application.displayName ?? application.bundleIdentifier)
                                        .font(.body)
                                    Group {
                                        Text("Insert Blank String") + Text(": ") + Text(application.insertBlankString ? "Enabled" : "Disabled")
                                    }.font(.footnote)
                                }
                                Spacer()
                            }
                            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .onAppear {
                                if application.icon == nil || application.displayName == nil {
                                    let workspace = NSWorkspace.shared
                                    if let index = applications.firstIndex(of: application),
                                       let appUrl = workspace.urlForApplication(withBundleIdentifier: application.bundleIdentifier) {
                                        settingsViewModel.updateWorkaroundApplication(index: index, displayName: FileManager.default.displayName(atPath: appUrl.path(percentEncoded: false)), icon: workspace.icon(forFile: appUrl.path(percentEncoded: false)))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            Text("SettingsNoteWorkaround")
                .font(.subheadline)
                .padding([.bottom, .leading, .trailing])
            Spacer()
        }
    }
}

#Preview {
    WorkaroundView(settingsViewModel: try! SettingsViewModel(workaroundApplications: [
        WorkaroundApplication(bundleIdentifier: "net.mtgto.inputmethod.macSKK",
                              insertBlankString: true,
                              icon: NSImage(named: "AppIcon"), displayName: "macSKK"),
        WorkaroundApplication(bundleIdentifier: "net.mtgto.inputmethod.macSKK.not-resolved", insertBlankString: false, icon: nil, displayName: nil)
    ]))
}

#Preview("空のとき") {
    WorkaroundView(settingsViewModel: try! SettingsViewModel(workaroundApplications: []))
}
