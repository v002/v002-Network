//
//  v002_TCP_Socket_ReaderPlugIn.m
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002_UDP_Socket_ClientPlugIn.h"

#define	kQCPlugIn_Name				@"v002 UDP Socket Client"
#define	kQCPlugIn_Description		@"Connectionless UDP client, sends string messages to remote UDP server/listener."

#include <sys/socket.h>
#include <netinet/in.h>

@implementation v002_UDP_Socket_ClientPlugIn

@synthesize connectSocket;

@dynamic inputHost;
@dynamic inputPort;
@dynamic inputData;
@dynamic inputControlCharacter;

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

	if([key isEqualToString:@"inputControlCharacter"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Control Character", QCPortAttributeNameKey,
				[NSNumber numberWithInteger:3], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithInteger:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithInteger:3], QCPortAttributeMaximumValueKey,
				[NSArray arrayWithObjects:@"None", @"Carriage Return", @"Line Feed", @"Carriage Return Line Feed", nil], QCPortAttributeMenuItemsKey,
				nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeIdle;
}

- (id) init
{
	if(self = [super init])
	{
		socket_queue = dispatch_queue_create(NULL, NULL);
		
		self.connectSocket = [[[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socket_queue] autorelease];
		
		[self.connectSocket enableBroadcast:YES error:nil];
	}
	
	return self;
}

- (void) finalize
{
	self.connectSocket = nil;
	
	dispatch_release(socket_queue);
	
	[super finalize];
}

- (void) dealloc
{
	self.connectSocket = nil;

	dispatch_release(socket_queue);
	[super dealloc];
}

@end

@implementation v002_UDP_Socket_ClientPlugIn (Execution)

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{		
	if([self didValueForInputKeyChange:@"inputData"])
	{
		NSData* data = nil;
		
		switch (self.inputControlCharacter) 
		{
			case 0:
				data = [self.inputData dataUsingEncoding:NSUTF8StringEncoding];
				break;
			case 1:
				data = [[self.inputData stringByAppendingString:@"\r"] dataUsingEncoding:NSUTF8StringEncoding];
				break;
			case 2:
				data = [[self.inputData stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
				break;
			case 3:
				data = [[self.inputData stringByAppendingString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
				break;
			default:
				break;
		}
		
		[self.connectSocket sendData:data toHost:self.inputHost port:self.inputPort withTimeout:-1 tag:0];
	}
		
	return YES;
}

@end

