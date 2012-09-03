//
//  MosquittoMessage.m
//  Mosquitto
//
//  Created by Toomas Vahter on 30.08.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//
//  This content is released under the MIT License (http://www.opensource.org/licenses/mit-license.php).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "MosquittoMessage.h"
#import "MosquittoMessageInternal.h"
#include "mosquitto.h"

@implementation MosquittoMessage

- (id)initWithMessageID:(NSUInteger)aMessageID
{
    if ((self = [super init]))
    {
        _messageID = aMessageID;
    }
    
    return self;
}


- (id)initWithCMessage:(const struct mosquitto_message *)message
{
    if ((self = [self initWithMessageID:message->mid]))
    {
        _topic = [NSString stringWithCString:message->topic encoding:NSUTF8StringEncoding];
        _payload = [NSData dataWithBytes:message->payload length:message->payloadlen];
        _qualityOfServiceLevel = message->qos;
    }
    
    return self;
}


- (id)initWithMessageTopic:(NSString *)aTopic payload:(NSData *)aPayload qualityOfServiceLevel:(NSUInteger)aQoSLevel
{
    if ((self = [self initWithMessageID:NSUIntegerMax]))
    {
        _topic = aTopic;
        _payload = aPayload;
        _qualityOfServiceLevel = aQoSLevel;
    }
    
    return self;
}


#pragma mark -
#pragma mark Identifying and Comparing Objects

- (NSUInteger)hash
{
    return self.messageID;
}


- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[MosquittoMessage class]])
        return NO;
    
    return [object messageID] == self.messageID;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <#%lu topic = %@ payload = %@ qos = %lu>", self, self.messageID, self.topic, self.payload, self.qualityOfServiceLevel];
}

@end
