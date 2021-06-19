//
//  FeedImporterCopy.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/18/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import CoreData

class FeedImporter {
    static let shared = FeedImporter()
    private var notificationObserver: NSObjectProtocol?
    private var context: NSManagedObjectContext!
    private var store: SubscriptionStore!
    
    lazy var pq: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    lazy var bq: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .background
        return queue
    }()
    
    func startListening() {
        notificationObserver = NotificationCenter.default.addObserver(SubscriptionsChanged.self, sender: nil, queue: nil) { notification in
            self.subscribe(podcastIds: notification.subscribedIds)
        }
    }
    
    
    func updatePodcasts(){
        bq.addOperation {
            self.context = PersistenceManager.shared.newBackgroundContext()
            self.store = SubscriptionStore(context: self.context)
            do {
                let subscriptions = try self.store.fetchSubscriptions()
                for sub in subscriptions {
                    let podcast = sub.podcast
                    if let id = podcast?.id {
                        let importEpisodeOp = ImportEpisodesOperationCopy(podcastId: id, priority: .background)
                        self.bq.addOperation(importEpisodeOp)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func subscribe(podcastIds: Set<String>) {
        for id in podcastIds {
            let importEpisodeOp = ImportEpisodesOperationCopy(podcastId: id, priority: .userInitiated)
            pq.addOperation(importEpisodeOp)
        }
    }
}
