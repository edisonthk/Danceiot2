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
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            while(true){
                self.writeString("hello\n");
                sleep(1);
            }
        }
        
    }

    func printQueueLabel(function:String = __FUNCTION__){
        let label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
        println("\(function) @ \(String.fromCString(label)!)");
    }
    
    
    var outputStream:NSOutputStream?
    var inputStream:NSInputStream?
    var outputQueue: NSOperationQueue{ get{
        let ret = NSOperationQueue()
        ret.maxConcurrentOperationCount = 1
        return ret
        }}
    
    func initTcpNetwork() {

        NSStream.getStreamsToHostWithName("127.0.0.1", port: 8081, inputStream: &inputStream, outputStream: &outputStream)

        inputStream?.delegate = self;
        outputStream?.delegate = self;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            self.printQueueLabel();
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
            NSLog("Stream opened%@", NSStringFromClass(aStream.dynamicType));
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
    
    func recv(recv: NSString) {
        dispatch_async(dispatch_get_main_queue()) {
            println(recv);
            self.button.setTitle(recv as String, forState: UIControlState.Normal);
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

