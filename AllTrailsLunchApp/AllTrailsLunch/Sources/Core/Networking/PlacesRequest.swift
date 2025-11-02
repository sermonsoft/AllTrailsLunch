///
/// `PlacesRequest.swift`
/// AllTrailsLunch
///
/// Request builder for Google Places API calls.
///

import Foundation

struct PlacesRequest {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let timeoutInterval: TimeInterval
    
    func toURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

class PlacesRequestBuilder {
    private var url: URL?
    private var method: HTTPMethod = .get
    private var headers: [String: String] = [:]
    private var timeoutInterval: TimeInterval = 30.0
    
    @discardableResult
    func setURL(_ url: URL) -> Self {
        self.url = url
        return self
    }
    
    @discardableResult
    func setMethod(_ method: HTTPMethod) -> Self {
        self.method = method
        return self
    }
    
    @discardableResult
    func addHeader(_ key: String, value: String) -> Self {
        headers[key] = value
        return self
    }
    
    @discardableResult
    func setHeaders(_ headers: [String: String]) -> Self {
        self.headers = headers
        return self
    }
    
    @discardableResult
    func setTimeoutInterval(_ interval: TimeInterval) -> Self {
        self.timeoutInterval = interval
        return self
    }
    
    func build() throws -> PlacesRequest {
        guard let url = url else {
            throw PlacesError.invalidURL("URL not set")
        }
        
        return PlacesRequest(
            url: url,
            method: method,
            headers: headers,
            timeoutInterval: timeoutInterval
        )
    }
}

