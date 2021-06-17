//
//  PodcastSearchAPICopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/10/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import Combine
class PodcastSearchAPICopy: BaseAPIClient {
    let baseURL = URL(string: "https://itunes.apple.com/")!
    
    func search(for term: String, country: String = "us") -> AnyPublisher<PodcastSearchAPIResponse, APIErrorCopy> {
        let url = URL(string: "search", relativeTo: baseURL)!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "attribute", value: "titleTerm"),
            URLQueryItem(name: "term", value: term)
        ]
        let request = URLRequest(url: components.url!)
        return perform(url: request)
    }
}



//extension PodcastSearchAPICopy {
    struct PodcastSearchAPIResponse: Decodable {
        let results: [PodcastSearchResult]
    }

    struct PodcastSearchResult : Decodable {
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            artistName = try values.decode(String.self, forKey: .artistName)
            collectionId = try values.decode(Int.self, forKey: .collectionId)
            collectionName = try values.decode(String.self, forKey: .collectionName)
            artworkUrl100 = try values.decode(String.self, forKey: .artworkUrl100)
            genreIds = try values.decode(Array<String>.self, forKey: .genreIds)
            genres = try values.decode(Array<String>.self, forKey: .genres)
            feedUrl = (try? values.decode(String.self, forKey: .feedUrl)) ?? ""
        }
        
        enum CodingKeys: String, CodingKey {
            case artistName
            case collectionId
            case collectionName
            case artworkUrl100
            case genreIds
            case genres
            case feedUrl
        }
        
        let artistName: String
        let collectionId: Int
        let collectionName: String
        let artworkUrl100: String
        let genreIds: [String]
        let genres: [String]
        let feedUrl: String
    }
//}

