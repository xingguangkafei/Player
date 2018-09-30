//  Player.swift
//
//  Created by patrick piemonte on 11/26/14.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014-present patrick piemonte (http://patrickpiemonte.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//

/*
 Permission n. 允许，许可
 hereby adv. 以此方式，据此；特此
 granted vt. 授予；允许；承认
 obtaining  n. 得到，获取
 furnished ：adj. 家具，有家具的  v. 供应；装备（furnish的过去分词）
 sublicense： vt. 给……发从属证书（或执照、许可证等）n. （证书持有者发给其他人的）从属证书（（或执照、许可证等）
 subject n. 主题；科目；[语] 主语；国民 adj. 服从的；易患…的；受制于…的 vt. 使…隶属；使屈从于…
 
 许可特此授权：
 1，免费给所有人获取本软件和其关联的文档
 2，为了免费，无限制的使用，复制，修改，合并，发布, 颁发证书或者售卖软件，或者教人使用，等等
 要做到以上两点，要遵守以下条件
 */
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
/*
 copyright n. 版权，著作权 adj. 版权的；受版权保护的 vt. 保护版权；为…取得版权
 substantial adj. 大量的；实质的；内容充实的 n. 本质；重要材料
 portions n. 部分（portion的复数形式）；加大份量 v. 将…分配（portion的第三人称单数形式）
 
 以上版权注意事项，和授权注意事项，应该在本软件的所有复制或者部分代码里都生效
 */
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
/*
 as is : 按照原来样子的
 express: vt. 表达；快递 adj. 明确的；迅速的；专门的 n. 快车，快递，专使；捷运公司
 implied vt. 暗示；意味（imply的过去式） adj. 含蓄的；暗指的
 warranties n. 担保；特约条款（warranty的复数）
 merchantability  n. 适销性，可销性
 particular adj. 特别的；详细的；独有的；挑剔的 n. 详细说明；个别项目
 Non-infringement ： declaration of noninfringement 非侵权申明
 
 
 这个软件 是按照原来的样子提供的，不用担心任何形式的，表达，暗示，包括但不限于特约条款的可售性
 
 适合于特别目的，和非侵权。
 在任何情况下，作者或版权所有人都不应对任何索赔、损害赔偿或其他责任承担责任，无论是在合同、侵权诉讼中，还是在其他情况下，由软件或软件的使用或其他交易引起的。
 */

import UIKit
import Foundation
import AVFoundation
import CoreGraphics

// MARK: - types

/// Video fill mode options for `Player.fillMode`.
///
/// - resize: Stretch to fill. 拉伸画面变形到填满屏幕
/// - resizeAspectFill: Preserve aspect ratio, filling bounds.  保持长宽比，填充边界。
/// - resizeAspectFit: Preserve aspect ratio, fill within bounds. 保持长宽比，在范围内填充。
public typealias PlayerFillMode = AVLayerVideoGravity

/*
 CustomStringConvertible 自定义字符串转换
 这个类里有一个协议，让
 */
/// Asset playback states. 资源播放状态。
public enum PlaybackState: Int, CustomStringConvertible {
    case stopped = 0
    case playing
    case paused
    case failed

    public var description: String {
        get {
            switch self {
            case .stopped:
                return "Stopped"
            case .playing:
                return "Playing"
            case .failed:
                return "Failed"
            case .paused:
                return "Paused"
            }
        }
    }
}

/// Asset buffering states.资源缓存状态。
public enum BufferingState: Int, CustomStringConvertible {
    case unknown = 0
    case ready
    case delayed

    public var description: String {
        get {
            switch self {
            case .unknown:
                return "Unknown"
            case .ready:
                return "Ready"
            case .delayed:
                return "Delayed"
            }
        }
    }
}
// MARK: - error types

/// Error domain for all Player errors. 所有播放器错误的错误域。
public let PlayerErrorDomain = "PlayerErrorDomain"

/// Error types. 错误类型。
public enum PlayerError: Error, CustomStringConvertible {
    case failed

    public var description: String {
        get {
            switch self {
            case .failed:
                return "failed"
            }
        }
    }
}

// MARK: - PlayerDelegate

