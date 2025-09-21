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
            
            Text(message.message ?? "No message")
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            if let tags = message.tags, !tags.isEmpty {
                HStack {
                    ForEach(tags.prefix(5), id: \.self) { tag in
                        Text(emojiForTag(tag))
                            .font(.caption)
                    }
                    
                    if tags.count > 5 {
                        Text("+\(tags.count - 5)")
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
    
    private func emojiForTag(_ tag: String) -> String {
        let lowercaseTag = tag.lowercased()
        
        // Common system/server tags
        if lowercaseTag.contains("urgent") || lowercaseTag.contains("critical") { return "🚨" }
        if lowercaseTag.contains("warning") || lowercaseTag.contains("warn") { return "⚠️" }
        if lowercaseTag.contains("error") || lowercaseTag.contains("fail") { return "❌" }
        if lowercaseTag.contains("success") || lowercaseTag.contains("ok") { return "✅" }
        if lowercaseTag.contains("info") || lowercaseTag.contains("information") { return "ℹ️" }
        
        // Infrastructure
        if lowercaseTag.contains("server") || lowercaseTag.contains("host") { return "🖥️" }
        if lowercaseTag.contains("database") || lowercaseTag.contains("db") { return "🗄️" }
        if lowercaseTag.contains("network") || lowercaseTag.contains("connection") { return "🌐" }
        if lowercaseTag.contains("backup") { return "💾" }
        if lowercaseTag.contains("security") || lowercaseTag.contains("auth") { return "🔒" }
        
        // Development
        if lowercaseTag.contains("deploy") || lowercaseTag.contains("release") { return "🚀" }
        if lowercaseTag.contains("build") || lowercaseTag.contains("ci") { return "🔧" }
        if lowercaseTag.contains("test") { return "🧪" }
        if lowercaseTag.contains("bug") { return "🐛" }
        if lowercaseTag.contains("feature") { return "✨" }
        
        // Monitoring
        if lowercaseTag.contains("cpu") || lowercaseTag.contains("memory") { return "📊" }
        if lowercaseTag.contains("disk") || lowercaseTag.contains("storage") { return "💿" }
        if lowercaseTag.contains("load") || lowercaseTag.contains("performance") { return "⚡" }
        if lowercaseTag.contains("uptime") || lowercaseTag.contains("health") { return "💚" }
        
        // Proxmox specific
        if lowercaseTag.contains("proxmox") || lowercaseTag.contains("pve") { return "🔵" }
        if lowercaseTag.contains("vm") || lowercaseTag.contains("virtual") { return "💻" }
        if lowercaseTag.contains("container") || lowercaseTag.contains("lxc") { return "📦" }
        if lowercaseTag.contains("replication") { return "🔄" }
        
        // Environment
        if lowercaseTag.contains("production") || lowercaseTag.contains("prod") { return "🔴" }
        if lowercaseTag.contains("staging") || lowercaseTag.contains("stage") { return "🟡" }
        if lowercaseTag.contains("development") || lowercaseTag.contains("dev") { return "🟢" }
        
        // Multimedia & Media
        if lowercaseTag.contains("video") || lowercaseTag.contains("stream") || lowercaseTag.contains("movie") || lowercaseTag.contains("film") || lowercaseTag.contains("recording") { return "📹" }
        if lowercaseTag.contains("audio") || lowercaseTag.contains("music") || lowercaseTag.contains("sound") || lowercaseTag.contains("podcast") || lowercaseTag.contains("voice") { return "🎵" }
        if lowercaseTag.contains("photo") || lowercaseTag.contains("image") || lowercaseTag.contains("picture") || lowercaseTag.contains("camera") || lowercaseTag.contains("screenshot") { return "📸" }
        if lowercaseTag.contains("live") || lowercaseTag.contains("broadcast") || lowercaseTag.contains("streaming") || lowercaseTag.contains("tv") { return "📺" }
        if lowercaseTag.contains("upload") { return "⬆️" }
        if lowercaseTag.contains("download") || lowercaseTag.contains("transfer") { return "⬇️" }
        
        // Communication & Social
        if lowercaseTag.contains("email") || lowercaseTag.contains("mail") || lowercaseTag.contains("newsletter") { return "📧" }
        if lowercaseTag.contains("chat") || lowercaseTag.contains("message") || lowercaseTag.contains("slack") || lowercaseTag.contains("discord") || lowercaseTag.contains("teams") { return "💬" }
        if lowercaseTag.contains("social") || lowercaseTag.contains("twitter") || lowercaseTag.contains("facebook") || lowercaseTag.contains("instagram") { return "👥" }
        if lowercaseTag.contains("call") || lowercaseTag.contains("phone") || lowercaseTag.contains("meeting") || lowercaseTag.contains("zoom") || lowercaseTag.contains("conference") { return "📞" }
        
        // Web & APIs
        if lowercaseTag.contains("api") || lowercaseTag.contains("endpoint") || lowercaseTag.contains("webhook") || lowercaseTag.contains("rest") || lowercaseTag.contains("graphql") { return "🔌" }
        if lowercaseTag.contains("web") || lowercaseTag.contains("website") || lowercaseTag.contains("http") || lowercaseTag.contains("url") { return "🌍" }
        if lowercaseTag.contains("cdn") || lowercaseTag.contains("cache") || lowercaseTag.contains("cloudflare") || lowercaseTag.contains("fastly") { return "🚀" }
        if lowercaseTag.contains("ssl") || lowercaseTag.contains("tls") || lowercaseTag.contains("certificate") || lowercaseTag.contains("https") { return "🔐" }
        
        // Cloud & Services
        if lowercaseTag.contains("aws") || lowercaseTag.contains("amazon") || lowercaseTag.contains("ec2") || lowercaseTag.contains("s3") || lowercaseTag.contains("lambda") { return "☁️" }
        if lowercaseTag.contains("azure") || lowercaseTag.contains("microsoft") || lowercaseTag.contains("office365") { return "🔵" }
        if lowercaseTag.contains("google") || lowercaseTag.contains("gcp") || lowercaseTag.contains("gmail") || lowercaseTag.contains("drive") { return "🟡" }
        if lowercaseTag.contains("docker") || lowercaseTag.contains("kubernetes") || lowercaseTag.contains("k8s") || lowercaseTag.contains("helm") { return "🐳" }
        
        // Business & Productivity
        if lowercaseTag.contains("calendar") || lowercaseTag.contains("schedule") || lowercaseTag.contains("event") { return "📅" }
        if lowercaseTag.contains("task") || lowercaseTag.contains("todo") || lowercaseTag.contains("ticket") || lowercaseTag.contains("jira") || lowercaseTag.contains("trello") { return "✅" }
        if lowercaseTag.contains("payment") || lowercaseTag.contains("billing") || lowercaseTag.contains("invoice") || lowercaseTag.contains("money") || lowercaseTag.contains("cost") { return "💰" }
        if lowercaseTag.contains("analytics") || lowercaseTag.contains("metrics") || lowercaseTag.contains("stats") || lowercaseTag.contains("report") { return "📈" }
        
        // Gaming & Entertainment
        if lowercaseTag.contains("game") || lowercaseTag.contains("gaming") || lowercaseTag.contains("steam") || lowercaseTag.contains("twitch") { return "🎮" }
        if lowercaseTag.contains("sport") || lowercaseTag.contains("football") || lowercaseTag.contains("soccer") || lowercaseTag.contains("basketball") { return "⚽" }
        if lowercaseTag.contains("news") || lowercaseTag.contains("article") || lowercaseTag.contains("rss") || lowercaseTag.contains("feed") { return "📰" }
        
        // IoT & Smart Home
        if lowercaseTag.contains("home") || lowercaseTag.contains("smart") || lowercaseTag.contains("iot") || lowercaseTag.contains("automation") { return "🏠" }
        if lowercaseTag.contains("temperature") || lowercaseTag.contains("thermostat") || lowercaseTag.contains("heating") { return "🌡️" }
        if lowercaseTag.contains("light") || lowercaseTag.contains("bulb") || lowercaseTag.contains("brightness") || lowercaseTag.contains("lamp") { return "💡" }
        if lowercaseTag.contains("surveillance") { return "📷" }
        if lowercaseTag.contains("door") || lowercaseTag.contains("lock") || lowercaseTag.contains("access") { return "🚪" }
        if lowercaseTag.contains("garage") { return "🏗️" }
        if lowercaseTag.contains("garden") || lowercaseTag.contains("irrigation") || lowercaseTag.contains("plant") { return "🌱" }
        if lowercaseTag.contains("weather") || lowercaseTag.contains("rain") || lowercaseTag.contains("wind") { return "🌤️" }
        if lowercaseTag.contains("alarm") || lowercaseTag.contains("alert") { return "🔔" }
        if lowercaseTag.contains("motion") || lowercaseTag.contains("sensor") { return "👁️" }
        
        // Transportation & Vehicles
        if lowercaseTag.contains("car") || lowercaseTag.contains("vehicle") || lowercaseTag.contains("auto") { return "🚗" }
        if lowercaseTag.contains("truck") || lowercaseTag.contains("delivery") { return "🚚" }
        if lowercaseTag.contains("bike") || lowercaseTag.contains("bicycle") { return "🚴" }
        if lowercaseTag.contains("train") || lowercaseTag.contains("railway") { return "🚆" }
        if lowercaseTag.contains("plane") || lowercaseTag.contains("flight") || lowercaseTag.contains("airport") { return "✈️" }
        if lowercaseTag.contains("ship") || lowercaseTag.contains("boat") { return "🚢" }
        if lowercaseTag.contains("fuel") || lowercaseTag.contains("gas") || lowercaseTag.contains("petrol") { return "⛽" }
        if lowercaseTag.contains("parking") { return "🅿️" }
        
        // Food & Restaurants
        if lowercaseTag.contains("food") || lowercaseTag.contains("restaurant") || lowercaseTag.contains("meal") { return "🍽️" }
        if lowercaseTag.contains("pizza") { return "🍕" }
        if lowercaseTag.contains("coffee") || lowercaseTag.contains("cafe") { return "☕" }
        if lowercaseTag.contains("beer") || lowercaseTag.contains("alcohol") { return "🍺" }
        if lowercaseTag.contains("grocery") || lowercaseTag.contains("shopping") { return "🛒" }
        if lowercaseTag.contains("kitchen") || lowercaseTag.contains("cooking") { return "👨‍🍳" }
        
        // Health & Fitness
        if lowercaseTag.contains("health") || lowercaseTag.contains("medical") || lowercaseTag.contains("doctor") { return "🏥" }
        if lowercaseTag.contains("fitness") || lowercaseTag.contains("gym") || lowercaseTag.contains("workout") { return "💪" }
        if lowercaseTag.contains("heart") || lowercaseTag.contains("pulse") { return "❤️" }
        if lowercaseTag.contains("step") || lowercaseTag.contains("walk") || lowercaseTag.contains("run") { return "🏃" }
        if lowercaseTag.contains("sleep") || lowercaseTag.contains("bed") { return "😴" }
        if lowercaseTag.contains("pill") || lowercaseTag.contains("medicine") || lowercaseTag.contains("drug") { return "💊" }
        
        // Education & Learning
        if lowercaseTag.contains("school") || lowercaseTag.contains("education") || lowercaseTag.contains("student") { return "🎓" }
        if lowercaseTag.contains("book") || lowercaseTag.contains("library") || lowercaseTag.contains("read") { return "📚" }
        if lowercaseTag.contains("course") || lowercaseTag.contains("training") || lowercaseTag.contains("tutorial") { return "📖" }
        if lowercaseTag.contains("exam") || lowercaseTag.contains("quiz") || lowercaseTag.contains("grade") { return "📝" }
        
        // Finance & Banking
        if lowercaseTag.contains("bank") || lowercaseTag.contains("banking") { return "🏦" }
        if lowercaseTag.contains("credit") || lowercaseTag.contains("card") { return "💳" }
        if lowercaseTag.contains("stock") || lowercaseTag.contains("trading") || lowercaseTag.contains("market") { return "📊" }
        if lowercaseTag.contains("crypto") || lowercaseTag.contains("bitcoin") || lowercaseTag.contains("ethereum") { return "₿" }
        if lowercaseTag.contains("tax") || lowercaseTag.contains("irs") { return "🧾" }
        
        // Science & Technology
        if lowercaseTag.contains("science") || lowercaseTag.contains("research") { return "🔬" }
        if lowercaseTag.contains("robot") || lowercaseTag.contains("ai") || lowercaseTag.contains("ml") { return "🤖" }
        if lowercaseTag.contains("satellite") || lowercaseTag.contains("space") { return "🛰️" }
        if lowercaseTag.contains("lab") || lowercaseTag.contains("experiment") { return "⚗️" }
        if lowercaseTag.contains("dna") || lowercaseTag.contains("genetic") { return "🧬" }
        
        // Location & Maps
        if lowercaseTag.contains("location") || lowercaseTag.contains("gps") || lowercaseTag.contains("map") { return "📍" }
        if lowercaseTag.contains("address") || lowercaseTag.contains("street") { return "🏘️" }
        if lowercaseTag.contains("city") || lowercaseTag.contains("urban") { return "🏙️" }
        if lowercaseTag.contains("country") || lowercaseTag.contains("nation") { return "🗺️" }
        
        // Time & Calendar
        if lowercaseTag.contains("time") || lowercaseTag.contains("clock") { return "🕐" }
        if lowercaseTag.contains("alarm") { return "⏰" }
        if lowercaseTag.contains("timer") || lowercaseTag.contains("countdown") { return "⏱️" }
        if lowercaseTag.contains("reminder") { return "⏰" }
        if lowercaseTag.contains("birthday") || lowercaseTag.contains("anniversary") { return "🎂" }
        
        // Tools & Utilities
        if lowercaseTag.contains("tool") || lowercaseTag.contains("utility") { return "🔧" }
        if lowercaseTag.contains("search") || lowercaseTag.contains("find") { return "🔍" }
        if lowercaseTag.contains("filter") || lowercaseTag.contains("sort") { return "🔀" }
        if lowercaseTag.contains("copy") || lowercaseTag.contains("duplicate") { return "📋" }
        if lowercaseTag.contains("delete") || lowercaseTag.contains("remove") { return "🗑️" }
        if lowercaseTag.contains("edit") || lowercaseTag.contains("modify") { return "✏️" }
        if lowercaseTag.contains("file") || lowercaseTag.contains("document") { return "📄" }
        if lowercaseTag.contains("folder") || lowercaseTag.contains("directory") { return "📁" }
        
        // Weather & Environment
        if lowercaseTag.contains("sun") || lowercaseTag.contains("sunny") { return "☀️" }
        if lowercaseTag.contains("cloud") || lowercaseTag.contains("cloudy") { return "☁️" }
        if lowercaseTag.contains("rain") || lowercaseTag.contains("rainy") { return "🌧️" }
        if lowercaseTag.contains("snow") || lowercaseTag.contains("winter") { return "❄️" }
        if lowercaseTag.contains("storm") || lowercaseTag.contains("thunder") { return "⛈️" }
        if lowercaseTag.contains("fire") || lowercaseTag.contains("flame") { return "🔥" }
        if lowercaseTag.contains("water") || lowercaseTag.contains("ocean") { return "🌊" }
        if lowercaseTag.contains("earth") || lowercaseTag.contains("planet") { return "🌍" }
        
        // Default emoji for unrecognized tags
        return "🏷️"
    }
}