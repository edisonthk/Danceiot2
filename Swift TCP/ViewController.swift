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

class ViewController: UIViewController, NSStreamDelegate {
    

    @IBOutlet weak var button: UIButton!
    
//    var audioPlayers = [AVAudioPlayer(), AVAudioPlayer(), AVAudioPlayer()];
    var audioPlayers = [TempAudio(), TempAudio(), TempAudio() ];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initTcpNetwork();
        self.button.setTitle("Test", forState: UIControlState.Normal);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            while(true){
                self.writeString("0");
                usleep(1000 * 100);
            }
        }
        

        
    }

    func printQueueLabel(function:String = __FUNCTION__){
        let label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
        println("\(function) @ \(String.fromCString(label)!)");
    }
    
    
    var outputStream:NSOutputStream?
    var inputStream:NSInputStream?
    var outputQueue: NSOperationQueue = NSOperationQueue();
    
    func initTcpNetwork() {
        
        outputQueue.maxConcurrentOperationCount = 1;

        NSStream.getStreamsToHostWithName("192.168.0.2", port: 8080, inputStream: &inputStream, outputStream: &outputStream)

        inputStream?.delegate = self;
        outputStream?.delegate = self;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            let loop = NSRunLoop.currentRunLoop();
            self.inputStream?.scheduleInRunLoop(loop, forMode: NSDefaultRunLoopMode);
            self.outputStream?.scheduleInRunLoop(loop, forMode: NSDefaultRunLoopMode);
            self.inputStream?.open()
            self.outputStream?.open()
            loop.run();
        }
    }
    
    func writeData() {
        self.printQueueLabel();
    }

    @IBAction func touchUpInside(sender: AnyObject) {
        println("touch up");
    }

    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {

        switch (eventCode){
        case NSStreamEvent.OpenCompleted:
            println("Stream opened");
            break
        case NSStreamEvent.HasSpaceAvailable:
            break
        case NSStreamEvent.HasBytesAvailable:
            var inputstream = aStream as? NSInputStream;

            var buffer = [UInt8](count: 4096, repeatedValue: 0);
            while ((inputstream?.hasBytesAvailable) != nil) {
                var len = inputstream?.read(&buffer, maxLength: 4096);
                if (len > 0) {
                    var output: NSString = NSString(bytes:&buffer, length:len!, encoding:NSASCIIStringEncoding)!;
                    recv(output);
                }
            }
            break
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            break
        case NSStreamEvent.EndEncountered:
            NSLog("EndEncountered")
            break
        default:
            NSLog("unknown.")
        }
    }
    
    var last_direction:Int = Int();
    func recv(recv: NSString) {
        dispatch_async(dispatch_get_main_queue()) {
            if var direction = (recv as String).toInt() {
                
                // to prevent duplicate
                if(direction == self.last_direction) {
                    println();
                    return;
                }
                
                self.last_direction = direction;
                if direction == 41 {
                    println("left");
                    self.playAudioInParallel("9");
                }else if( direction == 21 ) {
                    println("right");
                    self.playAudioInParallel("3");
                }else if( direction == 12 ) {
                    println("up");
                    self.playAudioInParallel("14");
                }else if( direction == 14 ) {
                    println("down");
                    self.playAudioInParallel("17");
                }
            }
        }
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
    
    
    func writeString(str: String) {
        writeData(str.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    ///write binary data to the TCPSocket. This sends it as a binary frame.
    func writeData(data: NSData) {
        while true {
            if((outputStream?.hasSpaceAvailable) != nil) {
                break;
            }
        }
        outputStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length);
    }
    
    ///used to write things to the stream in a
    private func enqueueOutput(data: NSData) {
        outputQueue.addOperationWithBlock {
            if let stream = self.outputStream{
                if(stream.hasSpaceAvailable){
                    stream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
                }
            }
        }
    }

}

