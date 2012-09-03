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

#define kMQTTBrokerHostKey @"host" // NSString
#define kMQTTBrokerPortKey @"port" // NSNumber
#define kMQTTBrokerWillKey @"will" // MQTTBrokerWill

enum
{
    MosquittoOutOfMemoryError = MOSQ_ERR_NOMEM,
    MosquittoProtocolError = MOSQ_ERR_PROTOCOL,
    MosquittoInvalidInputParametersError = MOSQ_ERR_INVAL,
    MosquittoNoConnectionError = MOSQ_ERR_NO_CONN,
    MosquittoRefusedConnectionError = MOSQ_ERR_CONN_REFUSED,
    MosquittoLostConnectionError = MOSQ_ERR_CONN_LOST,
    MosquittoTooLargePayloadError = MOSQ_ERR_PAYLOAD_SIZE,
    MosquittoUnknownError = NSUIntegerMax
};
typedef NSUInteger MosquittoErrorCode;

enum
{
    MosquittoNoLogging = 0x00,
    MosquittoNoticeLogging = MOSQ_LOG_NOTICE,
    MosquittoWarningLogging = MOSQ_LOG_WARNING,
    MosquittoErrorLogging = MOSQ_LOG_ERR,
    MosquittoDebugLogging = MOSQ_LOG_DEBUG,
    MosquittoAllLogging = MOSQ_LOG_ALL
};
typedef NSUInteger MosquittoLoggingMask;

@class MosquittoMessage;

@interface MosquittoClient : NSObject
{
	struct mosquitto *mosquitto_client;
}

/**
 Designated initialized for creating new MosquittoClient instance with broker info.
 @param anIdentifier - String used as client identifier. Must not be zero length.
 @param aBrokerInfo - Dictionary containing required host and port information and optional MQTTBrokerWill instance.
 @param aDelegate - Object to send methods defined in MosquittoClientDelegate.
 @returns MosquittoClient instance with identifier and broker configuration. Nil when invalid identifier or broker configuration.
 */
- (id)initWithIdentifier:(NSString *)anIdentifier brokerInfo:(NSDictionary *)aBrokerInfo delegate:(id)aDelegate;


/**
 MosquittoClient identifier.
 */
@property (nonatomic, readonly) NSString *identifier;


/**
 MosquittoClient broker configuration.
 */
@property (nonatomic, readonly) NSDictionary *brokerInfo;


/**
 Sets username and password used for connecting broker. Broker have to support MQTT version 3.1.
 @param anUsername - Username for authentication.
 @param aPassword - Password used together with username. If username is nil, password is ignored and only username is sent.
 */
- (void)setUsername:(NSString *)anUsername password:(NSString *)aPassword;


/**
 Number of seconds when broker sends PING message to the client when no other messages are exhanged. Default value is 30 seconds. Takes effect when calling -connect.
 */
@property (nonatomic, assign) NSUInteger keepAliveInterval;


/**
 When YES, broker cleans all messages and subscriptions on disconnect. Default value is YES. Takes effect when calling -connect.
 */
@property (nonatomic, assign) BOOL cleanSession;


/**
 Number of seconds until client tries to resend messages. Applies to publish messages with quality of service > 0. Default value is 60 seconds. Takes effect immediately.
 */
@property (nonatomic, assign) NSUInteger messageRetryInterval;


/**
 Attempts to connect to the broker.
 @returns YES if successful, otherwise NO. Use delegate method for getting error reason.
 */
- (BOOL)connect;


/**
 Attempts to disconnect from the broker.
 @returns YES if successful, otherwise NO.
 */
- (BOOL)disconnect;


/**
 Publishes message on a topic.
 @param outgoingMessage - MosquittoMessage containing topic, payload and quality of service.
 @param anError - An error object containing domain and error code.
 @returns YES if publish message is valid and client is connected to the broker, otherwise NO.
 */
- (BOOL)publishMessage:(MosquittoMessage *)outgoingMessage error:(NSError **)anError;


/**
 Subscribes to a topic.
 @param outgoingMessage - MosquittoMessage with topic which defines subscription pattern and with requested quality of service.
 @param anError - An error object containing domain and error code.
 @returns YES if subscription message is valid and client is connected to the broker, otherwise NO.
 */
- (BOOL)subscribeToTopic:(MosquittoMessage *)outgoingMessage error:(NSError **)anError;


/**
 Unsubscribes from a topic.
 @param outgoingMessage - MosquittoMessage with topic which defines unsubscription pattern.
 @param anError - An error object containing domain and error code.
 @returns YES if unsubscription message is valid and client is connected to the broker, otherwise NO.
 */
- (BOOL)unsubscribeFromTopic:(MosquittoMessage *)outgoingMessage error:(NSError **)anError;


/**
 Sets client logging options. Log messages are sent to STDOUT. 
 */
@property (nonatomic, assign) MosquittoLoggingMask loggingMask;

@end
