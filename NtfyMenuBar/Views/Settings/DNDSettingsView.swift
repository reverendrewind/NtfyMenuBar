//
//  DNDSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct DNDSettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    // Required bindings from parent
    @Binding var isDNDScheduleEnabled: Bool
    @Binding var dndStartTime: Date
    @Binding var dndEndTime: Date
    @Binding var dndDaysOfWeek: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Do not disturb schedule")
                    .font(.headline)

                Toggle("Enable scheduled do not disturb", isOn: $isDNDScheduleEnabled)
                    .help("Automatically block notifications during specified hours")

                if isDNDScheduleEnabled {
                    VStack(alignment: .leading, spacing: 16) {
                        // Time configuration
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Start time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $dndStartTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }

                            Spacer()

                            VStack(alignment: .leading) {
                                Text("End time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $dndEndTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }

                        // Days of week selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active days")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(1...7, id: \.self) { day in
                                    let dayName = Calendar.current.shortWeekdaySymbols[day - 1]

                                    Button(action: {
                                        if dndDaysOfWeek.contains(day) {
                                            dndDaysOfWeek.remove(day)
                                        } else {
                                            dndDaysOfWeek.insert(day)
                                        }
                                    }) {
                                        Text(dayName)
                                            .font(.caption)
                                            .frame(width: 28, height: 28)
                                            .background(
                                                Circle()
                                                    .fill(dndDaysOfWeek.contains(day) ? Color.accentColor : Color.secondary.opacity(0.2))
                                            )
                                            .foregroundColor(dndDaysOfWeek.contains(day) ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Status display
                        if viewModel.settings.isCurrentlyInDND {
                            HStack {
                                Image(systemName: "moon.zzz.fill")
                                    .foregroundColor(.orange)
                                Text("Do Not Disturb is currently active")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
}