/// Player delegate protocol
public protocol PlayerDelegate: AnyObject {
    func playerReady(_ player: Player)
    func playerPlaybackStateDidChange(_ player: Player)
    func playerBufferingStateDidChange(_ player: Player)

    /*
     这是以秒为单位的视频缓冲时间。
     如果是用实现UIProgressView，用value / player.maximumDuration 来设置进度的最大持续时间。
     */
    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set progress.
    func playerBufferTimeDidChange(_ bufferTime: Double)

    func player(_ player: Player, didFailWithError error: Error?)
}


/// Player playback protocol
public protocol PlayerPlaybackDelegate: AnyObject {
    func playerCurrentTimeDidChange(_ player: Player)
    func playerPlaybackWillStartFromBeginning(_ player: Player)
    func playerPlaybackDidEnd(_ player: Player)
    func playerPlaybackWillLoop(_ player: Player)
}

// MARK: - Player
/*
 1、private
 private访问级别所修饰的属性或者方法只能在当前类里访问。
 
 2、fileprivate
 fileprivate访问级别所修饰的属性或者方法在当前的Swift源文件里可以访问。
 
 3、internal（默认访问级别，internal修饰符可写可不写）
 internal访问级别所修饰的属性或方法在源代码所在的整个模块都可以访问。
 如果是框架或者库代码，则在整个框架内部都可以访问，框架由外部代码所引用时，则不可以访问。
 如果是App代码，也是在整个App代码，也是在整个App内部可以访问。
 
 4、public
 可以被任何人访问。但其他module中不可以被override和继承，而在module内可以被override和继承。
 
 5，open
 可以被任何人使用，包括override和继承。
 
 访问顺序：
 现在的访问权限则依次为：open，public，internal，fileprivate，private。 
 */
/// ▶️ Player, simple way to play and stream media
open class Player: UIViewController {

    /// Player delegate.
    open weak var playerDelegate: PlayerDelegate?

    /// Playback delegate.
    open weak var playbackDelegate: PlayerPlaybackDelegate?

    // configuration

    /// Local or remote URL for the file asset to be played.
    ///
    /// - Parameter url: URL of the asset.
    open var url: URL? {
        didSet {
            setup(url: url)
        }
    }

    /// For setting up with AVAsset instead of URL
    /// Note: Resets URL (cannot set both)
    open var asset: AVAsset? {
        get { return _asset }
        set { _ = newValue.map { setupAsset($0) } }
    }

    /// Specifies how the video is displayed within a player layer’s bounds.
    /// The default value is `AVLayerVideoGravityResizeAspect`. See `PlayerFillMode`.
    open var fillMode: PlayerFillMode {
        get {
            return self._playerView.playerFillMode
        }
        set {
            self._playerView.playerFillMode = newValue
        }
    }

    /// Determines if the video should autoplay when a url is set
    ///
    /// - Parameter bool: defaults to true
    open var autoplay: Bool = true

    /// Mutes audio playback when true.
    open var muted: Bool {
        get {
            return self._avplayer.isMuted
        }
        set {
            self._avplayer.isMuted = newValue
        }
    }

    /// Volume for the player, ranging from 0.0 to 1.0 on a linear scale.
    open var volume: Float {
        get {
            return self._avplayer.volume
        }
        set {
            self._avplayer.volume = newValue
        }
    }

    /// Pauses playback automatically when resigning active.
    open var playbackPausesWhenResigningActive: Bool = true

    /// Pauses playback automatically when backgrounded.
    open var playbackPausesWhenBackgrounded: Bool = true

    /// Resumes playback when became active.
    open var playbackResumesWhenBecameActive: Bool = true

    /// Resumes playback when entering foreground.
    open var playbackResumesWhenEnteringForeground: Bool = true

    // state

    /// Playback automatically loops continuously when true.
    open var playbackLoops: Bool {
        get {
            return self._avplayer.actionAtItemEnd == .none
        }
        set {
            if newValue {
                self._avplayer.actionAtItemEnd = .none
            } else {
                self._avplayer.actionAtItemEnd = .pause
            }
        }
    }

    /// Playback freezes on last frame frame at end when true.
    open var playbackFreezesAtEnd: Bool = false

