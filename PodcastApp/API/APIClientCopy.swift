//
//  APIClientCopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/10/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import Combine

protocol APIClientCopy {
    var session: URLSession {get}
}

class BaseAPIClient: APIClientCopy {
    var session: URLSession
    init(_ session: URLSession = URLSession.shared) {
        self.session = session
    }
}

extension APIClientCopy {
    
    
    func request(url: URLRequest) -> AnyPublisher<Data, APIErrorCopy> {
        return session.dataTaskPublisher(for: url).tryMap() { element -> Data in
            guard let http = element.response as? HTTPURLResponse else {
                throw APIErrorCopy.invalidResponse
            }
            switch http.statusCode {
            case 200:
                return element.data

            case 400...499:
                let body = String(data: element.data, encoding: .utf8)
                throw APIErrorCopy.requestError(http.statusCode, body ?? "<no body>")

            case 500...599:
                throw APIErrorCopy.serverError

            default:
                fatalError("Unhandled HTTP status code: \(http.statusCode)")
            }
        }.catchAPIErrors().eraseToAnyPublisher()
    }
    
    func perform<T: Decodable>(url: URLRequest) -> AnyPublisher<T, APIErrorCopy> {
        return request(url: url).decode(type: T.self, decoder: JSONDecoder()).catchAPIErrors()
        .eraseToAnyPublisher()
    }
}

extension Publisher {
    func catchAPIErrors() -> AnyPublisher<Self.Output,APIErrorCopy> {
        return self.catch { error -> AnyPublisher<Self.Output,APIErrorCopy> in
            if let decodingError = error as? DecodingError {
                return Fail(error: APIErrorCopy.decodingError(decodingError)).eraseToAnyPublisher()
            }
            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    return Fail(error: APIErrorCopy.nothing).eraseToAnyPublisher()
                }
                return Fail(error: APIErrorCopy.networkingError(error)).eraseToAnyPublisher()
            }
            return Fail(error: APIErrorCopy.nothing).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

enum APIErrorCopy : Error {
    case networkingError(Error)
    case serverError // HTTP 5xx
    case requestError(Int, String) // HTTP 4xx
    case invalidResponse
    case decodingError(DecodingError)
    case feedError(Error)
    case nothing

    var localizedDescription: String {
        switch self {
        case .nothing: return ""
        case .networkingError(let error): return "Error sending request: \(error.localizedDescription)"
        case .serverError: return "HTTP 500 Server Error"
        case .requestError(let status, let body): return "HTTP \(status)\n\(body)"
        case .invalidResponse: return "Invalid Response"
        case .feedError(let error): return "Feed Error: \(error.localizedDescription)"
        case .decodingError(let error):

            return "Decoding error: \(error.localizedDescription)"

        }
    }
}
