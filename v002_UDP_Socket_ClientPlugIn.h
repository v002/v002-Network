//
//  v002_TCP_Socket_ReaderPlugIn.h
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "GCDAsyncUdpSocket.h"

@interface v002_UDP_Socket_ClientPlugIn : QCPlugIn
{
	dispatch_queue_t socket_queue;
	GCDAsyncUdpSocket* connectSocket;	
}

@property (readwrite, retain) GCDAsyncUdpSocket* connectSocket;

@property (assign) NSString* inputHost;
@property (assign) NSUInteger inputPort;
@property (assign) NSString *inputData;
@property (assign) NSUInteger inputControlCharacter;

@end

@interface v002_UDP_Socket_ClientPlugIn (Execution)

@end

