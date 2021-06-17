//
//  NewEpisodes+CoreDataProperties.swift
//  
//
//  Created by Kenneth Hom on 6/14/21.
//
//

import Foundation
import CoreData


extension NewEpisodes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewEpisodes> {
        return NSFetchRequest<NewEpisodes>(entityName: "NewEpisodes")
    }

    @NSManaged public var identifier: String
    @NSManaged public var title: String
    @NSManaged public var publicationDate: Date
    @NSManaged public var enclosureUrl: URL
    @NSManaged public var episodeDescription: String
    @NSManaged public var duration: Double
    @NSManaged public var podcast: NewPodcast
    @NSManaged public var episodeStatus: NewEpisodeStatus?

}
