import Foundation

extension HermesSession {
    public static func from(dict: [String: Any]) -> HermesSession? {
        guard let id = dict["id"] as? String ?? dict["sessionId"] as? String else { return nil }
        return HermesSession(
            id: id,
            source: dict["source"] as? String ?? "",
            userId: dict["userId"] as? String ?? dict["user_id"] as? String,
            model: dict["model"] as? String,
            title: dict["title"] as? String,
            parentSessionId: dict["parentSessionId"] as? String ?? dict["parent_session_id"] as? String,
            startedAt: (dict["startedAt"] as? String).flatMap(ISO8601DateFormatter().date) ?? (dict["started_at"] as? String).flatMap(ISO8601DateFormatter().date),
            endedAt: (dict["endedAt"] as? String).flatMap(ISO8601DateFormatter().date) ?? (dict["ended_at"] as? String).flatMap(ISO8601DateFormatter().date),
            endReason: dict["endReason"] as? String ?? dict["end_reason"] as? String,
            messageCount: dict["messageCount"] as? Int ?? dict["message_count"] as? Int ?? 0,
            toolCallCount: dict["toolCallCount"] as? Int ?? dict["tool_call_count"] as? Int ?? 0,
            inputTokens: dict["inputTokens"] as? Int ?? dict["input_tokens"] as? Int ?? 0,
            outputTokens: dict["outputTokens"] as? Int ?? dict["output_tokens"] as? Int ?? 0,
            cacheReadTokens: dict["cacheReadTokens"] as? Int ?? dict["cache_read_tokens"] as? Int ?? 0,
            cacheWriteTokens: dict["cacheWriteTokens"] as? Int ?? dict["cache_write_tokens"] as? Int ?? 0,
            estimatedCostUSD: dict["estimatedCostUSD"] as? Double ?? dict["estimated_cost_usd"] as? Double,
            reasoningTokens: dict["reasoningTokens"] as? Int ?? dict["reasoning_tokens"] as? Int ?? 0,
            actualCostUSD: dict["actualCostUSD"] as? Double ?? dict["actual_cost_usd"] as? Double,
            costStatus: dict["costStatus"] as? String ?? dict["cost_status"] as? String,
            billingProvider: dict["billingProvider"] as? String ?? dict["billing_provider"] as? String,
            apiCallCount: dict["apiCallCount"] as? Int ?? dict["api_call_count"] as? Int ?? 0
        )
    }
}

extension HermesMessage {
    public static func from(dict: [String: Any]) -> HermesMessage? {
        guard let id = dict["id"] as? Int,
              let role = dict["role"] as? String
        else { return nil }
        var toolCalls: [HermesToolCall] = []
        if let raw = dict["toolCalls"] as? [[String: Any]] ?? dict["tool_calls"] as? [[String: Any]] {
            toolCalls = raw.compactMap(HermesToolCall.from(dict:))
        }
        let content = dict["content"] as? String ?? ""
        return HermesMessage(
            id: id,
            sessionId: dict["sessionId"] as? String ?? dict["session_id"] as? String ?? "",
            role: role,
            content: content,
            toolCallId: dict["toolCallId"] as? String ?? dict["tool_call_id"] as? String,
            toolCalls: toolCalls,
            toolName: dict["toolName"] as? String ?? dict["tool_name"] as? String,
            timestamp: (dict["timestamp"] as? String).flatMap(ISO8601DateFormatter().date),
            tokenCount: dict["tokenCount"] as? Int ?? dict["token_count"] as? Int,
            finishReason: dict["finishReason"] as? String ?? dict["finish_reason"] as? String,
            reasoning: dict["reasoning"] as? String,
            reasoningContent: dict["reasoningContent"] as? String ?? dict["reasoning_content"] as? String
        )
    }
}

extension HermesToolCall {
    public static func from(dict: [String: Any]) -> HermesToolCall? {
        guard let callId = dict["id"] as? String ?? dict["callId"] as? String,
              let function = dict["function"] as? [String: Any],
              let name = function["name"] as? String
        else { return nil }
        let args = (function["arguments"] as? String) ?? ""
        return HermesToolCall(callId: callId, functionName: name, arguments: args)
    }
}

extension HermesCapabilities {
    public static func from(dict: [String: Any]) -> HermesCapabilities? {
        let versionLine = dict["versionLine"] as? String ?? dict["version_line"] as? String ?? ""
        var semver: SemVer?
        var dateVersion: DateVersion?
        if let sv = dict["semver"] as? [String: Any],
           let major = sv["major"] as? Int,
           let minor = sv["minor"] as? Int,
           let patch = sv["patch"] as? Int {
            semver = SemVer(major: major, minor: minor, patch: patch)
        }
        if let dv = dict["dateVersion"] as? [String: Any] ?? dict["date_version"] as? [String: Any],
           let year = dv["year"] as? Int, let month = dv["month"] as? Int, let day = dv["day"] as? Int {
            dateVersion = DateVersion(year: year, month: month, day: day)
        }
        return HermesCapabilities(versionLine: versionLine, semver: semver, dateVersion: dateVersion)
    }
}

extension HermesSkill {
    public static func from(dict: [String: Any]) -> HermesSkill? {
        guard let id = dict["id"] as? String ?? dict["name"] as? String,
              let name = dict["name"] as? String else { return nil }
        return HermesSkill(
            id: id,
            name: name,
            category: dict["category"] as? String ?? "",
            path: dict["path"] as? String ?? "",
            files: dict["files"] as? [String] ?? [],
            requiredConfig: dict["requiredConfig"] as? [String] ?? [],
            allowedTools: dict["allowedTools"] as? [String],
            relatedSkills: dict["relatedSkills"] as? [String],
            dependencies: dict["dependencies"] as? [String],
            enabled: dict["enabled"] as? Bool ?? true,
            pinned: dict["pinned"] as? Bool ?? false
        )
    }
}
