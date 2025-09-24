//
//  MessageRowView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

struct MessageRowView: View {
    let message: NtfyMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(message.displayTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                // Topic badge
                Text(message.topic)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.blue)

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(message.message ?? StringConstants.NotificationContent.noMessage)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            if let tags = message.tags, !tags.isEmpty {
                HStack {
                    ForEach(tags.prefix(UIConstants.MenuBar.recentMessagesLimit), id: \.self) { tag in
                        Text(emojiForTag(tag))
                            .font(.caption)
                    }
                    
                    if tags.count > UIConstants.MenuBar.recentMessagesLimit {
                        Text("+\(tags.count - UIConstants.MenuBar.recentMessagesLimit)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.theme.cardBackground)
        .cornerRadius(6)
    }
    
    private var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.date, relativeTo: Date())
    }
    
    private static let tagEmojiMap: [(keywords: [String], emoji: String)] = [
        // System/server tags (highest priority)
        (["urgent", "critical"], "🚨"),
        (["warning", "warn"], "⚠️"),
        (["error", "fail"], "❌"),
        (["success", "ok"], "✅"),
        (["info", "information"], "ℹ️"),

        // Infrastructure
        (["server", "host"], "🖥️"),
        (["database", "db"], "🗄️"),
        (["network", "connection"], "🌐"),
        (["backup"], "💾"),
        (["security", "auth"], "🔒"),

        // Development
        (["deploy", "release"], "🚀"),
        (["build", "ci"], "🔧"),
        (["test"], "🧪"),
        (["bug"], "🐛"),
        (["feature"], "✨"),

        // Monitoring
        (["cpu", "memory"], "📊"),
        (["disk", "storage"], "💿"),
        (["load", "performance"], "⚡"),
        (["uptime", "health"], "💚"),

        // Proxmox specific
        (["proxmox", "pve"], "🔵"),
        (["vm", "virtual"], "💻"),
        (["container", "lxc"], "📦"),
        (["replication"], "🔄"),

        // Environment
        (["production", "prod"], "🔴"),
        (["staging", "stage"], "🟡"),
        (["development", "dev"], "🟢"),

        // Multimedia & Media
        (["video", "stream", "movie", "film", "recording"], "📹"),
        (["audio", "music", "sound", "podcast", "voice"], "🎵"),
        (["photo", "image", "picture", "camera", "screenshot"], "📸"),
        (["live", "broadcast", "streaming", "tv"], "📺"),
        (["upload"], "⬆️"),
        (["download", "transfer"], "⬇️"),

        // Communication & Social
        (["email", "mail", "newsletter"], "📧"),
        (["chat", "message", "slack", "discord", "teams"], "💬"),
        (["social", "twitter", "facebook", "instagram"], "👥"),
        (["call", "phone", "meeting", "zoom", "conference"], "📞"),

        // Web & APIs
        (["api", "endpoint", "webhook", "rest", "graphql"], "🔌"),
        (["web", "website", "http", "url"], "🌍"),
        (["cdn", "cache", "cloudflare", "fastly"], "🚀"),
        (["ssl", "tls", "certificate", "https"], "🔐"),

        // Cloud & Services
        (["aws", "amazon", "ec2", "s3", "lambda"], "☁️"),
        (["azure", "microsoft", "office365"], "🔵"),
        (["google", "gcp", "gmail", "drive"], "🟡"),
        (["docker", "kubernetes", "k8s", "helm"], "🐳"),

        // Business & Productivity
        (["calendar", "schedule", "event"], "📅"),
        (["task", "todo", "ticket", "jira", "trello"], "✅"),
        (["payment", "billing", "invoice", "money", "cost"], "💰"),
        (["analytics", "metrics", "stats", "report"], "📈"),

        // Gaming & Entertainment
        (["game", "gaming", "steam", "twitch"], "🎮"),
        (["sport", "football", "soccer", "basketball"], "⚽"),
        (["news", "article", "rss", "feed"], "📰"),

        // IoT & Smart Home
        (["home", "smart", "iot", "automation"], "🏠"),
        (["temperature", "thermostat", "heating"], "🌡️"),
        (["light", "bulb", "brightness", "lamp"], "💡"),
        (["surveillance"], "📷"),
        (["door", "lock", "access"], "🚪"),
        (["garage"], "🏗️"),
        (["garden", "irrigation", "plant"], "🌱"),
        (["weather", "rain", "wind"], "🌤️"),
        (["alarm", "alert"], "🔔"),
        (["motion", "sensor"], "👁️"),

        // Transportation & Vehicles
        (["car", "vehicle", "auto"], "🚗"),
        (["truck", "delivery"], "🚚"),
        (["bike", "bicycle"], "🚴"),
        (["train", "railway"], "🚆"),
        (["plane", "flight", "airport"], "✈️"),
        (["ship", "boat"], "🚢"),
        (["fuel", "gas", "petrol"], "⛽"),
        (["parking"], "🅿️"),

        // Food & Restaurants
        (["food", "restaurant", "meal"], "🍽️"),
        (["pizza"], "🍕"),
        (["coffee", "cafe"], "☕"),
        (["beer", "alcohol"], "🍺"),
        (["grocery", "shopping"], "🛒"),
        (["kitchen", "cooking"], "👨‍🍳"),

        // Health & Fitness
        (["health", "medical", "doctor"], "🏥"),
        (["fitness", "gym", "workout"], "💪"),
        (["heart", "pulse"], "❤️"),
        (["step", "walk", "run"], "🏃"),
        (["sleep", "bed"], "😴"),
        (["pill", "medicine", "drug"], "💊"),

        // Education & Learning
        (["school", "education", "student"], "🎓"),
        (["book", "library", "read"], "📚"),
        (["course", "training", "tutorial"], "📖"),
        (["exam", "quiz", "grade"], "📝"),

        // Finance & Banking
        (["bank", "banking"], "🏦"),
        (["credit", "card"], "💳"),
        (["stock", "trading", "market"], "📊"),
        (["crypto", "bitcoin", "ethereum"], "₿"),
        (["tax", "irs"], "🧾"),

        // Science & Technology
        (["science", "research"], "🔬"),
        (["robot", "ai", "ml"], "🤖"),
        (["satellite", "space"], "🛰️"),
        (["lab", "experiment"], "⚗️"),
        (["dna", "genetic"], "🧬"),

        // Location & Maps
        (["location", "gps", "map"], "📍"),
        (["address", "street"], "🏘️"),
        (["city", "urban"], "🏙️"),
        (["country", "nation"], "🗺️"),

        // Time & Calendar
        (["time", "clock"], "🕐"),
        (["alarm"], "⏰"),
        (["timer", "countdown"], "⏱️"),
        (["reminder"], "⏰"),
        (["birthday", "anniversary"], "🎂"),

        // Tools & Utilities
        (["tool", "utility"], "🔧"),
        (["search", "find"], "🔍"),
        (["filter", "sort"], "🔀"),
        (["copy", "duplicate"], "📋"),
        (["delete", "remove"], "🗑️"),
        (["edit", "modify"], "✏️"),
        (["file", "document"], "📄"),
        (["folder", "directory"], "📁"),

        // Weather & Environment
        (["sun", "sunny"], "☀️"),
        (["cloud", "cloudy"], "☁️"),
        (["rain", "rainy"], "🌧️"),
        (["snow", "winter"], "❄️"),
        (["storm", "thunder"], "⛈️"),
        (["fire", "flame"], "🔥"),
        (["water", "ocean"], "🌊"),
        (["earth", "planet"], "🌍")
    ]

    private func emojiForTag(_ tag: String) -> String {
        let lowercaseTag = tag.lowercased()

        for mapping in Self.tagEmojiMap {
            if mapping.keywords.contains(where: { lowercaseTag.contains($0) }) {
                return mapping.emoji
            }
        }

        // Default emoji for unrecognized tags
        return "🏷️"
    }
}