//
//  NetworkLogger.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation

/// Thread-safe network logger with per-request ordering
class NetworkLogger {
    
    // MARK: - Singleton
    
    static let shared = NetworkLogger()
    
    // MARK: - Properties
    
    private let queue = DispatchQueue(label: "com.alltrails.networklogger", qos: .utility)
    private var requestCounter: Int = 0
    private let isEnabled: Bool
    
    // MARK: - Configuration
    
    enum LogLevel {
        case none
        case minimal    // Only URL and status code
        case standard   // URL, status, headers
        case verbose    // Everything including body
    }
    
    private let logLevel: LogLevel
    
    // MARK: - Initialization
    
    private init() {
        // Enable logging in DEBUG builds only
        #if DEBUG
        self.isEnabled = true
        self.logLevel = .verbose
        #else
        self.isEnabled = false
        self.logLevel = .none
        #endif
    }
    
    // MARK: - Request Context
    
    /// Context for a single request to keep logs grouped
    struct RequestContext {
        let id: Int
        let startTime: Date
        let url: URL
        let method: String
        
        var identifier: String {
            "[\(id)]"
        }
    }
    
    // MARK: - Public Logging Methods
    
    /// Log the start of a request
    func logRequest(_ request: URLRequest) -> RequestContext {
        guard isEnabled, logLevel != .none else {
            return RequestContext(id: 0, startTime: Date(), url: request.url!, method: request.httpMethod ?? "GET")
        }
        
        return queue.sync {
            requestCounter += 1
            let context = RequestContext(
                id: requestCounter,
                startTime: Date(),
                url: request.url!,
                method: request.httpMethod ?? "GET"
            )
            
            logRequestStart(context, request: request)
            return context
        }
    }
    
    /// Log a successful response
    func logResponse(_ context: RequestContext, response: HTTPURLResponse, data: Data?) {
        guard isEnabled, logLevel != .none else { return }
        
        queue.async {
            self.logResponseSuccess(context, response: response, data: data)
        }
    }
    
    /// Log a failed request
    func logError(_ context: RequestContext, error: Error, response: HTTPURLResponse? = nil, data: Data? = nil) {
        guard isEnabled, logLevel != .none else { return }
        
        queue.async {
            self.logResponseError(context, error: error, response: response, data: data)
        }
    }
    
    /// Log a retry attempt
    func logRetry(_ context: RequestContext, attempt: Int, delay: TimeInterval) {
        guard isEnabled, logLevel != .none else { return }
        
        queue.async {
            let duration = Date().timeIntervalSince(context.startTime)
            print("⚠️ \(context.identifier) RETRY #\(attempt) after \(String(format: "%.2f", delay))s (elapsed: \(String(format: "%.3f", duration))s)")
        }
    }
    
    // MARK: - Private Logging Implementation
    
    private func logRequestStart(_ context: RequestContext, request: URLRequest) {
        let separator = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        print("\n\(separator)")
        print("🚀 \(context.identifier) REQUEST START")
        print("\(separator)")
        print("📍 Method:    \(context.method)")
        print("📍 URL:       \(context.url.absoluteString)")
        print("📍 Timestamp: \(formatTimestamp(context.startTime))")
        
        if logLevel == .standard || logLevel == .verbose {
            logHeaders(context, headers: request.allHTTPHeaderFields)
        }
        
        if logLevel == .verbose {
            logRequestBody(context, request: request)
        }
        
        print("\(separator)\n")
    }
    
    private func logResponseSuccess(_ context: RequestContext, response: HTTPURLResponse, data: Data?) {
        let duration = Date().timeIntervalSince(context.startTime)
        let separator = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        print("\n\(separator)")
        print("✅ \(context.identifier) RESPONSE SUCCESS")
        print("\(separator)")
        print("📍 Status:    \(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
        print("📍 Duration:  \(String(format: "%.3f", duration))s")
        print("📍 URL:       \(context.url.absoluteString)")
        
        if let data = data {
            print("📍 Size:      \(formatBytes(data.count))")
        }
        
        if logLevel == .standard || logLevel == .verbose {
            logHeaders(context, headers: response.allHeaderFields as? [String: String])
        }
        
        if logLevel == .verbose {
            logResponseBody(context, data: data, statusCode: response.statusCode)
        }
        
        print("\(separator)\n")
    }
    
    private func logResponseError(_ context: RequestContext, error: Error, response: HTTPURLResponse?, data: Data?) {
        let duration = Date().timeIntervalSince(context.startTime)
        let separator = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        print("\n\(separator)")
        print("❌ \(context.identifier) RESPONSE ERROR")
        print("\(separator)")
        
        if let response = response {
            print("📍 Status:    \(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
        }
        
        print("📍 Duration:  \(String(format: "%.3f", duration))s")
        print("📍 URL:       \(context.url.absoluteString)")
        print("📍 Error:     \(error.localizedDescription)")
        
        if let nsError = error as NSError? {
            print("📍 Domain:    \(nsError.domain)")
            print("📍 Code:      \(nsError.code)")
        }
        
        if logLevel == .standard || logLevel == .verbose {
            if let response = response {
                logHeaders(context, headers: response.allHeaderFields as? [String: String])
            }
        }
        
        if logLevel == .verbose {
            logResponseBody(context, data: data, statusCode: response?.statusCode)
        }
        
        print("\(separator)\n")
    }
    
    // MARK: - Helper Methods
    
    private func logHeaders(_ context: RequestContext, headers: [String: String]?) {
        guard let headers = headers, !headers.isEmpty else { return }
        
        print("📋 Headers:")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            // Mask sensitive headers
            let maskedValue = shouldMaskHeader(key) ? "***REDACTED***" : value
            print("   \(key): \(maskedValue)")
        }
    }
    
    private func logRequestBody(_ context: RequestContext, request: URLRequest) {
        guard let body = request.httpBody else { return }
        
        print("📦 Request Body (\(formatBytes(body.count))):")
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: body),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print(prettyString)
        } else if let bodyString = String(data: body, encoding: .utf8) {
            print(bodyString)
        } else {
            print("   <Binary data: \(formatBytes(body.count))>")
        }
    }
    
    private func logResponseBody(_ context: RequestContext, data: Data?, statusCode: Int?) {
        guard let data = data, !data.isEmpty else {
            print("📦 Response Body: <empty>")
            return
        }
        
        print("📦 Response Body (\(formatBytes(data.count))):")
        
        // Try to parse as JSON
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
            if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                // Limit output to first 100 lines for very large responses
                let lines = prettyString.components(separatedBy: .newlines)
                if lines.count > 100 {
                    let truncated = lines.prefix(100).joined(separator: "\n")
                    print(truncated)
                    print("   ... (\(lines.count - 100) more lines truncated)")
                } else {
                    print(prettyString)
                }
            }
        } else if let bodyString = String(data: data, encoding: .utf8) {
            // Plain text response
            let lines = bodyString.components(separatedBy: .newlines)
            if lines.count > 100 {
                let truncated = lines.prefix(100).joined(separator: "\n")
                print(truncated)
                print("   ... (\(lines.count - 100) more lines truncated)")
            } else {
                print(bodyString)
            }
        } else {
            print("   <Binary data: \(formatBytes(data.count))>")
        }
    }
    
    private func shouldMaskHeader(_ key: String) -> Bool {
        let sensitiveHeaders = ["authorization", "api-key", "x-api-key", "cookie", "set-cookie"]
        return sensitiveHeaders.contains(key.lowercased())
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

