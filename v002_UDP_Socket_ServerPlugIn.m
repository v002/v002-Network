//
//  v002_TCP_Socket_ReaderPlugIn.m
//  v002 TCP Socket Reader
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002_UDP_Socket_ServerPlugIn.h"

#define	kQCPlugIn_Name				@"v002 UDP Socket Server"
#define	kQCPlugIn_Description		@"Opens a UDP Socket on a specified port, and outputs data as a string."

#include <sys/socket.h>
#include <netinet/in.h>


@implementation v002_UDP_Socket_ServerPlugIn

@synthesize listenSocket;
@synthesize messageString;

@dynamic inputPort;
@dynamic outputData;

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey,
            [kQCPlugIn_Description stringByAppendingString:kv002DescriptionAddOnText], QCPlugInAttributeDescriptionKey,
            kQCPlugIn_Category, QCPlugInAttributeCategoriesKey, nil];
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
		socket_queue = dispatch_queue_create(NULL, NULL);

		// make a new socket.		
		self.listenSocket = [[[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socket_queue] autorelease];

		// defaults
		self.messageString = @"";
	}
	
	return self;
}

- (void) finalize
{
	[self.listenSocket close];
	self.listenSocket = nil;
	
	dispatch_release(socket_queue);
	
	self.messageString = nil;
	[super finalize];
}

- (void) dealloc
{
	[self.listenSocket close];
	self.listenSocket = nil;
	
	dispatch_release(socket_queue);
	
	self.messageString = nil;
	[super dealloc];
}

@end

@implementation v002_UDP_Socket_ServerPlugIn (Execution)


- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	if([self didValueForInputKeyChange:@"inputPort"])
	{
		// stop listening for incomming connections
		[self.listenSocket close];
				
		if(![self.listenSocket bindToPort:self.inputPort error:nil])
		{
			[context logMessage:@"UDP Server Unable to bind on port: %u", self.inputPort];
		}
		if(![self.listenSocket beginReceiving:nil])
		{
			[context logMessage:@"UDP Server Unable to begin receiving on port: %u", self.inputPort];
		}
	}
			
	self.outputData = self.messageString;

	return YES;
}

#pragma mark - Async Socket handling

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext;
{	
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
}



@end

