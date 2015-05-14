//
//  TCPHandler.swift
//  Swift TCP
//
//  Created by Edisonthk on 2015/05/12.
//  Copyright (c) 2015年 test. All rights reserved.
//

import Foundation

protocol TCPHandlerDelegate: class {
    func TCPHandlerDidConnect(handler: TCPHandler)
    func TCPHandlerDidDisconnect(handler: TCPHandler, error: NSError?)
    func TCPHandlerDidReceiveMessage(handler: TCPHandler, text: String)
}

class TCPHandler:NSObject, NSStreamDelegate {
    
    var delegate: TCPHandlerDelegate?
    var host = "";
    var port = 0;
    
    private var bothStreamOpened = false;
    private var streamOpenedCount = 0;
    private var outputStream:NSOutputStream?
    private var inputStream:NSInputStream?
    private var outputQueue: NSOperationQueue = NSOperationQueue();
    
    func initTcpNetwork(host: String, port:Int) {
        
        self.host = host;
        self.port = port;
        
        outputQueue.maxConcurrentOperationCount = 1;
        
        NSStream.getStreamsToHostWithName(host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        
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
    
    func printQueueLabel(function:String = __FUNCTION__){
        let label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
        println("\(function) @ \(String.fromCString(label)!)");
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        switch (eventCode){
        case NSStreamEvent.OpenCompleted:
            streamOpenedCount += 1;
            if(streamOpenedCount >= 2) {
                bothStreamOpened = true;
                self.delegate?.TCPHandlerDidConnect(self);
            }
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
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate?.TCPHandlerDidReceiveMessage(self, text: output as String);
                    }
                }
            }
            break
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            close();
            break
        case NSStreamEvent.EndEncountered:
            NSLog("end countered");
            close();
            break
        default:
            NSLog("unknown.")
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
    
    func close() {
        self.outputQueue.cancelAllOperations();
        self.inputStream?.close();
        self.outputStream?.close();
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