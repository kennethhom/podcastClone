//
//  PodcastFeedLoaderCopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/11/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import Combine
import FeedKit

class PodcastFeedLoaderCopy {
    let api = PodcastFeedLoaderApi()
    
    var podcast: AnyPublisher<Podcast, PodcastLoadingError>
    private var feedDidChange = PassthroughSubject<Podcast, PodcastLoadingError>()
    private var cancellable: AnyCancellable? = nil
    var pod: Podcast?
    init() {
        podcast = feedDidChange.eraseToAnyPublisher()

    }
    
    func fetchFeed(lookup: PodcastLookupInfo, priority: DispatchQoS.QoSClass) {
        api.fetchFeed(lookup: lookup, priority: priority)
        cancellable = api.podcast.receive(on: DispatchQueue.global(qos: priority)).mapError { error -> PodcastLoadingError in
            PodcastLoadingError.convertCopy(from: error)
        }.sink(receiveCompletion: { [weak self] completion in
            self?.feedDidChange.send(completion: completion)
            if let pod = self?.pod {
                self?.feedDidChange.send(pod)
            }
            self?.pod = nil
        }, receiveValue: { [weak self] val in
            self?.feedDidChange.send(val)
            self?.pod = val
        })
    }
    
}
