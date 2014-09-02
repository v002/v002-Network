//
//  v002_TCP_Socket_ReaderPlugIn.m
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002_TCP_Socket_ServerPlugIn.h"

#define	kQCPlugIn_Name				@"v002 TCP Socket Server"
#define	kQCPlugIn_Description		@"Opens a raw TCP Socket on a specified port, and outputs data as a string."

#include <sys/socket.h>
#include <netinet/in.h>


@implementation v002_TCP_Socket_ServerPlugIn

@synthesize listenSocket;
@synthesize messageString;
@synthesize connectedSockets;

@dynamic inputPort;
@dynamic inputData;
@dynamic outputData;

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey,
            [kQCPlugIn_Description stringByAppendingString:kv002DescriptionAddOnText], QCPlugInAttributeDescriptionKey,
            kQCPlugIn_Category, @"categories", nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	if([key isEqualToString:@"inputPort"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Port", QCPortAttributeNameKey, [NSNumber numberWithInteger:31337], QCPortAttributeDefaultValueKey, [NSNumber numberWithInteger:1024], QCPortAttributeMinimumValueKey, [NSNumber numberWithInteger:65535], QCPortAttributeMaximumValueKey, nil];

	if([key isEqualToString:@"inputData"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Input (to all Clients)", QCPortAttributeNameKey, nil];

	if([key isEqualToString:@"outputData"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Output (from any Client)", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeIdle;
}

- (id) init
{
	if(self = [super init])
	{
		// make a new socket.
		self.listenSocket = [[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()] autorelease];
		//listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
		//[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];

		// defaults
		self.messageString = @"";
		connectedSockets = [[NSMutableArray alloc] initWithCapacity:3];
	}
	
	return self;
}

- (void) dealloc
{
	self.listenSocket = nil;
	self.messageString = nil;
	self.connectedSockets = nil;

	[super dealloc];
}

@end

@implementation v002_TCP_Socket_ServerPlugIn (Execution)


- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	if([self didValueForInputKeyChange:@"inputPort"])
	{
		// stop listening for incomming connections
		[listenSocket disconnect];
		
		// disconnect clients
		// Stop any client connections
		int i;
		for(i = 0; i < [connectedSockets count]; i++)
		{
			// Call disconnect on the socket,
			// which will invoke the onSocketDidDisconnect: method,
			// which will remove the socket from the list.
			[[connectedSockets objectAtIndex:i] disconnect];
		}
		
		if(![listenSocket acceptOnPort:self.inputPort error:nil])
		{
			[context logMessage:@"Unable to bind on port: %u", self.inputPort];
		}
	}
		
	if([self didValueForInputKeyChange:@"inputData"])
	{
		NSData* data = [[self.inputData stringByAppendingString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
 
		for(GCDAsyncSocket *sock in connectedSockets)
		{
			[sock writeData:data withTimeout:-1 tag:0];
		}
	}
	
	self.outputData = self.messageString;

	return YES;
}

#pragma mark - Async Socket handling

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	NSLog(@"Server didAcceptNewSocket");
	[connectedSockets addObject:newSocket];

//	[newSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];

	NSString *welcomeMsg = @"v002 TCP Socket Server Connection Accepted\r\n";
	NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[newSocket writeData:welcomeData withTimeout:-1 tag:0];	

	[newSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{	
	NSLog(@"Server socket didConnectToHost %@ on port %u", host, port);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	NSLog(@"Server socket did write data");
	[sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{		
	NSLog(@"Server socket did read data");

	if([data length] > 1)	// make sure its not just an empty line
	{	
		NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 1)];
		NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
		if(msg)
		{
			self.messageString = msg;
		}
		else
		{
			self.messageString = @"";
			NSLog(@"Error converting received data into UTF-8 String");
		}
	}
	else
 		self.messageString = @"";

	[sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
	NSLog(@"Server socketDidDisconnect");
	
	[connectedSockets removeObject:sock];
}

@end

