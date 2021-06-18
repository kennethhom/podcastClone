//
//  NewPodcast+CoreDataClass.swift
//  
//
//  Created by Kenneth Hom on 6/14/21.
//
//

import Foundation
import CoreData

@objc(NewPodcast)
public class NewPodcast: NSManagedObject {
    var artworkURL: URL? {
        return artworkURLString.flatMap(URL.init)
    }
    
    var lookupInfo: PodcastLookupInfo? {
        guard let id = id else { return nil }
        guard let feedUrl = feedURLString.flatMap(URL.init) else { return nil }
        return PodcastLookupInfo(id: id, feedURL: feedUrl)
    }
}

extension NewPodcast : PodcastCellModel {
    var titleText: String? { return title }
    var authorText: String? { return author }
    var artwork: URL? { return artworkURL }
}