    /// Current playback state of the Player.
    open var playbackState: PlaybackState = .stopped {
        didSet {
            if playbackState != oldValue || !playbackEdgeTriggered {
                self.playerDelegate?.playerPlaybackStateDidChange(self)
            }
        }
    }

    /// Current buffering state of the Player.
    open var bufferingState: BufferingState = .unknown {
        didSet {
            if bufferingState != oldValue || !playbackEdgeTriggered {
                self.playerDelegate?.playerBufferingStateDidChange(self)
            }
        }
    }

    /// Playback buffering size in seconds.
    open var bufferSizeInSeconds: Double = 10

    /// Playback is not automatically triggered from state changes when true.
    open var playbackEdgeTriggered: Bool = true

    /// Maximum duration of playback.
    open var maximumDuration: TimeInterval {
        get {
            if let playerItem = self._playerItem {
                return CMTimeGetSeconds(playerItem.duration)
            } else {
                return CMTimeGetSeconds(CMTime.indefinite)
            }
        }
    }

    /// Media playback's current time.
    open var currentTime: TimeInterval {
        get {
            if let playerItem = self._playerItem {
                return CMTimeGetSeconds(playerItem.currentTime())
            } else {
                return CMTimeGetSeconds(CMTime.indefinite)
            }
        }
    }

    /// The natural dimensions of the media.
    open var naturalSize: CGSize {
        get {
            if let playerItem = self._playerItem,
                let track = playerItem.asset.tracks(withMediaType: .video).first {

                let size = track.naturalSize.applying(track.preferredTransform)
                return CGSize(width: abs(size.width), height: abs(size.height))
            } else {
                return CGSize.zero
            }
        }
    }

    /// self.view as PlayerView type
    public var playerView: PlayerView {
        get {
            return self._playerView
        }
    }

    /// Return the av player layer for consumption by things such as Picture in Picture
    open func playerLayer() -> AVPlayerLayer? {
        return self._playerView.playerLayer
    }

    /// Indicates the desired limit of network bandwidth consumption for this item.
    open var preferredPeakBitRate: Double = 0 {
        didSet {
            self._playerItem?.preferredPeakBitRate = self.preferredPeakBitRate
        }
    }

    /// Indicates a preferred upper limit on the resolution of the video to be downloaded.
    @available(iOS 11.0, tvOS 11.0, *)
    open var preferredMaximumResolution: CGSize {
        get {
            return self._playerItem?.preferredMaximumResolution ?? CGSize.zero
        }
        set {
            self._playerItem?.preferredMaximumResolution = newValue
            self._preferredMaximumResolution = newValue
        }
    }

    // MARK: - private instance vars

    internal var _asset: AVAsset? {
        didSet {
            if let _ = self._asset {
                self.setupPlayerItem(nil)
            }
        }
    }
    internal var _avplayer: AVPlayer = AVPlayer()
    internal var _playerItem: AVPlayerItem?

    internal var _playerObservers = [NSKeyValueObservation]()
    internal var _playerItemObservers = [NSKeyValueObservation]()
    internal var _playerLayerObserver: NSKeyValueObservation?
    internal var _playerTimeObserver: Any?

    internal var _playerView: PlayerView = PlayerView(frame: .zero)
    internal var _seekTimeRequested: CMTime?
    internal var _lastBufferTime: Double = 0
    internal var _preferredMaximumResolution: CGSize = .zero

    // Boolean that determines if the user or calling coded has trigged autoplay manually.
    internal var _hasAutoplayActivated: Bool = true

    // MARK: - object lifecycle

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        self._avplayer.actionAtItemEnd = .pause
        super.init(coder: aDecoder)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self._avplayer.actionAtItemEnd = .pause
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        self._avplayer.pause()
        self.setupPlayerItem(nil)

        self.removePlayerObservers()

        self.playerDelegate = nil
        self.removeApplicationObservers()

        self.playbackDelegate = nil
        self.removePlayerLayerObservers()

        self._playerView.player = nil
    }

    // MARK: - view lifecycle

    open override func loadView() {
        super.loadView()
        self._playerView.frame = self.view.bounds
        self.view = self._playerView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if let url = url {
            setup(url: url)
        } else if let asset = asset {
            setupAsset(asset)
        }

        self.addPlayerLayerObservers()
        self.addPlayerObservers()
        self.addApplicationObservers()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.playbackState == .playing {
            self.pause()
        }
    }

}

