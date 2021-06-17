//
//  NewPodcast+CoreDataProperties.swift
//  
//
//  Created by Kenneth Hom on 6/14/21.
//
//

import Foundation
import CoreData


extension NewPodcast {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewPodcast> {
        return NSFetchRequest<NewPodcast>(entityName: "NewPodcast")
    }

    @NSManaged public var id: String?
    @NSManaged public var artworkURLString: String?
    @NSManaged public var author: String?
    @NSManaged public var feedURLString: String?
    @NSManaged public var podcastDescription: String?
    @NSManaged public var genre: String?
    @NSManaged public var title: String?
    @NSManaged public var subscription: NewSubscription?
    @NSManaged public var episodes: NSSet?

}

// MARK: Generated accessors for episodes
extension NewPodcast {

    @objc(addEpisodesObject:)
    @NSManaged public func addToEpisodes(_ value: NewEpisodes)

    @objc(removeEpisodesObject:)
    @NSManaged public func removeFromEpisodes(_ value: NewEpisodes)

    @objc(addEpisodes:)
    @NSManaged public func addToEpisodes(_ values: NSSet)

    @objc(removeEpisodes:)
    @NSManaged public func removeFromEpisodes(_ values: NSSet)

}
