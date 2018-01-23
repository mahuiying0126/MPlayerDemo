//
//  MPlayerView.swift
//  BangDemo
//
//  Created by yizhilu on 2017/6/28.
//  Copyright © 2017年 Magic. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import SnapKit

/**
 * 定义两个枚举:
 *  1.PanDirection手势:包含水平移动方向和垂直移动方向
 *  2.PlayerStatus播放状态:播放,暂停,缓存等
 **/

/// 滑动手势
///
/// - PanDirectionHorizontalMoved: 横向移动
/// - PanDirectionVerticalMoved: 纵向移动
enum PanDirection{
    case HorizontalMoved
    
    case VerticalMoved
}

/// 播放器状态
///
/// - PlayerBuffering: 正在缓冲
/// - PlayerReadyToPlay: 准备播放
/// - PlayerPlaying: 正在播放状态
/// - PlayerPaused: 播放暂停状态
/// - PlayerComplete: 播放完成
/// - PlayerFaild: 播放失败
enum PlayerStatus {
    case PlayerBuffering
    case PlayerReadyToPlay
    case PlayerPlaying
    case PlayerPaused
    case PlayerComplete
    case PlayerFaild
}

/// 播放器两个代理事件
@objc protocol MPlayerViewDelegate {
    
    func closePlayer()
    func setBackgroundTime(_ currTime:Float,_ totTime:Float)
}
final class MPlayerView: UIView,UIGestureRecognizerDelegate,MChangeRateValueDelegate {
    
    /** *播放器*/
    var player : AVPlayer?
    private var playerItem : AVPlayerItem?
    private var playerLayer : AVPlayerLayer?
    weak var mPlayerDelegate : MPlayerViewDelegate?
    /** *用来保存快进的总时长 */
    private var sumTime : CMTime?
    /** *手势,枚举 */
    private var panDirection : PanDirection?
    /** *是否在调节音量 */
    private var isVolume : Bool = false
    /** *声音进度条 */
    private var volumeViewSlider : UISlider?
    /** 播放器 UI 布局*/
    private var viewModel : MPlayerViewModel?
    /** *视频非解析的码 */
    private var videoParseCode : String?
    /** 视频解密的链接即.m3u8 */
    private var videoPlayUrl : String?
    /** *视频类型 */
    private var videoType : String?
    /** *是否为本地视频 */
    private var isLOCAL : Bool = false
    /** *显示控制层定时器 */
    private var timer : Timer?
    /** *是否正在拖动进度条 */
    private var progressDragging : Bool = false
    /** *控制层是否显示 */
    private var controlViewIsShowing : Bool = false
    /** *是否锁屏屏幕 */
    private var isLocked : Bool = false
    /** *是否全屏 */
    private var isFullScreen : Bool = false
    /** *时间观察 */
    private var timeObserve : Any?
    /** 当前播放是音频还是视频*/
    private var isVideo : Bool = true
    /** *是否播放完毕 */
    private var playEnd : Bool = false
    /** *当前倍速 */
    final var rateValue : Float = 1.0
    /** *当前时长 */
    final var currentTime : NSInteger = 0
    /** *总时长 */
    final var totalTime : NSInteger = 0
    /** *播放器状态 */
    final var status : PlayerStatus = .PlayerReadyToPlay
    /// 创建播放器单例
    static let shared = MPlayerView()
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// 初始化播放器视图
    ///
    /// - Parameters:
    ///   - frame: 播放器尺寸
    ///   - url: videoUrl(hhtp://非加密链接)
    ///   - type: 类型:音频 || 视频
    ///   - parseString: 需要解析的码
    func initWithFrame(frame:CGRect,videoUrl:String,type:String) -> MPlayerView {
        self.backgroundColor = UIColor.black
        //开启屏幕旋转
        let appde = UIApplication.shared.delegate as! AppDelegate
        appde.allowRotation = true
        self.frame = frame
        self.videoType = type
        self.videoPlayUrl = videoUrl
        rateValue = 1.0
        isFullScreen = false
        isLocked = false
        self.status = .PlayerBuffering
        ///屏幕旋转监听
        self.listeningRotating()
        ///页面布局,菊花,倒计时
        self.playWithUrl(url: videoUrl)
        ///页面布局
        self.makeSubViewsConstraints()
        ///增加点击手势
        self.addGesture()
        ///增加滑动手势
        self.addPanGesture()
        ///获取系统音量
        self.configureVolume()
        ///亮度,视图暂时没有做
        
        ///配置远程控制显示的信息
        self.configRemoteCommandCenter()
        return self
    }
    
