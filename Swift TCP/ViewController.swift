//
//  ViewController.swift
//  Swift TCP
//
//  Created by Edisonthk on 2015/05/03.
//  Copyright (c) 2015年 test. All rights reserved.
//

import CoreFoundation;
import UIKit

class ViewController: UIViewController, NSStreamDelegate {
    

    @IBOutlet weak var button: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        initTcpNetwork();
        self.button.setTitle("Test", forState: UIControlState.Normal);
    }

func printQueueLabel(function:String = __FUNCTION__){
    let label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    println("\(function) @ \(String.fromCString(label))");
}

    func initTcpNetwork() {
        printQueueLabel();
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(nil, "127.0.0.1", 55222, &readStream, &writeStream);

        var inputStream: NSInputStream = readStream!.takeRetainedValue();
        var outputStream: NSOutputStream = writeStream!.takeRetainedValue();

        inputStream.delegate = self;
        outputStream.delegate = self;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            self.printQueueLabel();
            let loop = NSRunLoop.currentRunLoop();
            inputStream.scheduleInRunLoop(loop, forMode: NSDefaultRunLoopMode);
            outputStream.scheduleInRunLoop(loop, forMode: NSDefaultRunLoopMode);
            inputStream.open()
            outputStream.open()
            loop.run();
        }

    }

    @IBAction func touchUpInside(sender: AnyObject) {
        printQueueLabel();
    }

    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        printQueueLabel();
        switch (eventCode){
        case NSStreamEvent.OpenCompleted:
            NSLog("Stream opened");
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
    
    func recv(recv: NSString) {
        printQueueLabel();
        dispatch_async(dispatch_get_main_queue()) {
            self.button.setTitle(recv, forState: UIControlState.Normal);
        }
    }


}

