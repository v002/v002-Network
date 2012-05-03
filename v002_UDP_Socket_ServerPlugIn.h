//
//  v002_TCP_Socket_ReaderPlugIn.h
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "GCDAsyncUdpSocket.h"

// Server takes in a string to send to all clients
// Server outputs a string (maybe a dictionary/array of messages?) from clients.

@interface v002_UDP_Socket_ServerPlugIn : QCPlugIn
{
	GCDAsyncUdpSocket* listenSocket;

	dispatch_queue_t socket_queue;

	NSString* messageString;
}
@property (readwrite, retain) GCDAsyncUdpSocket* listenSocket;
@property (readwrite, copy) NSString* messageString;

@property (assign) NSUInteger inputPort;
@property (assign) NSString* outputData;

@end

@interface v002_UDP_Socket_ServerPlugIn (Execution)

@end

