//
//  MQTTBrokerWill.h
//  Mosquitto
//
//  Created by Toomas Vahter on 26.08.12.
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

@interface MQTTBrokerWill : NSObject

/**
 Initializes MQTTBrokerWill instance which can be used for setting will to the broker. Topic and statement is validated when initializing MosquittoClient instance with MQTTBrokerWill.
 @param aTopic - Topic to publish the will.
 @param aStatement - Will information.
 @returns Initialized MQTTBrokerWill.
 */
- (id)initWithTopic:(NSString *)aTopic statement:(NSData *)aStatement qos:(NSUInteger)qos;

/**
 Topic of the will.
 */
@property (nonatomic, readonly) NSString *topic;

/**
 Information passed to the topic.
 */
@property (nonatomic, readonly) NSData *statement;

/**
 Quality of Service level for the will.
 */
@property (nonatomic, readonly) NSUInteger qualityOfServiceLevel;

@end
