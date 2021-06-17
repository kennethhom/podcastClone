//
//  TopPodcastsAPICopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/10/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import Combine

class TopPodcastsAPICopy: BaseAPIClient{
    private let baseURL = URL(string: "https://rss.itunes.apple.com/api/v1/us/podcasts/")!
    func fetchTopPodcasts(limit: Int = 100, allowExplicit: Bool = false) -> AnyPublisher<TopPodcastsAPIResponse,APIErrorCopy> {
        let explicit = allowExplicit ? "explicit" : "non-explicit"
        let path = "top-podcasts/all/\(100)/\(explicit).json"
        let url = baseURL.appendingPathComponent(path)
        let request = URLRequest(url: url)

        return perform(url: request)
    }
}

//extension TopPodcastsAPICopy {
    struct TopPodcastsAPIResponse : Decodable {
        let feed: Feed
    }

    struct Feed : Decodable {
        let results: [PodcastResult]
    }

    struct PodcastResult : Decodable {
        let id: String
        let artistName: String
        let name: String
        let artworkUrl100: String
        let genres: [Genre]
    }

    struct Genre: Decodable {
        let name: String
        let genreId: String
    }
//}
