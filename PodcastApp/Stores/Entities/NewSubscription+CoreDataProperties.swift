//
//  NewSubscription+CoreDataProperties.swift
//  
//
//  Created by Kenneth Hom on 6/14/21.
//
//

import Foundation
import CoreData


extension NewSubscription {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewSubscription> {
        return NSFetchRequest<NewSubscription>(entityName: "NewSubscription")
    }

    @NSManaged public var dateSubscribed: Date?
    @NSManaged public var podcast: NewPodcast?

}
