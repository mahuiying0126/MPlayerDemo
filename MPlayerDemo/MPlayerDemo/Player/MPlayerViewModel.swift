//
//  MPlayerViewModel.swift
//  MAVPlayerDmeo
//
//  Created by yizhilu on 2018/1/17.
//Copyright © 2018年 Magic. All rights reserved.
//

import UIKit
import SnapKit
class MPlayerViewModel: NSObject {
    /** *音频背景 */
    var musicBackGround : UIImageView?
    /** *顶部背景 */
     var topImageView : UIImageView?
    /** *关闭按钮 */
     var closeBtn : UIButton?

    /** *音频视频切换，倍速三个按钮 */
    var rateView : RateView?
    /** *中间暂停按钮 */
    var centerPlayOrPauseBtn : UIButton?
    /** *锁定屏幕 */
     var lockBtn : UIButton?
    /** *重播 */
     var repeatBtn : UIButton?
    /** *底部遮罩 */
     var bottomImageView : UIImageView?
    /** *底部播放暂停播放按钮 */
     var playOrPauseBtn : UIButton?
    /** *全屏播放按钮 */
     var fullScreenBtn : UIButton?
    /** *当前时间 */
     var currentTimeLB : UILabel?
    /** *总时间 */
     var totalTimeLB : UILabel?
    /** *时间滑动条 */
     var slider : UISlider?
    /** *菊花 */
     var activeView : UIActivityIndicatorView?
    /** *提示文字,快进快退 */
     var activeLB : UILabel?
    /** *快进快退显示label */
     var horizontalLabel : UILabel?
    
    func createPlayerView(_ view : UIView)  {
        ///音频背景图片
        self.musicBackGround = {
            let musicBackGround = UIImageView()
            musicBackGround.image = MIMAGE("音频模式")
            musicBackGround.isHidden = true
            view.addSubview(musicBackGround)
            musicBackGround.snp.makeConstraints({ (make) in
                make.left.right.width.height.equalTo(view)
            })
            return musicBackGround
        }()
        let stateHeight = UIApplication.shared.statusBarFrame.size.height;
        ///顶部操作条
        self.topImageView = {
            let temptopImageView = UIImageView()
            temptopImageView.image = MIMAGE("Player_top_shadow")
            temptopImageView.isUserInteractionEnabled = true
            view.addSubview(temptopImageView)
            temptopImageView.snp.makeConstraints({ (make) in
                make.left.right.equalTo(view)
                if stateHeight > 20 {
                    ///iphonex
                    make.top.equalTo(view)
                }else{
                   make.top.equalTo(view).offset(23)
                }
                make.height.equalTo(40)
            })
            return temptopImageView
        }()
        
        /// 关闭播放器按钮
        self.closeBtn = {
            let tempCloseBtn = UIButton.init(type: .custom)
            tempCloseBtn.setImage(MIMAGE("Player_close"), for: .normal)
            topImageView?.addSubview(tempCloseBtn)
            tempCloseBtn.snp.makeConstraints({ (make) in
                make.left.equalTo(topImageView!).offset(5)
                make.top.equalTo(topImageView!)
                make.size.equalTo(CGSize.init(width: 40, height: 40))
            })
            return tempCloseBtn
        }()
        
        /// 锁屏按钮
        
        self.lockBtn = {
            
            let lockBtn = UIButton.init(type: .custom)
            lockBtn.setImage(MIMAGE("Player_unlock-nor"), for: .normal)
            lockBtn.setImage(MIMAGE("Player_lock-nor"), for: .selected)
            view.addSubview(lockBtn)
            lockBtn.snp.makeConstraints({ (make) in
                make.left.equalTo(view.snp.left).offset(5);
                make.centerY.equalTo(view)
                make.size.equalTo(CGSize.init(width: 40, height: 40));
            })
            return lockBtn
        }()
        
        ///重播按钮
        self.repeatBtn = {
            let tempBtn = UIButton.init(type: .custom)
            tempBtn.setImage(MIMAGE("Player_repeat_video"), for: .normal)
            tempBtn.isHidden = true
            view.addSubview(tempBtn)
            tempBtn.snp.makeConstraints({ (make) in
                make.center.equalTo(view)
            })
            return tempBtn
        }()
        
        
        ///右侧操作图
        self.rateView = {
            let tempRateView = RateView.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 140))
            tempRateView.image = MIMAGE("背景")
            view.addSubview(tempRateView)
            tempRateView.snp.makeConstraints({ (make) in
                make.centerY.equalTo(view)
                make.right.equalTo(view).offset(-5)
                make.width.equalTo(40)
                make.height.equalTo(130)
            })
            
