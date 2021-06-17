//
//  PodcastFeedLoaderApi.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/12/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import Combine
import FeedKit

class PodcastFeedLoaderApi {
    let baseAPIClient = BaseAPIClient()
    var podcast: AnyPublisher<Podcast,APIErrorCopy>
    private var parseDidChange = PassthroughSubject<Podcast,APIErrorCopy>()
    private var cancellables: Set<AnyCancellable> = []
    init() {
        podcast = parseDidChange.eraseToAnyPublisher()
    }
    
    func fetchFeed(lookup: PodcastLookupInfo, priority: DispatchQoS.QoSClass) {
        let req = URLRequest(url: lookup.feedURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        baseAPIClient.request(url: req).receive(on: DispatchQueue.global(qos: priority)).sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let _):
                self?.parseDidChange.send(completion: completion)
            }
        }, receiveValue: { val in
            self.loadFeed(data: val, with: lookup)
        }).store(in: &cancellables)
    }
    
    private func loadFeed(data: Data, with lookup: PodcastLookupInfo)   {
        let parser = FeedParser(data: data)
        
        parser.parseAsync { [weak self] parseResult in
            guard let self = self else {
                return
            }
            var result: Podcast? = nil
            var error: APIErrorCopy? = nil
            do {
                switch parseResult {
                case .atom(let atom):
                    result = try self.convert(atom: atom, lookup: lookup)
                case .rss(let rss):
                    result = try self.convert(rss: rss, lookup: lookup)
                case .json(_): fatalError()
                case .failure(let e):
                    error = APIErrorCopy.feedError(e)
                }
            } catch let e as PodcastLoadingError {
                error = APIErrorCopy.feedError(e)
            } catch {
                fatalError()
            }
            if let error = error {
                self.parseDidChange.send(completion: .failure(error))
            } else if let result = result {
                self.parseDidChange.send(result)
            }
        }
    }
    
    private func convert(atom: AtomFeed, lookup: PodcastLookupInfo) throws -> Podcast {
        guard let name = atom.title else { throw PodcastLoadingError.feedMissingData("title")  }

        let author = atom.authors?.compactMap({ $0.name }).joined(separator: ", ") ?? ""

        guard let logoURL = atom.logo.flatMap(URL.init) else {
            throw PodcastLoadingError.feedMissingData("logo")
        }

        let description = atom.subtitle?.value ?? ""

        let p = Podcast(id: lookup.id, feedURL: lookup.feedURL)
        p.title = name
        p.author = author
        p.artworkURL = logoURL
        p.description = description
        p.primaryGenre = atom.categories?.first?.attributes?.label

        p.episodes = (atom.entries ?? []).map { entry in
            let episode = Episode()
            episode.identifier = entry.id
            episode.title = entry.title
            episode.description = entry.summary?.value
            episode.enclosureURL = entry.content?.value.flatMap(URL.init)

            return episode
        }

        print("\(name) convert atom")
        return p
    }

    private func convert(rss: RSSFeed, lookup: PodcastLookupInfo) throws -> Podcast {
        guard let title = rss.title else { throw PodcastLoadingError.feedMissingData("title") }
        guard let author = rss.iTunes?.iTunesAuthor ?? rss.iTunes?.iTunesOwner?.name else {
            throw PodcastLoadingError.feedMissingData("itunes:author, itunes:owner name")
        }
        let description = rss.description ?? ""
        guard let logoURL = rss.iTunes?.iTunesImage?.attributes?.href.flatMap(URL.init) else {
            throw PodcastLoadingError.feedMissingData("itunes:image url")
        }

        let p = Podcast(id: lookup.id, feedURL: lookup.feedURL)
        p.title = title
        p.author = author
        p.artworkURL = logoURL
        p.description = description
        p.primaryGenre = rss.categories?.first?.value ?? rss.iTunes?.iTunesCategories?.first?.attributes?.text

        print("\(title) rss feed")
        p.episodes = (rss.items ?? []).map { item in
            let episode = Episode()
            episode.identifier = item.guid?.value
            episode.title = item.title
            episode.description = item.description
            episode.publicationDate = item.pubDate
            episode.duration = item.iTunes?.iTunesDuration
            episode.enclosureURL = item.enclosure?.attributes?.url.flatMap(URL.init)
            return episode
        }

        return p
    }
    
}

