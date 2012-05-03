//
//  v002_TCP_Socket_ReaderPlugIn.h
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "GCDAsyncSocket.h"

@interface v002_TCP_Socket_ClientPlugIn : QCPlugIn
{
	GCDAsyncSocket* connectSocket;

	NSMutableArray *connectedSockets;

	NSString* messageString;	
}
@property (readwrite, copy) NSString* messageString;

@property (assign) NSString* inputHost;
@property (assign) NSUInteger inputPort;
@property (assign) NSString *inputData;

@property (assign) NSString* outputData;

@end

@interface v002_TCP_Socket_ClientPlugIn (Execution)

@end

