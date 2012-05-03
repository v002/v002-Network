//
//  v002_TCP_Socket_ReaderPlugIn.h
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "GCDAsyncSocket.h"

// Server takes in a string to send to all clients
// Server outputs a string (maybe a dictionary/array of messages?) from clients.

@interface v002_TCP_Socket_ServerPlugIn : QCPlugIn
{
	GCDAsyncSocket* listenSocket;
	
	NSMutableArray *connectedSockets;
		
	NSString* messageString;
}

@property (readwrite, retain) GCDAsyncSocket* listenSocket;
@property (readwrite, retain) NSMutableArray* connectedSockets;

@property (readwrite, copy) NSString* messageString;

@property (assign) NSUInteger inputPort;
@property (assign) NSString *inputData;

@property (assign) NSString* outputData;

@end

@interface v002_TCP_Socket_ServerPlugIn (Execution)

@end

