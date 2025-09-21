//
//  ScriptableMessage.swift
//  NtfyMenuBar
//
//  Created by Assistant on 2025-09-21.
//

import Foundation
import Cocoa

@objc(ScriptableMessage)
class ScriptableMessage: NSObject {
    @objc var messageId: String
    @objc var title: String?
    @objc var body: String?
    @objc var topic: String
    @objc var priority: Int
    @objc var date: Date
    @objc var tags: String?

    init(from message: NtfyMessage) {
        self.messageId = message.id
        self.title = message.title
        self.body = message.message
        self.topic = message.topic
        self.priority = message.priority ?? 3
        self.date = message.date
        self.tags = message.tags?.joined(separator: ", ")
        super.init()
    }

    override var objectSpecifier: NSScriptObjectSpecifier? {
        let container = NSApplication.shared

        return NSUniqueIDSpecifier(
            containerClassDescription: container.classDescription as! NSScriptClassDescription,
            containerSpecifier: container.objectSpecifier,
            key: "scriptingMessages",
            uniqueID: messageId
        )
    }
}