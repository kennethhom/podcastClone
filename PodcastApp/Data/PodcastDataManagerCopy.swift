//
//  PodcastDataManagerCopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/10/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import Combine

class PodcastDataManagerCopy {
    private let topPodcastsAPI = TopPodcastsAPICopy()
    private let searchClient = PodcastSearchAPICopy()
    
    private var searchClientCancellable: AnyCancellable?
    private var topPodcastCencellable: AnyCancellable?
    
    var dataChangedSearch = PassthroughSubject<Void,PodcastLoadingError>()
    var dataChangedPodcasts = PassthroughSubject<Void, PodcastLoadingError>()
    
    var podcasts: TopPodcastsAPIResponse?
    var searchResults: PodcastSearchAPIResponse?
    
    func fetchTopPodcasts(limit: Int = 100, allowExplicit: Bool = false) {
        topPodcastCencellable = topPodcastsAPI.fetchTopPodcasts(limit: limit, allowExplicit: allowExplicit).receive(on: DispatchQueue.main)
            .mapError { error -> PodcastLoadingError in
                 PodcastLoadingError.convertCopy(from: error)
            }.sink(receiveCompletion: { [weak self] error in
                
                self?.dataChangedPodcasts.send(completion: error)
                self?.dataChangedPodcasts.send()
        }, receiveValue: { [weak self] podcast in
            self?.podcasts = podcast
            self?.dataChangedPodcasts.send()
        })
    }
    
    func search(term: String) {
        searchClientCancellable = searchClient.search(for: term).receive(on: DispatchQueue.main).mapError { error -> PodcastLoadingError in
            PodcastLoadingError.convertCopy(from: error)
       }.sink(receiveCompletion: { [weak self] error in
            self?.dataChangedSearch.send(completion: error)
        }, receiveValue: {
            [weak self] search in
            self?.searchResults = search
            self?.dataChangedSearch.send()
        })
    }
    
    func cancelSearch() {
        searchClientCancellable = nil
    }
    
    
}
