//
//  PlayerManager.swift
//  PodcastApp
//
//  Created by Kenneth Hom on 6/18/21.
//  Copyright © 2021 NSScreencast. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

class PlayerManager {
    private var player: AVPlayer?
    private var timeObservationToken: Any?
    private var statusObservationToken: Any?
    private let skipTime = CMTime(seconds: 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
    var didBeginAudioSession: AnyPublisher<Void,Error>
    private var didBeginAudioSessionPass = PassthroughSubject<Void,Error>()
    private var subscriptionStore: SubscriptionStore!
    private var episodeStatus: NewEpisodeStatus?
    
    init() {
        didBeginAudioSession = didBeginAudioSessionPass.eraseToAnyPublisher()
        subscriptionStore = SubscriptionStore(context: PersistenceManager.shared.mainContext)
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback)
        try session.setMode(.spokenAudio)
        try session.setActive(true, options: [])
    }
    
    func beginAudioSession() {
        do {
            try configureAudioSession()
            didBeginAudioSessionPass.send(completion: .finished)
        } catch {
            print("ERROR: \(error)")
            didBeginAudioSessionPass.send(completion: .failure(error))
            //showAudioSessionError()
        }
    }
    
    func setEpisode(_ episode: Episode, podcast: Podcast, autoPlay: Bool = true) {
        getEpisodeStatus(for: episode)
        guard let audioURL = episode.enclosureURL else { return }
        beginAudioSession()
        cleanupPlayerState()

        preparePlayer(audioURL: audioURL) {
            if autoPlay {
                self.player?.play()
               // self.togglePlayPauseButton(isPlaying: true)
            }
        }
    }
    
    private func preparePlayer(audioURL: URL, onReady: @escaping () -> Void) {
        let playerItem = AVPlayerItem(url: audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
    }
    
    private func getEpisodeStatus(for episode: Episode) {
        do {

            if let previousStatus = try subscriptionStore.findCurrentlyPlayingEpisode() {
                previousStatus.isCurrentlyPlaying = false
            }

            episodeStatus = try subscriptionStore.getStatus(for: episode)
            episodeStatus?.isCurrentlyPlaying = true
            episodeStatus?.lastPlayedAt = Date()

            try PersistenceManager.shared.mainContext.save()

        } catch {
            print("Error: ", error)
        }

        if episodeStatus == nil {
            print("WARNING: Episode status was not returned. No progress will be saved.")
        }
    }
    
    private func cleanupPlayerState() {
        if player != nil {
            player?.pause()
            if let previousObservation = timeObservationToken {
                player?.removeTimeObserver(previousObservation)
            }
            player = nil
        }
    }

}