// MARK: - action funcs

extension Player {

    /// Begins playback of the media from the beginning.
    open func playFromBeginning() {
        self.playbackDelegate?.playerPlaybackWillStartFromBeginning(self)
        self._avplayer.seek(to: CMTime.zero)
        self.playFromCurrentTime()
    }

    /// Begins playback of the media from the current time.
    open func playFromCurrentTime() {
        if !self.autoplay {
            //external call to this method with auto play off.  activate it before calling play
            self._hasAutoplayActivated = true
        }
        self.play()
    }

    fileprivate func play() {
        if self.autoplay || self._hasAutoplayActivated {
            self.playbackState = .playing
            self._avplayer.play()
        }
    }

    /// Pauses playback of the media.
    open func pause() {
        if self.playbackState != .playing {
            return
        }

        self._avplayer.pause()
        self.playbackState = .paused
    }

    /// Stops playback of the media.
    open func stop() {
        if self.playbackState == .stopped {
            return
        }

        self._avplayer.pause()
        self.playbackState = .stopped
        self.playbackDelegate?.playerPlaybackDidEnd(self)
    }

    /// Updates playback to the specified time.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - completionHandler: Call block handler after seeking/
    open func seek(to time: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        if let playerItem = self._playerItem {
            return playerItem.seek(to: time, completionHandler: completionHandler)
        } else {
            _seekTimeRequested = time
        }
    }

    /// Updates the playback time to the specified time bound.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - toleranceBefore: The tolerance allowed before time.
    ///   - toleranceAfter: The tolerance allowed after time.
    ///   - completionHandler: call block handler after seeking
    open func seekToTime(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        if let playerItem = self._playerItem {
            return playerItem.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
        }
    }

    /// Captures a snapshot of the current Player asset.
    ///
    /// - Parameter completionHandler: Returns a UIImage of the requested video frame. (Great for thumbnails!)
    open func takeSnapshot(completionHandler: ((_ image: UIImage?, _ error: Error?) -> Void)? ) {
        guard let asset = self._playerItem?.asset else {
            DispatchQueue.main.async {
                completionHandler?(nil, nil)
            }
            return
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let currentTime = self._playerItem?.currentTime() ?? CMTime.zero

        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: currentTime)]) { (requestedTime, image, actualTime, result, error) in
            if let image = image {
                switch result {
                case .succeeded:
                    let uiimage = UIImage(cgImage: image)
                    DispatchQueue.main.async {
                        completionHandler?(uiimage, nil)
                    }
                    break
                case .failed:
                    fallthrough
                case .cancelled:
                    DispatchQueue.main.async {
                        completionHandler?(nil, nil)
                    }
                    break
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler?(nil, error)
                }
            }
        }
    }

}

// MARK: - loading funcs

extension Player {

    fileprivate func setup(url: URL?) {
        guard isViewLoaded else { return }

        // ensure everything is reset beforehand
        if self.playbackState == .playing {
            self.pause()
        }

        //Reset autoplay flag since a new url is set.
        self._hasAutoplayActivated = false
        if self.autoplay {
            self.playbackState = .playing
        } else {
            self.playbackState = .stopped
        }

        self.setupPlayerItem(nil)

        if let url = url {
            let asset = AVURLAsset(url: url, options: .none)
            self.setupAsset(asset)
        }
    }

    fileprivate func setupAsset(_ asset: AVAsset, loadableKeys: [String] = ["tracks", "playable", "duration"]) {
        guard isViewLoaded else { return }

        if self.playbackState == .playing {
            self.pause()
        }

        self.bufferingState = .unknown

        self._asset = asset

        self._asset?.loadValuesAsynchronously(forKeys: loadableKeys, completionHandler: { () -> Void in
            if let asset = self._asset {
                for key in loadableKeys {
                    var error: NSError? = nil
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    if status == .failed {
                        self.playbackState = .failed
                        self.executeClosureOnMainQueueIfNecessary {
                            self.playerDelegate?.player(self, didFailWithError: PlayerError.failed)
                        }
                        return
                    }
                }

                if !asset.isPlayable {
                    self.playbackState = .failed
                    self.executeClosureOnMainQueueIfNecessary {
                        self.playerDelegate?.player(self, didFailWithError: PlayerError.failed)
                    }
                    return
                }

                let playerItem = AVPlayerItem(asset:asset)
                self.setupPlayerItem(playerItem)
            }
        })
    }

