//
//  SubscriptionStoreCopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/16/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import CoreData

// this is our copy
class SubscriptionStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func isSubscribed(to id: String) -> Bool {
        do {
            return try findSubscription(with: id) != nil
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    func findSubscription(with podcastId: String) throws -> NewSubscription? {
        let fetch: NSFetchRequest<NewSubscription> = NewSubscription.fetchRequest()
        fetch.fetchLimit = 1
        fetch.predicate = NSPredicate(format: "podcast.id == %@", podcastId)
        return try context.fetch(fetch).first
    }
    
    func fetchSubscriptions() throws -> [NewSubscription] {
        let fetch: NSFetchRequest<NewSubscription> = NewSubscription.fetchRequest()
        fetch.returnsObjectsAsFaults = false
        fetch.relationshipKeyPathsForPrefetching = ["podcast"]
        fetch.sortDescriptors = [NSSortDescriptor(key: "dateSubscribed", ascending: false)]
        return try context.fetch(fetch)
    }
    
    @discardableResult func subscribe(to podcast: Podcast, sender: Any?) throws -> NewSubscription {
        let newPodcast = NewPodcast(context: context)
        newPodcast.artworkURLString = podcast.artworkURL?.absoluteString
        newPodcast.author = podcast.author
        newPodcast.feedURLString = podcast.feedURL.absoluteURL.absoluteString
        newPodcast.genre = podcast.primaryGenre
        newPodcast.id = podcast.id
        newPodcast.podcastDescription = podcast.description
        newPodcast.title = podcast.title
        
        let newSubscription = NewSubscription(context: context)
        newSubscription.dateSubscribed = Date()
        newSubscription.podcast = newPodcast
        
        try context.save()
        
        var changed = SubscriptionsChanged(subscribed: [podcast.id])
        changed.sender = sender
        NotificationCenter.default.post(changed)
        return newSubscription
    }
    
    func unsubscribe(from podcast: Podcast, sender: Any?) throws {
        guard let subscription = try findSubscription(with: podcast.id) else {
            return
        }
        context.delete(subscription)
        try context.save()
        var changed = SubscriptionsChanged(unsubscribed: [podcast.id])
        changed.sender = sender
        NotificationCenter.default.post(changed)
    }
    
    func findPodcast(with podcastId: String) throws -> NewPodcast? {
        let fetch: NSFetchRequest<NewPodcast> = NewPodcast.fetchRequest()
        fetch.fetchLimit = 1
        fetch.predicate = NSPredicate(format: "id == %@", podcastId)
        return try context.fetch(fetch).first
    }
    
    func fetchPlaylist() throws -> [NewEpisodes] {
        return try context.fetch(playlistFetchRequest())
    }
    
    func playlistFetchRequest() -> NSFetchRequest<NewEpisodes> {
        let fetch: NSFetchRequest<NewEpisodes> = NewEpisodes.fetchRequest()
        fetch.predicate = NSPredicate(format: "podcast.subscription != nil")
        fetch.sortDescriptors = [NSSortDescriptor(key: "publicationDate", ascending: false)]
        return fetch
    }
 
    func findCurrentlyPlayingEpisode() throws -> NewEpisodeStatus? {
        let fetch: NSFetchRequest<NewEpisodeStatus> = NewEpisodeStatus.fetchRequest()
        fetch.predicate = NSPredicate(format: "isCurrentlyPlaying == YES")
        fetch.fetchLimit = 1
        return try context.fetch(fetch).first
    }
    
    func getStatus(for episode: Episode) throws -> NewEpisodeStatus? {
        guard let identifier = episode.identifier else {
            return nil
        }
        
        let fetch: NSFetchRequest<NewEpisodes> = NewEpisodes.fetchRequest()
        fetch.predicate = NSPredicate(format: "identifier == %@", identifier)
        fetch.fetchLimit = 1
        
        guard let episodeFetched = try context.fetch(fetch).first else {
            return nil
        }
        
        if let status = episodeFetched.episodeStatus {
            return status
        }
        
        let newStatus = NewEpisodeStatus(context: context)
        newStatus.hasCompleted = false
        newStatus.isCurrentlyPlaying = false
        newStatus.lastListenedTime = 0
        newStatus.lastPlayedAt = Date()
        
        newStatus.episodes = episodeFetched
        return newStatus
    }
}
