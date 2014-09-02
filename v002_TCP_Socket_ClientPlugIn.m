//
//  v002_TCP_Socket_ReaderPlugIn.m
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002_TCP_Socket_ClientPlugIn.h"

#define	kQCPlugIn_Name				@"v002 TCP Socket Client"
#define	kQCPlugIn_Description		@"Opens a raw TCP Socket connection to a remote server, inputs and outputs data as a string."

#include <sys/socket.h>
#include <netinet/in.h>


@implementation v002_TCP_Socket_ClientPlugIn

@synthesize messageString;

@dynamic inputHost;
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

	if([key isEqualToString:@"inputHost"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Host", QCPortAttributeNameKey, @"localhost", QCPortAttributeDefaultValueKey, nil];

	if([key isEqualToString:@"inputPort"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Port", QCPortAttributeNameKey, [NSNumber numberWithInteger:31337], QCPortAttributeDefaultValueKey, [NSNumber numberWithInteger:1024], QCPortAttributeMinimumValueKey, [NSNumber numberWithInteger:65535], QCPortAttributeMaximumValueKey, nil];

	if([key isEqualToString:@"inputData"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Input (To Server)", QCPortAttributeNameKey, nil];

	if([key isEqualToString:@"outputData"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Output (From Server)", QCPortAttributeNameKey, nil];
	
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
		connectSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		//connectSocket = [[AsyncSocket alloc] initWithDelegate:self];
		//[connectSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];

		connectedSockets = [[NSMutableArray alloc] initWithCapacity:3];

		self.messageString = @"";
	}
	
	return self;
}

- (void) dealloc
{
	self.messageString = nil;
	[super dealloc];
}

@end

@implementation v002_TCP_Socket_ClientPlugIn (Execution)


- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	if([self didValueForInputKeyChange:@"inputPort"] || [self didValueForInputKeyChange:@"inputHost"])
	{
		// stop listening for incomming connections
		[connectSocket disconnect];

		if(![connectSocket connectToHost:self.inputHost onPort:self.inputPort error:nil])
			NSLog(@"could not connect to host, port");
	}
		
	if([self didValueForInputKeyChange:@"inputData"])
	{
		NSData* data = [[self.inputData stringByAppendingString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
		[connectSocket writeData:data withTimeout:-1 tag:0];
	}
	
	self.outputData = self.messageString;
	return YES;
}

#pragma mark - Async Socket handling


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{	
	NSLog(@"Client socket didConnectToHost %@ on port %u", host, port);

	[sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	NSLog(@"Client socket didWriteDataWithTag");
	
	[sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{			
	NSLog(@"Client socket didReadData");

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
			NSLog(@"Error converting received data into UTF-8 String");
			self.messageString = @"";
		}

	}
	else
		self.messageString = @"";

	[sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"Client socketDidDisconnect");
}




@end

