import Foundation

/// A URLProtocol subclass that intercepts network requests for logging.
public final class URLSessionInterceptor: URLProtocol {
    static let handledKey = "Chronicle_Handled"
    static var networkLogger: NetworkLogger?

    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var response: URLResponse?
    private var startTime = Date()

    override public class func canInit(with request: URLRequest) -> Bool {
        guard networkLogger != nil else { return false }
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else {
            return false
        }
        return true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        startTime = Date()
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        dataTask = session.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self else { return }

            if let data {
                self.receivedData.append(data)
                self.client?.urlProtocol(self, didLoad: data)
            }

            if let response {
                self.response = response
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                self.client?.urlProtocolDidFinishLoading(self)
            }

            self.logRequest(error: error)
        }
        dataTask?.resume()
    }

    override public func stopLoading() {
        dataTask?.cancel()
    }

    private func logRequest(error: Error?) {
        guard let logger = Self.networkLogger else { return }

        let endTime = Date()
        let networkLog = NetworkLog(
            url: request.url ?? URL(string: "https://unknown")!,
            method: request.httpMethod ?? "GET",
            requestHeaders: request.allHTTPHeaderFields,
            requestBodySize: request.httpBody?.count,
            statusCode: (response as? HTTPURLResponse)?.statusCode,
            responseHeaders: (response as? HTTPURLResponse)?.allHeaderFields as? [String: String],
            responseBodySize: receivedData.count,
            error: error?.localizedDescription,
            metrics: NetworkMetrics(
                startTime: startTime,
                endTime: endTime,
                bytesSent: Int64(request.httpBody?.count ?? 0),
                bytesReceived: Int64(receivedData.count)
            )
        )
        logger.log(networkLog)
    }
}