    fileprivate func setupPlayerItem(_ playerItem: AVPlayerItem?) {

        self.removePlayerItemObservers()

        if let currentPlayerItem = self._playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentPlayerItem)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: currentPlayerItem)
        }

        self._playerItem = playerItem

        self._playerItem?.preferredPeakBitRate = self.preferredPeakBitRate
        if #available(iOS 11.0, tvOS 11.0, *) {
            self._playerItem?.preferredMaximumResolution = self._preferredMaximumResolution
        }

        if let seek = self._seekTimeRequested, self._playerItem != nil {
            self._seekTimeRequested = nil
            self.seek(to: seek)
        }

        if let updatedPlayerItem = self._playerItem {
            self.addPlayerItemObservers()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: updatedPlayerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: updatedPlayerItem)
        }

        self._avplayer.replaceCurrentItem(with: self._playerItem)

        // update new playerItem settings
        if self.playbackLoops {
            self._avplayer.actionAtItemEnd = .none
        } else {
            self._avplayer.actionAtItemEnd = .pause
        }
    }

}

// MARK: - NSNotifications

extension Player {

    // MARK: - UIApplication

    internal func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    internal func removeApplicationObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVPlayerItem handlers

    @objc internal func playerItemDidPlayToEndTime(_ aNotification: Notification) {
        self.executeClosureOnMainQueueIfNecessary {
            if self.playbackLoops {
                self.playbackDelegate?.playerPlaybackWillLoop(self)
                self._avplayer.pause()
                self._avplayer.seek(to: CMTime.zero)
                self._avplayer.play()
            } else if self.playbackFreezesAtEnd {
                self.stop()
            } else {
                self._avplayer.seek(to: CMTime.zero, completionHandler: { _ in
                    self.stop()
                })
            }
        }
    }

    @objc internal func playerItemFailedToPlayToEndTime(_ aNotification: Notification) {
        self.playbackState = .failed
    }

    // MARK: - UIApplication handlers

    @objc internal func handleApplicationWillResignActive(_ aNotification: Notification) {
        if self.playbackState == .playing && self.playbackPausesWhenResigningActive {
            self.pause()
        }
    }

    @objc internal func handleApplicationDidBecomeActive(_ aNotification: Notification) {
        if self.playbackState == .paused && self.playbackResumesWhenBecameActive {
            self.play()
        }
    }

    @objc internal func handleApplicationDidEnterBackground(_ aNotification: Notification) {
        if self.playbackState == .playing && self.playbackPausesWhenBackgrounded {
            self.pause()
        }
    }

    @objc internal func handleApplicationWillEnterForeground(_ aNoticiation: Notification) {
        if self.playbackState != .playing && self.playbackResumesWhenEnteringForeground {
            self.play()
        }
    }

}

// MARK: - KVO

extension Player {

    // MARK: - AVPlayerItemObservers

    internal func addPlayerItemObservers() {
        guard let playerItem = self._playerItem else {
            return
        }

        self._playerItemObservers.append(playerItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] (object, change) in
            if object.isPlaybackBufferEmpty {
                self?.bufferingState = .delayed
            }

            switch object.status {
            case .readyToPlay:
                self?._playerView.player = self?._avplayer
            case .failed:
                self?.playbackState = PlaybackState.failed
            default:
                break
            }
        })

        self._playerItemObservers.append(playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old]) { [weak self] (object, change) in
            if object.isPlaybackLikelyToKeepUp {
                self?.bufferingState = .ready
                if self?.playbackState == .playing {
                    self?.playFromCurrentTime()
                }
            }

            switch object.status {
            case .readyToPlay:
                self?._playerView.player = self?._avplayer
            case .failed:
                self?.playbackState = PlaybackState.failed
            default:
                break
            }
        })

