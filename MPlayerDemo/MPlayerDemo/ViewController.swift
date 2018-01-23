//
//  ViewController.swift
//  MPlayerDemo
//
//  Created by yizhilu on 2018/1/22.
//  Copyright © 2018年 Magic. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,MPlayerViewDelegate {
    
    /** *表格 */
    var tableViewM : UITableView?
    /** *播放器视图 */
    var playerView : MPlayerView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableViewM = UITableView.init(frame: CGRect.init(x: 0, y: Screen_width * 9/16, width: Screen_width, height: Screen_height - Screen_width * 9/16))
        self.view.addSubview(self.tableViewM!)
        self.tableViewM?.separatorStyle = .singleLine
        self.tableViewM?.delegate = self
        self.tableViewM?.dataSource = self
        
        
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)-> UITableViewCell {
        let cellID = "MCELL"
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: cellID)
        cell.selectionStyle = .none
        cell.textLabel?.text = "点击播放视频";
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let videoUrl = "http://v.96koo.net/common/LzIwNC9yZWxlYXNlLzIwMTgwMTE1L2Y1cDQ4d0NLa0ovZjVwNDh3Q0trSl85NjBfMTAwMA==_1402.m3u8"
        if self.playerView != nil {
            self.playerView?.removeFromSuperview()
            self.playerView?.exchangeWithURL(videoURLStr: videoUrl)
        }else{
            self.playerView  = MPlayerView().initWithFrame(frame: CGRect.init(x: 0, y: 0, width: Screen_width, height: Screen_width * 9/16), videoUrl: videoUrl, type: "VIDEO")
            self.playerView?.mPlayerDelegate = self
            self.view.addSubview(self.playerView!)
        }
        
    }
    
    ///MARK:播放器代理事件
    func closePlayer() {
        ///还可以做一些操作,比如清除单元格状态
        self.playerView = nil
    }
    func setBackgroundTime(_ currTime: Float, _ totTime: Float) {
        //        print("~~~~~当前时间!!!!!!总时间",currTime,totTime);
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
