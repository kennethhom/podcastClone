//
//  ImportEpisodesOperationCopy.swift
//  PodcastApp
//
//  Created by janice ou on 6/17/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import CoreData
import Combine

class ImportEpisodesOperationCopy : BaseOperation {
    
    private var context: NSManagedObjectContext!
    private var store: SubscriptionStore!
    
    private var feedLoader = PodcastFeedLoaderCopy()
    private var cancellable: AnyCancellable?
    
    private let podcastId: String
    private let priority: DispatchQoS.QoSClass
    
    init(podcastId: String, priority: DispatchQoS.QoSClass) {
        self.podcastId = podcastId
        self.priority = priority
    }
    
    override func execute() {
        context = PersistenceManager.shared.newBackgroundContext()
        store = SubscriptionStore(context: context)
        
        print("ImportEpisodes -> Loading podcast: \(podcastId)")
        guard let podcastEntity = try? store.findPodcast(with: podcastId) else {
            finish()
            return
        }
        
        print("ImportEpisodes -> Fetching the feed for \(podcastEntity.title ?? "<?>") - \(podcastEntity.feedURLString ?? "<?>")")
        guard let lookup = podcastEntity.lookupInfo else {
            finish()
            return
        }
        
        feedLoader.fetchFeed(lookup: lookup, priority: priority)
        
        cancellable = feedLoader.podcast.receive(on: DispatchQueue.global(qos: priority)).sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                self.finish()
            case .failure(let error):
                print(error.localizedDescription)
                self.finish()
            }
        }, receiveValue: { podcast in
            self.importEpisodes(podcast, podcastEntity)
            self.saveChanges()
            self.finish()
        })
        
    }
    
    func importEpisodes(_ podcast: Podcast, _ podcastEntity: NewPodcast) {
        var existingEpisodes: [String: NewEpisodes] = [:]
        
        if let episodeEntities = podcastEntity.episodes {
            episodeEntities.forEach { episode in
                if let episode = episode as? NewEpisodes {
                    existingEpisodes[episode.identifier] = episode
                }
            }
        }
        
        for episode in podcast.episodes {
            guard let identifier = episode.identifier else {
                continue
            }
            
            guard let enclosureUrl = episode.enclosureURL else {
                continue
            }
            
            let episodeEntity = existingEpisodes[identifier] ?? NewEpisodes(context: context)
            episodeEntity.duration = episode.duration ?? 0
            episodeEntity.enclosureUrl = enclosureUrl
            episodeEntity.episodeDescription = episode.description ?? ""
            episodeEntity.identifier = identifier
            episodeEntity.publicationDate = episode.publicationDate ?? Date()
            episodeEntity.title = episode.title ?? "Untitled"
            episodeEntity.podcast = podcastEntity
        }
    }
    
    func saveChanges() {
        context.perform { [weak self] in
            do {
                try self?.context.save()
            }
            catch {
                print(error)
            }
        }
    }
}