//        self._playerItemObservers.append(playerItem.observe(\.status, options: [.new, .old]) { (object, change) in
//        })

        self._playerItemObservers.append(playerItem.observe(\.loadedTimeRanges, options: [.new, .old]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }

            strongSelf.bufferingState = .ready

            let timeRanges = object.loadedTimeRanges
            if let timeRange = timeRanges.first?.timeRangeValue {
                let bufferedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
                if strongSelf._lastBufferTime != bufferedTime {
                    strongSelf._lastBufferTime = bufferedTime
                    strongSelf.executeClosureOnMainQueueIfNecessary {
                        strongSelf.playerDelegate?.playerBufferTimeDidChange(bufferedTime)
                    }
                }
            }

            let currentTime = CMTimeGetSeconds(object.currentTime())
            let passedTime = strongSelf._lastBufferTime <= 0 ? currentTime : (strongSelf._lastBufferTime - currentTime)

            if (passedTime >= strongSelf.bufferSizeInSeconds ||
                strongSelf._lastBufferTime == strongSelf.maximumDuration ||
                timeRanges.first == nil) &&
                strongSelf.playbackState == .playing {
                strongSelf.play()
            }
        })
    }

    internal func removePlayerItemObservers() {
        for observer in self._playerItemObservers {
            observer.invalidate()
        }
        self._playerItemObservers.removeAll()
    }

    // MARK: - AVPlayerLayerObservers

    internal func addPlayerLayerObservers() {
        self._playerLayerObserver = self._playerView.playerLayer.observe(\.isReadyForDisplay, options: [.new, .old]) { [weak self] (object, change) in
            self?.executeClosureOnMainQueueIfNecessary {
                if let strongSelf = self {
                    strongSelf.playerDelegate?.playerReady(strongSelf)
                }
            }
        }
    }

    internal func removePlayerLayerObservers() {
        self._playerLayerObserver?.invalidate()
        self._playerLayerObserver = nil
    }

    // MARK: - AVPlayerObservers

    internal func addPlayerObservers() {
        self._playerTimeObserver = self._avplayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main, using: { [weak self] timeInterval in
            guard let strongSelf = self else {
                return
            }
            strongSelf.playbackDelegate?.playerCurrentTimeDidChange(strongSelf)
        })

        if #available(iOS 10.0, tvOS 10.0, *) {
            self._playerObservers.append(self._avplayer.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (object, change) in
                switch object.timeControlStatus {
                case .paused:
                    self?.playbackState = .paused
                case .playing:
                    self?.playbackState = .playing
                default:
                    break
                }
            })
        }

    }

    internal func removePlayerObservers() {
        if let observer = self._playerTimeObserver {
            self._avplayer.removeTimeObserver(observer)
        }
        for observer in self._playerObservers {
            observer.invalidate()
        }
        self._playerObservers.removeAll()
    }

}

// MARK: - queues

extension Player {

    internal func executeClosureOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }

}

// MARK: - PlayerView

public class PlayerView: UIView {

    // MARK: - overrides

    public override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }

    // MARK: - internal properties

    internal var playerLayer: AVPlayerLayer {
        get {
            return self.layer as! AVPlayerLayer
        }
    }

    internal var player: AVPlayer? {
        get {
            return self.playerLayer.player
        }
        set {
            self.playerLayer.player = newValue
            if let _ = self.playerLayer.player {
                self.playerLayer.isHidden = false
            } else {
                self.playerLayer.isHidden = true
            }
        }
    }

    // MARK: - public properties

    public var playerBackgroundColor: UIColor? {
        get {
            if let cgColor = self.playerLayer.backgroundColor {
                return UIColor(cgColor: cgColor)
            }
            return nil
        }
        set {
            self.playerLayer.backgroundColor = newValue?.cgColor
        }
    }

    public var playerFillMode: PlayerFillMode {
        get {
            return self.playerLayer.videoGravity
        }
        set {
            self.playerLayer.videoGravity = newValue
        }
    }

    public var isReadyForDisplay: Bool {
        get {
            return self.playerLayer.isReadyForDisplay
        }
    }

    // MARK: - object lifecycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    deinit {
        self.player?.pause()
        self.player = nil
    }

}
