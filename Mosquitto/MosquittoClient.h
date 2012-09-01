//
//  MosquittoClient.h
//  Mosquitto
//
//  Created by Toomas Vahter on 25.08.12.
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


#import <Foundation/Foundation.h>
#include "mosquitto.h"

#define kMQTTBrokerHostKey @"host"
#define kMQTTBrokerPortKey @"port"
#define kMQTTBrokerWillKey @"will"

@interface MosquittoClient : NSObject
{
	struct mosquitto *mosquitto_client;
}

- (id)initWithIdentifier:(NSString *)anIdentifier brokerInfo:(NSDictionary *)aBrokerInfo delegate:(id)aDelegate;

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSDictionary *brokerInfo;

- (void)setUsername:(NSString *)username password:(NSString *)password;

@property (nonatomic, assign) NSUInteger keepAliveInterval; // defaults to 30 seconds, takes effect when calling connect
@property (nonatomic, assign) BOOL cleanSession; // defaults to YES, takes effect when calling connect
@property (nonatomic, assign) NSUInteger messageRetryInterval; // defaults to 60 seconds, takes effect immediately

- (BOOL)connect;
- (BOOL)reconnect;
- (BOOL)disconnect;

@end
