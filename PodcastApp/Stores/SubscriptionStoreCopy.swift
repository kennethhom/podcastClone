//
//  SubscriptionStoreCopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/16/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import CoreData

class SubscriptionStoreCopy {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func isSubscribed(id: String) -> Bool {
        do {
            return try findSubscription(with: id) != nil
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    func findSubscription(with podcastId: String) throws -> NewSubscription? {
        let fetch = NSFetchRequest<NewSubscription>()
        fetch.fetchLimit = 1
        fetch.predicate = NSPredicate(format: "podcast.id == %@", podcastId)
        return try context.fetch(fetch).first
    }
    
    func fetchSubscriptions() throws -> [NewSubscription] {
        let fetch = NSFetchRequest<NewSubscription>()
        fetch.returnsObjectsAsFaults = false
        fetch.relationshipKeyPathsForPrefetching = ["podcast"]
        fetch.sortDescriptors = [NSSortDescriptor(key: "dateSubscribed", ascending: false)]
        return try context.fetch(fetch)
    }
    
    @discardableResult func subscribe(podcast: Podcast) throws -> NewSubscription {
        let newPodcast = NewPodcast(context: context)
        newPodcast.artworkURLString = podcast.artworkURL?.absoluteString
        newPodcast.author = podcast.author
        newPodcast.feedURLString = podcast.feedURL.absoluteURL.absoluteString
        newPodcast.genre = podcast.primaryGenre
        newPodcast.id = podcast.id
        newPodcast.podcastDescription = podcast.description
        
        let newSubscription = NewSubscription(context: context)
        newSubscription.dateSubscribed = Date()
        newSubscription.podcast = newPodcast
        
        try context.save()
        
        let changed = SubscriptionsChanged(subscribed: [podcast.id])
        NotificationCenter.default.post(changed)
        return newSubscription
    }
    
    func unsubscribed(podcast: Podcast) throws {
        guard let subscription = try findSubscription(with: podcast.id) else {
            return
        }
        context.delete(subscription)
        try context.save()
        let changed = SubscriptionsChanged(unsubscribed: [podcast.id])
        NotificationCenter.default.post(changed)
    }
    
    func findPodcast(with podcastId: String) throws -> NewPodcast? {
        let fetch = NSFetchRequest<NewPodcast>()
        fetch.fetchLimit = 1
        fetch.predicate = NSPredicate(format: "id == %@", podcastId)
        return try context.fetch(fetch).first
    }
    
    
}
