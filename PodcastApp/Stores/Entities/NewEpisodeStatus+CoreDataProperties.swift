//
//  NewEpisodeStatus+CoreDataProperties.swift
//  
//
//  Created by Kenneth Hom on 6/14/21.
//
//

import Foundation
import CoreData


extension NewEpisodeStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewEpisodeStatus> {
        return NSFetchRequest<NewEpisodeStatus>(entityName: "NewEpisodeStatus")
    }

    @NSManaged public var hasCompleted: Bool
    @NSManaged public var lastPlayedAt: Date?
    @NSManaged public var isCurrentlyPlaying: Bool
    @NSManaged public var lastListenedTime: Double
    @NSManaged public var episodes: NewEpisodes?

}