            return tempRateView
            
        }()
        
        /// 底部操作条
        self.bottomImageView = {
            let tempBottom = UIImageView()
            tempBottom.image = MIMAGE("Player_bottom_shadow")
            tempBottom.isUserInteractionEnabled = true
            view.addSubview(tempBottom)
            tempBottom.snp.makeConstraints({ (make) in
                make.left.bottom.right.equalTo(view)
                make.height.equalTo(40)
            })
            return tempBottom
        }()
        
        /// 中间播放暂停按钮
        self.centerPlayOrPauseBtn = {
            let tempPlayBtn = UIButton()
            tempPlayBtn.setImage(MIMAGE("Player_pause_btn_small"), for: .normal)
            tempPlayBtn.setImage(MIMAGE("Player_play_btn_small"), for: .selected)
            view.addSubview(tempPlayBtn)
            tempPlayBtn.snp.makeConstraints({ (make) in
                make.center.equalTo(view)
                make.size.equalTo(CGSize.init(width: 80, height: 80))
            })
            
            return tempPlayBtn
            
        }()
        
        ///全屏退出全屏按钮
        self.fullScreenBtn = {
            let fullBtn = UIButton.init(type: .custom)
            fullBtn.setImage(MIMAGE("Player_fullscreen"), for: .normal)
            fullBtn.setImage(MIMAGE("Player_shrinkscreen"), for: .selected)
            bottomImageView!.addSubview(fullBtn)
            fullBtn.snp.makeConstraints({ (make) in
                make.right.equalTo(bottomImageView!.snp.right).offset(-2);
                make.top.equalTo(bottomImageView!);
                make.size.equalTo(CGSize.init(width: 40, height: 40));
            })
            return fullBtn
        }()
        
        /// 总时间
        self.totalTimeLB = {
            let tem = UILabel()
            tem.font = FONT(12)
            tem.textColor = Whit
            tem.text = "00:00"
            bottomImageView?.addSubview(tem)
            tem.snp.makeConstraints({ (make) in
                make.right.equalTo(fullScreenBtn!.snp.left)
                    .offset(-3)
                make.top.equalTo(fullScreenBtn!.snp.top)
                make.height.equalTo(40)
            })
            return tem
        }()
        /// 当前时间
        self.currentTimeLB = {
            let tempLabel = UILabel()
            tempLabel.font = FONT(12)
            tempLabel.textColor = Whit
            tempLabel.text = "00:00"
            bottomImageView?.addSubview(tempLabel)
            tempLabel.snp.makeConstraints({ (make) in
                make.left.equalTo(bottomImageView!.snp.left).offset(3)
                make.top.equalTo(fullScreenBtn!.snp.top)
                make.height.equalTo(40)
            })
            return tempLabel
        }()
        
        /// 滑动进度条
        self.slider = {
            let tempSlider = UISlider()
            tempSlider.setThumbImage(MIMAGE("Player_slider"), for: .normal)
            tempSlider.maximumValue = 1.0

            bottomImageView?.addSubview(tempSlider)
            tempSlider.snp.makeConstraints({ (make) in
                make.left.equalTo(currentTimeLB!.snp.right).offset(3)
                make.top.height.equalTo(currentTimeLB!)
                make.right.equalTo(totalTimeLB!.snp.left).offset(-8)
            })
            return tempSlider
        }()
        
        ///菊花
        self.activeView = {
            let activew = UIActivityIndicatorView()
            activew.activityIndicatorViewStyle = .white
            view.addSubview(activew)
            activew.snp.makeConstraints({ (make) in
                make.center.equalTo(view)
            })
            return activew
        }()
        ///本地倍速显示
        self.activeLB = {
            let temp = UILabel()
            temp.text = "正在加载"
            temp.font = FONT(13)
            temp.textColor = Whit
            temp.isHidden = true
            view.addSubview(temp)
            temp.snp.makeConstraints({ (make) in
                make.top.equalTo(activeView!.snp.bottom)
                make.height.equalTo(20)
                make.centerX.equalTo(activeView!)
            })
            return temp
        }()
        
        self.horizontalLabel = {
            let tempLabel = UILabel()
            tempLabel.font = FONT(13)
            tempLabel.textColor = Whit
            tempLabel.isHidden = true
            tempLabel.textAlignment = .center
            view.addSubview(tempLabel)
            tempLabel.snp.makeConstraints({ (make) in
                make.height.equalTo(33)
                make.centerX.equalTo(view)
                make.bottom.equalTo(view).offset(-15)
            })
            return tempLabel
            
        }()
    }
}
