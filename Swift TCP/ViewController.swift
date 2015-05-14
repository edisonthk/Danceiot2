//
//  ViewController.swift
//  Swift TCP
//
//  Created by Edisonthk on 2015/05/03.
//  Copyright (c) 2015年 test. All rights reserved.
//

import CoreFoundation;
import AVFoundation;   // ライブラリーのインポート
import UIKit

class ViewController: UIViewController, TCPHandlerDelegate {
    
    let host = "127.0.0.1";
    let port = 8080;

    
//    var audioPlayers = [AVAudioPlayer(), AVAudioPlayer(), AVAudioPlayer()];
    var audioPlayers = [TempAudio(), TempAudio(), TempAudio() ];
    var last_direction:Int = Int();
    var tcp_handler: TCPHandler = TCPHandler();
    var app_is_active = true;
    
    @IBOutlet weak var tempImage: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    var imgA:UIImage!;
    var imgB:UIImage!;
    var imgC:UIImage!;
    var imgD:UIImage!;
    var imgCount: Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tcp_handler.initTcpNetwork(self.host, port: self.port);
        tcp_handler.delegate = self;
        
        self.button.setTitle("Test", forState: UIControlState.Normal);
        
        app_is_active = true;
        
        imgA = UIImage(named: "a")!
        imgB = UIImage(named: "b")!
        imgC = UIImage(named: "c")!
        imgD = UIImage(named: "d")!
        
        tempImage.image = imgA;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            while(self.app_is_active){
                self.tcp_handler.writeString("0111");
                usleep(1000 * 100);
            }
        }
    }
    
    override func viewDidDisappear(_animated: Bool) {
        println("deinit");
        self.app_is_active = false;
        tcp_handler.close();
    }
    
    func TCPHandlerDidConnect(handler: TCPHandler) {
        println("conected");
    }
    
    func TCPHandlerDidDisconnect(handler: TCPHandler, error: NSError?) {
        NSLog("disconnect");
    }
    
    func TCPHandlerDidReceiveMessage(handler: TCPHandler, text: String) {
        println(text);
        
            if var direction = text.toInt() {
                
                // to prevent duplicate
                if(direction == self.last_direction) {
                    println();
                    return;
                }
                
                self.last_direction = direction;
                if direction == 41 {
                    println("left");
//                    self.playAudioInParallel("9");
                    tempImage.image = imgB;
                }else if( direction == 21 ) {
                    println("right");
                    self.playAudioInParallel("3");
                    tempImage.image = imgC;
                }else if( direction == 12 ) {
                    println("up");
                    self.playAudioInParallel("14");
                    tempImage.image = imgD;
                }else if( direction == 14 ) {
                    println("down");
                    self.playAudioInParallel("17");
                    tempImage.image = imgA;
                }
            }
        
    }
    

    @IBAction func touchUpInside(sender: AnyObject) {
        println("touch up");
    }
    
    
    func playAudioInParallel( filename: String) {
        
        for var i = 0; i < self.audioPlayers.count; i++ {
            print(i);
            print(" ");
            println(self.audioPlayers[i].playing);
            if(!self.audioPlayers[i].playing) {
                self.audioPlayers[i].play(filename);
                break;
            }
        }

    }
}


class TempAudio:NSObject, AVAudioPlayerDelegate {
    
    var audio = AVAudioPlayer();
    var initial = false;
    var playing = false;
    
    
    override init() {
        super.init();
    }
    
    func play(filename: String) {
        self.playing = true;
        var url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(filename, ofType: "mp3")! );
        self.audio = AVAudioPlayer(contentsOfURL: url, error: nil);
        self.audio.delegate = self;
        self.audio.prepareToPlay();
        self.audio.play();
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        println("helll");
        self.playing = false;
    }
}