    @objc func playerPause() -> Void {
        self.player?.pause()
    }
    
    @objc func playerPlay() -> Void {
        self.player?.rate = self.rateValue
    }
    
    /*
     * 初始化playerItem,play
     *
     */
    private func playWithUrl(url:String){
        ///开启菊花
        self.startAnimation()
        self.playerItem = getPlayItemWithURLString(url: url)
        self.player = AVPlayer.init(playerItem: self.playerItem)
        self.playerLayer = AVPlayerLayer.init(player: self.player)
        self.playerLayer?.frame = self.layer.bounds
        ///播放画面呈现模式,裁剪,充满等等
        self.playerLayer?.videoGravity = AVLayerVideoGravity.resize
        self.layer.addSublayer(playerLayer!)
        self.player?.play()
        
    }
    
    /*
     * 初始化playerItem
     */
    private func getPlayItemWithURLString(url:String) -> AVPlayerItem{
        ///初始化播放 item
//        let Item = AVPlayerItem.init(url: NSURL.init(string: url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)! as URL)
        let Item = AVPlayerItem.init(url: NSURL.init(string: url)! as URL)
        if playerItem == Item {
            return playerItem!
        }
        if (playerItem != nil) {

            playerItem?.removeObserver(self, forKeyPath: "status")
            playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
    
        Item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        Item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        
        
        return Item
    }
    
    /*
     * 切换视频调用方法
     */
    func exchangeWithURL(videoURLStr : String)  {
        self.playEnd = false
        self.playerItem = self.getPlayItemWithURLString(url: videoURLStr)
        self.player?.replaceCurrentItem(with: self.playerItem)
        self.player?.seek(to: CMTimeMake(Int64(0), 1))
    }
    
    //MARK: - 音频,视频,倍速代理
    func changeRateValue(_ rateValue: Float) {
        self.rateValue = rateValue
        self.player?.rate = self.rateValue
    }
    
    func conversionMediaType(_ isVideo: Bool) {
        if isVideo {
            ///切换到视频
            self.viewModel?.musicBackGround?.isHidden = true
            self.isVideo = true
            recoverAudioBackMode()
        }else{
            ///切换到音频
            self.isVideo = false
            self.viewModel?.musicBackGround?.isHidden = false
            configAudioBackMode()
        }
    }
    
    private func conversionWithURL(_ videoUrl : String){
        self.playerItem = self.getPlayItemWithURLString(url: videoUrl)
        self.player?.replaceCurrentItem(with: self.playerItem)
        self.player?.seek(to: CMTimeMake(Int64(currentTime), 1))
    }
    
    //MARK: - 播放器手势添加与创建
    /*
     * 增加单点手势
     */
    private func addGesture(){
        let oneRecognizer = UITapGestureRecognizer()
        oneRecognizer.addTarget(self, action: #selector(tapOneClick(gesture:)))
        self.addGestureRecognizer(oneRecognizer)
    }
    
    /*
     * 添加平移手势，用来控制音量、亮度、快进快退
     */
    private func addPanGesture(){
        let panGest = UIPanGestureRecognizer.init(target: self, action: #selector(panDirection(pan:)))
        self.addGestureRecognizer(panGest)
        
    }
    
    /*
     * 手势点击事件
     */
    @objc private func tapOneClick(gesture:UIGestureRecognizer){
        if !playEnd {
            if controlViewIsShowing {
                hideControlView()
                cancleDelay()
                controlViewIsShowing = false
            }else{
                self.showControlView()
                controlViewIsShowing = true
            }
        }else{
            self.viewModel?.closeBtn?.isHidden = false
        }
    }
    
    /*
     * Pan手势事件
     */
    @objc private func panDirection(pan:UIPanGestureRecognizer){
        if (!(self.viewModel?.repeatBtn?.isHidden)!) {
            return
        }
        /// 获取手指点在屏幕上的位置
        let locationPoint = pan.location(in: self)
        /// 根据上次和本次移动的位置，算出一个速率的point
        let veloctyPoint = pan.velocity(in: self)
        switch pan.state {
        case .began:
            /// 使用绝对值来判断移动的方向
            let x = fabs(veloctyPoint.x)
            let y = fabs(veloctyPoint.y)
            if x > y {
                self.viewModel?.horizontalLabel?.isHidden = false
                self.panDirection = PanDirection.HorizontalMoved
                /// 给sumTime初值
                let time = self.player?.currentTime()
                self.sumTime = CMTimeMake((time?.value)!, (time?.timescale)!)
                ///暂停视频播放
                self.player?.pause()
            }else if x < y {
                self.panDirection = .VerticalMoved
                /// 开始滑动的时候,状态改为正在控制音量
                if locationPoint.x > self.bounds.size.width/2 {
                    self.isVolume = true
                }else{
                    self.isVolume = false
                }
            }
            break
        case .changed:
            switch self.panDirection! {
            case .HorizontalMoved:
                /// 移动中一直显示快进label
                self.viewModel?.horizontalLabel?.isHidden = false
                /// 水平移动的方法只要x方向的值
                self.horizontalMoved(value: veloctyPoint.x)
                break
            case .VerticalMoved:
                ///垂直移动方法只要y方向的值
                self.verticalMoved(value: veloctyPoint.y)
                break
            }
            break
        case .ended:
            switch self.panDirection! {
            case .HorizontalMoved:
                
                self.player?.rate = self.rateValue
                self.viewModel?.horizontalLabel?.isHidden = true
                ///快进、快退时候把开始播放按钮改为播放状态
                self.seekTime(dragedTime: self.sumTime!)
                self.sumTime = CMTime.init(seconds: 0.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                break
            case.VerticalMoved:
                self.isVolume = false
                self.viewModel?.horizontalLabel?.isHidden = true
                break;
                
            }
            break
        default:
            break
        }
        
        
    }
    
    /*
     * 手势:水平移动
     */
    private func horizontalMoved(value:CGFloat){
        ///开启菊花
        self.startAnimation()
        var style = String()
        if value < 0 {
            style = "<<"
        }
        if value > 0 {
            style = ">>"
        }
        if value == 0 {
            return
        }
        /// 将平移距离转成CMTime格式
        let addend = CMTime.init(seconds: Double.init(value/200), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        self.sumTime = CMTimeAdd(self.sumTime!, addend)
        /// 总时间
        let totalTime = self.playerItem?.duration
        
        let totalMovieDuration = CMTimeMake((totalTime?.value)!, (totalTime?.timescale)!)
        
        if self.sumTime! > totalMovieDuration {
            self.sumTime = totalMovieDuration
        }
        ///最小时间0
        let small = CMTime.init(seconds: 0.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        if self.sumTime! < small {
            self.sumTime = small
        }
        
        let nowTime = self.timeStringWithTime(times: NSInteger(CMTimeGetSeconds(self.sumTime!)))
        let durationTime = self.timeStringWithTime(times: NSInteger(CMTimeGetSeconds(totalMovieDuration)))
        
        self.viewModel?.horizontalLabel?.text = String.init(format: "%@ %@ / %@",style, nowTime, durationTime)
        let sliderTime = CMTimeGetSeconds(self.sumTime!)/CMTimeGetSeconds(totalMovieDuration)
        self.viewModel?.slider?.value = Float.init(sliderTime)
        self.viewModel?.currentTimeLB?.text = nowTime
    }
    
    /*
     * 手势:上下移动
     */
    private func verticalMoved(value:CGFloat){
        
        self.isVolume ? (self.volumeViewSlider?.value -= Float(value / 10000)) : (UIScreen.main.brightness -= value / 10000)
    }
    
    /*
     * 时间转化
     */
    private func timeStringWithTime(times:NSInteger) -> String{
        let min = times / 60
        let sec = times % 60
        let timeString = String.init(format: "%02zd:%02zd", min,sec)
        return timeString
    }
    
    /*
     * 从X秒开始播放视频
     */
    private func seekTime(dragedTime:CMTime){
        
        if self.player?.currentItem?.status == .readyToPlay {
            self.player?.seek(to: dragedTime, completionHandler: { (finished) in
                self.player?.rate = self.rateValue
            })
        }
    }
    
    /*
     * 获取系统音量
     */
    private func configureVolume(){
        let volumeView = MPVolumeView()
        volumeViewSlider = nil
        for view in volumeView.subviews {
            if NSStringFromClass(view.classForCoder) == "MPVolumeSlider" {
                volumeViewSlider = view as? UISlider
                break
            }
        }
        ///监听播放完毕通知
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        ///监听耳机插入和拔掉通知
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListenerCallback(notification:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
        ///中断处理
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruption(sender :)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        ///程序进入后台通知
//        NotificationCenter.default.addObserver(self, selector: #selector(playerEnterBackGround(sender:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    /*
     * 耳机监听拔插事件
     */
    @objc private func audioRouteChangeListenerCallback(notification:NSNotification){
        DispatchQueue.main.async {
            let interuptionDict = notification.userInfo! as NSDictionary
            let routeChangeReason = interuptionDict.value(forKey: AVAudioSessionRouteChangeReasonKey) as! AVAudioSessionRouteChangeReason
            switch routeChangeReason {
            case .newDeviceAvailable:
                // 耳机插入
                print("耳机插入")
                break
            case .oldDeviceUnavailable:
                // 耳机拔掉
                print("耳机拔出")
                self.player?.rate = self.rateValue
                break
            default:
                break
            }
        }
    }
    @objc func audioSessionInterruption(sender : Notification) {
        DispatchQueue.main.async {
            
            let interruptionType = sender.userInfo?[AVAudioSessionInterruptionTypeKey] as! UInt
            if interruptionType == AVAudioSessionInterruptionType.began.rawValue {
                print("开始中断")
                //中断播放
                
                self.player?.pause()
                
            } else if interruptionType == AVAudioSessionInterruptionType.ended.rawValue {
                print("结束中断")
                
                self.player?.play()
                }
            }
        }
   
    
    //MARK: - 延迟延迟与显示控制层
    /*
     * 延时5秒隐藏控制层
     */
    private func DelayOperation()  {
        self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControlView), userInfo: nil, repeats: false)
    }
    
    /*
     * 暂停倒计时
     */
    @objc private func cancleDelay(){
        if (self.timer != nil) {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    /*
     * 隐藏控制层
     */
    @objc private func hideControlView(){
        UIView.animate(withDuration: 0.35) {
            self.controlViewIsShowing = false
            self.viewModel?.bottomImageView?.alpha = 0.0
            if self.playEnd {
                self.viewModel?.topImageView?.alpha = 1.0
            }else{
                self.viewModel?.topImageView?.alpha = 0.0
            }
            self.viewModel?.lockBtn?.isHidden = true
            self.viewModel?.rateView?.isHidden = true
            self.viewModel?.centerPlayOrPauseBtn?.isHidden = true
            self.viewModel?.closeBtn?.isHidden = true
        }
        
        cancleDelay()
        
    }
    
    /*
     *  显示控制层
     */
    @objc private func showControlView(){
        UIView.animate(withDuration:0.35) { [weak self] in
            self?.controlViewIsShowing = true
            self?.viewModel?.bottomImageView?.alpha = 1.0
            self?.viewModel?.topImageView?.alpha = 1.0
            self?.viewModel?.lockBtn?.isHidden = false
            self?.viewModel?.rateView?.isHidden =  false
            self?.viewModel?.centerPlayOrPauseBtn?.isHidden = false
            self?.viewModel?.closeBtn?.isHidden = false
            
        }
        
        self.DelayOperation()
        
    }
    
    //MARK:公共方法
    /*
     * 开启菊花
     */
    private func startAnimation(){
        self.viewModel?.activeView?.startAnimating()
        self.viewModel?.activeLB?.isHidden = false
        self.viewModel?.centerPlayOrPauseBtn?.isHidden = true
    }
    
    /*
     * 关闭菊花
     */
    private func stopAnimation(){
        self.viewModel?.activeView?.stopAnimating()
        self.viewModel?.centerPlayOrPauseBtn?.isHidden = controlViewIsShowing ? false : true
        self.viewModel?.activeLB?.isHidden = true
        
    }
    
    /*
     * 播放器关闭
     */
    private func closPlaer(){
        let appde = UIApplication.shared.delegate as! AppDelegate
        appde.allowRotation = false
        NotificationCenter.default.removeObserver(self)
        if (self.timeObserve != nil) {
            self.player?.removeTimeObserver(self.timeObserve as Any)
            self.timeObserve = nil
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.player?.currentItem?.cancelPendingSeeks()
        self.player?.currentItem?.asset.cancelLoading()
        self.player?.pause()
        self.removeFromSuperview()
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil
        self.playerItem = nil
    }
    
    //MARK:播放器属性添加与监听
    /*
     * item播放完毕通知
     */
    @objc private func moviePlayDidEnd(note:Notification){
        hideControlView()
        self.viewModel?.repeatBtn?.isHidden = false
        self.playEnd = true
        self.status = .PlayerComplete
    }
    
    /*
     * 添加属性观察
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            let status = playerItem!.status
            switch status {
            case .readyToPlay:
                
                self.status = .PlayerReadyToPlay
                stopAnimation()
                ///时间刷新
                addTimeObserve()
                ///将倍速重新给播放器,避免做一些操作把倍速给搞没了
                self.player?.rate = self.rateValue
                ///倍速
                enableAudioTracks(isable: true, playerItem: self.playerItem!)
//                self.playerItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.timeDomain
                ///增加面板信息
                configMediaItemArtwork()
                break
            case .failed:
                self.status = .PlayerFaild
                break
            default:
                break
            }
        }else if keyPath == "loadedTimeRanges"{
            ///计算视频缓存速度,可自行实现具体效果
//            let loadedTimeRanges = self.player?.currentItem?.loadedTimeRanges
//            let timeRange = loadedTimeRanges?.first?.timeRangeValue
//            
//            let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
//            let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
//            let result = startSeconds + durationSeconds
//            print(result)
            self.viewModel?.repeatBtn?.isHidden = true
            
        }
    }
    
    /*
     * 实时刷新数据
     */
    private func addTimeObserve(){
        self.timeObserve = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: nil, using: { [weak self](time) in
            if #available(iOS 10.0, *) {
                if self?.player?.timeControlStatus == .playing {
                    self?.status = PlayerStatus.PlayerPlaying
                    self?.viewModel?.playOrPauseBtn?.isSelected = false
                }else if self?.player?.timeControlStatus == .paused {
                    self?.status = PlayerStatus.PlayerPaused
                    self?.viewModel?.playOrPauseBtn?.isSelected = true
                }else if self?.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    self?.status = PlayerStatus.PlayerBuffering
                    self?.viewModel?.playOrPauseBtn?.isSelected = true
                }
            }else{
                //ios 10.0 以下
                if self?.player?.currentItem?.status == .readyToPlay {
                    self?.status = PlayerStatus.PlayerPlaying
                    self?.viewModel?.playOrPauseBtn?.isSelected = false
                }else{
                    self?.status = PlayerStatus.PlayerFaild
                    self?.viewModel?.playOrPauseBtn?.isSelected = true
                }
            }
            if (self?.playerItem != nil) {
                let currentItem = self?.playerItem
                let currentTime = CMTimeGetSeconds((currentItem?.currentTime())!)
//                print("itemTime!!!!!!!!",currentTime);
//                print("time~~~~~~",CMTimeGetSeconds(time))
                
                let totalTime = CMTimeGetSeconds(CMTimeMake((currentItem?.duration.value)!, (currentItem?.duration.timescale)!))
//                print(totalTime)
                ///代理实现
                self?.mPlayerDelegate?
                    .setBackgroundTime(Float(currentTime), Float(totalTime))
                ///更新进度条,时间
                if (currentItem?.seekableTimeRanges.count)! > 0 && (currentItem?.duration.timescale)! != 0 {
                    self?.totalTime = NSInteger(totalTime)
                    self?.currentTime = NSInteger(currentTime)
                    let currentTimeString = self?.timeStringWithTime(times: NSInteger(currentTime))
                    let totalTimeString = self?.timeStringWithTime(times: NSInteger(totalTime))
                    self?.viewModel?.slider?.value = Float(currentTime / totalTime)
                    self?.viewModel?.currentTimeLB?.text = currentTimeString
                    self?.viewModel?.totalTimeLB?.text = totalTimeString
                }
            }
            
        })
    }
    
    /*
     * 倍速调用
     */
    private func enableAudioTracks(isable:Bool,playerItem:AVPlayerItem){
        for track in playerItem.tracks {
            if track.assetTrack.mediaType == AVMediaType.audio {
                track.isEnabled = isable
            }
        }
    }
    

    //MARK:按钮点击事件
    /*
     * 中间大按钮播放暂停
     */
    @objc private func playOrPauseButtonClick(sender:UIButton){
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            self.player?.pause()
        }else{
            ///将倍速重设一下,相当于播放
            self.player?.rate = self.rateValue
        }
    }

    /*
     * 重播按钮
     */
    @objc private func repeatBtnClick(button:UIButton){
    
        exchangeWithURL(videoURLStr: self.videoPlayUrl!)
    }
    
    /*
     *  全屏按钮点击事件
     */
    @objc private func fullScreenClick(sender:UIButton){
        
        if isLocked {
            return
        }
        sender.isSelected = !sender.isSelected
        let orientation = UIDevice.current.orientation
        switch orientation {
            
        case .portraitUpsideDown:
            ///如果是UpsideDown就直接回到竖屏
            interfaceOrientation(orientation: .portrait)
        case .portrait:
            ///如果是竖屏就直接右旋转
            interfaceOrientation(orientation: .landscapeRight)
            break
        case .landscapeLeft:
            ///如果是小屏一律右旋转，如果是大屏的LandscapeLeft，就竖屏
            if !isFullScreen {
                interfaceOrientation(orientation: .landscapeRight)
            }else{
                interfaceOrientation(orientation: .portrait)
            }
            break
        case .landscapeRight:
            ///如果是小屏一律右旋转，如果是大屏的LandscapeLeft，就竖屏
            if !isFullScreen {
                interfaceOrientation(orientation: .landscapeRight)
            }else{
                interfaceOrientation(orientation: .portrait)
            }
            break
            
        default:
            if !self.isFullScreen {
                self.isFullScreen = true
                interfaceOrientation(orientation: .landscapeRight)
            }else{
                self.isFullScreen = false
                interfaceOrientation(orientation: .portrait)
            }
            break
        }
    }
    
    /*
     * 锁屏按钮
     */
    @objc private func lockBtnClick(sender:UIButton){
        sender.isSelected = !sender.isSelected
        let appde = UIApplication.shared.delegate as! AppDelegate
        if isLocked {
            appde.allowRotation = true
            isLocked = false
        }else{
            appde.allowRotation = false
            isLocked = true
        }
    }
    
    /*
     * 关闭播放器按钮
     */
    @objc private func closePlayer(sender:UIButton){
        if !isLocked {
            if isFullScreen {
                fullScreenClick(sender: UIButton())
            }else{
                UIApplication.shared.isStatusBarHidden = false
                ///关闭播放器代理
                self.mPlayerDelegate?.closePlayer()
                closPlaer()
            }
        }else{
            print("屏幕被锁了")
        }
    }
    
    /*
     * 进度条滑动事件
     */
    @objc private func progressSliderTouchBegan(slider:UISlider){
        self.startAnimation()
        self.player?.pause()
    }
    
    @objc private func progressSliderValueChanged(slider:UISlider){
        if (totalTime > 0)  {
            let chageTime = slider.value * Float(totalTime)
            self.viewModel?.currentTimeLB?.text = String.init(format: "%@", self.timeStringWithTime(times: NSInteger(chageTime)))
        }
    }
    
    @objc private func progressSliderTouchEnded(slider:UISlider){
        if (totalTime > 0) {
            self.player?.seek(to: CMTimeMake(Int64(slider.value * Float(totalTime)), 1))
            self.player?.rate = self.rateValue
        }
    }
    
    //MARK:屏幕相关设置以及屏幕布局
    /**
     *  监听设备旋转通知
     */
    private func listeningRotating()  {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange), name:NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    /**
     *  强制屏幕转屏
     *  orientation 屏幕方向
     */
    private func interfaceOrientation(orientation:UIInterfaceOrientation){
        if isLocked {
            return
        }
        ///swift移除了NSInvocation 暂时找不到强制旋转方法,只能桥接
        DeviceTool.interfaceOrientation(orientation)
    }
    
    /**
     *  屏幕方向发生变化会调用这里
     */
    @objc private func onDeviceOrientationChange()  {
        
        if isLocked {
            return
        }
        
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portraitUpsideDown:
            let frame = UIScreen.main.bounds
            self.center = CGPoint.init(x: frame.origin.x + ceil(frame.size.width/2), y: frame.origin.y + ceil(frame.size.height/2))
            self.frame = frame
           
            self.isFullScreen = true
            
            break
            
        case .portrait:
            let frame = UIScreen.main.bounds
            self.center = CGPoint.init(x: frame.origin.x + ceil(frame.size.width/2), y: frame.origin.y + ceil((frame.size.width*9/16)/2))
            self.frame = CGRect.init(x: frame.origin.x, y: frame.origin.x, width: frame.size.width, height: Screen_width * 9/16)
           
            self.isFullScreen = false
            break
            
        case .landscapeLeft:
            
            let frame = UIScreen.main.bounds
            self.center = CGPoint.init(x: frame.origin.x + ceil(frame.size.width/2), y: frame.origin.y + ceil(frame.size.height/2))
            self.frame = frame
           
            self.isFullScreen = true
            break
            
        case .landscapeRight:
            let frame = UIScreen.main.bounds
            self.center = CGPoint.init(x: frame.origin.x + ceil(frame.size.width/2), y: frame.origin.y + ceil(frame.size.height/2))
            self.frame = frame
            self.isFullScreen = true
            break
            
        default:
            break
        }
        self.playerLayer?.frame = self.frame
    }
    
    private func configMediaItemArtwork() -> Void {
        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            var info : [String : Any] = Dictionary()
            
            ///设置后台播放时显示的东西，例如歌曲名字，图片等
            let image = UIImage(named: "testImage")
            ///标题
            info[MPMediaItemPropertyTitle] = "我有一头小毛驴"
            ///作者
            info[MPMediaItemPropertyArtist] = "Magic"
            //相簿标题
            info[MPMediaItemPropertyAlbumTitle] = "心血来潮去赶集"
            ///封面
            if #available(iOS 10.0, *) {
                let artWork = MPMediaItemArtwork(boundsSize: image!.size, requestHandler: { (size) -> UIImage in return image! })
                info[MPMediaItemPropertyArtwork] = artWork
            } else {
                // Fallback on earlier versions
                info[MPMediaItemPropertyArtwork] = image
            }
            
            if self.playerItem?.duration != nil {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: CMTimeGetSeconds(self.player!.currentTime()))
                let duration = CMTimeGetSeconds((self.playerItem?.duration)!)
                info[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            ///设置后台播放
            self.configAudioBackMode()
        }
    }
    ///配置远程控制显示的信息
    private func configRemoteCommandCenter() -> Void {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        //播放事件
        let playCommand = remoteCommandCenter.playCommand
        playCommand.isEnabled = true
        playCommand.addTarget(self, action: #selector(playerPlay))
        //暂停事件
        let pauseCommand = remoteCommandCenter.pauseCommand
        pauseCommand.isEnabled = true
        pauseCommand.addTarget(self, action: #selector(playerPause))
        //下一曲
        let nextTrackCommand = remoteCommandCenter.nextTrackCommand
        nextTrackCommand.isEnabled = true
        nextTrackCommand.addTarget(self, action: #selector(playerPause))
        
        //喜欢
        let likeCommand = remoteCommandCenter.likeCommand
        likeCommand.isEnabled = true
        likeCommand.isActive = true//显示钩
        likeCommand.localizedTitle = "不喜欢"
        likeCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            let event =  commandEvent as! MPFeedbackCommandEvent
            if event.isNegative == false {
                likeCommand.isActive = true
            } else {
                likeCommand.isActive = false
            }
            
            likeCommand.localizedTitle = (likeCommand.isActive == true) ? "不喜欢" : "喜欢"
            return MPRemoteCommandHandlerStatus.success
        }
        
        let dislikeCommand = remoteCommandCenter.dislikeCommand
        dislikeCommand.isEnabled = true
        dislikeCommand.localizedTitle = "上一首"
        dislikeCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            print("上一首")
            return MPRemoteCommandHandlerStatus.success
        }
        
        //拖动播放位置
        if #available(iOS 9.1, *) {
           let changePlaybackPositionCommand = remoteCommandCenter.changePlaybackPositionCommand
            changePlaybackPositionCommand.isEnabled = true
            changePlaybackPositionCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
                //如何精确拖动的位置？
                let event = commandEvent as! MPChangePlaybackPositionCommandEvent
                
                if self.player != nil {
                    ///需要使用带回调的SeekTime 回调重新设置进度 否则播放进度条会停止
                    self.player?.seek(to: CMTimeMakeWithSeconds(event.positionTime, 1), completionHandler: { (finish) in
                        ///更新面板信息
                        var dic = MPNowPlayingInfoCenter.default().nowPlayingInfo
                        dic?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: CMTimeGetSeconds(self.player!.currentTime()))
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = dic
                    })
                    return MPRemoteCommandHandlerStatus.success
                } else {
                    return MPRemoteCommandHandlerStatus.commandFailed
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    ///设置后台播放模式
    func configAudioBackMode() {
        //配置后台播放
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category == AVAudioSessionCategoryPlayback {
        } else {
            try? audioSession.setActive(true, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
            try? audioSession.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions())
        }
    }
    ///恢复默认的播放模式
    func recoverAudioBackMode() {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category == AVAudioSessionCategorySoloAmbient {
            
        } else {
            try? audioSession.setActive(true, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
            try? audioSession.setCategory(AVAudioSessionCategorySoloAmbient, with: AVAudioSessionCategoryOptions())
        }
    }
    
    /**
     *  页面布局
     */
    private func makeSubViewsConstraints(){
        self.viewModel = MPlayerViewModel()
        self.viewModel?.createPlayerView(self)
        /** 关闭按钮事件*/
        self.viewModel?.closeBtn?.addTarget(self, action: #selector(closePlayer(sender:)), for: .touchUpInside)
        /** 锁屏按钮事件*/
        self.viewModel?.lockBtn?.addTarget(self, action: #selector(lockBtnClick(sender:)), for: .touchUpInside)
        /** 重播按钮事件*/
        self.viewModel?.repeatBtn?.addTarget(self, action: #selector(repeatBtnClick(button:)), for: .touchUpInside)
        /** 设置切换倍速代理*/
        self.viewModel?.rateView?.rateValueDelegate = self
        /** 中间播放按钮事件*/
        self.viewModel?.centerPlayOrPauseBtn?.addTarget(self, action: #selector(playOrPauseButtonClick(sender:)), for: .touchUpInside)
        /** 全屏事件*/
        self.viewModel?.fullScreenBtn?.addTarget(self, action: #selector(fullScreenClick(sender:)), for: .touchUpInside)
        /** 滑动进度条*/
        self.viewModel?.slider?.addTarget(self, action: #selector(progressSliderTouchBegan(slider:)), for: .touchDown)
        self.viewModel?.slider?.addTarget(self, action: #selector(progressSliderValueChanged(slider:)), for: .valueChanged)
        self.viewModel?.slider?.addTarget(self, action: #selector(progressSliderTouchEnded(slider:)), for: .touchCancel)
        self.controlViewIsShowing = true
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
