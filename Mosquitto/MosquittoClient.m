//
//  MosquittoClient.m
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


#import "MosquittoClient.h"
#import "MQTTBrokerWill.h"
#import "MosquittoClientDelegate.h"
#import "MosquittoMessage.h"
#import "MosquittoMessageInternal.h"

@interface MosquittoClient()
@property (nonatomic, readonly) id delegate;
@property (nonatomic, readonly) NSCache *messageCache;

@property (assign, getter = isNetworkLoopActive) BOOL networkLoopActive;
@property (assign) BOOL tearDownNetworkLoop;
- (void)startNetworkEventLoop;
- (void)stopNetworkEventLoop;
@end

@implementation MosquittoClient

+ (void)initialize
{
	if (self == [MosquittoClient class])
	{
		mosquitto_lib_init();
	}
}


- (id)initWithIdentifier:(NSString *)anIdentifier brokerInfo:(NSDictionary *)aBrokerInfo delegate:(id)aDelegate
{
	if ((self = [super init]))
	{
        if ([anIdentifier length] == 0)
        {
            NSLog(@"%s invalid identifier", __func__);
            return nil;
        }
        
		mosquitto_client = mosquitto_new([anIdentifier cStringUsingEncoding:NSUTF8StringEncoding], (__bridge void *)(self));
		
		if (mosquitto_client)
		{
            // Validate broker info
            if (![aBrokerInfo objectForKey:kMQTTBrokerHostKey])
			{
                mosquitto_destroy(mosquitto_client);
                NSLog(@"%s host not specified", __func__);
                return nil;
            }
            else if (![aBrokerInfo objectForKey:kMQTTBrokerPortKey])
			{
                mosquitto_destroy(mosquitto_client);
                NSLog(@"%s port not specified", __func__);
                return nil;
            }
            
			_identifier = anIdentifier;
			_brokerInfo = aBrokerInfo;
			_delegate = aDelegate;
            
            _messageCache = [[NSCache alloc] init];
            [_messageCache setName:anIdentifier];
            [_messageCache setCountLimit:1024];
            
            // Default settings
            _keepAliveInterval = 30;
            _messageRetryInterval = 60;
            _cleanSession = YES;
			
			MQTTBrokerWill *will = [aBrokerInfo objectForKey:kMQTTBrokerWillKey];
            
			if (will)
			{
                // Get payload
				uint32_t payload_length = (uint32_t)[will.statement length];
				uint8_t payload[payload_length];
				[will.statement getBytes:&payload];
                
                // Set will
				int result = mosquitto_will_set(mosquitto_client, true, [will.topic cStringUsingEncoding:NSUTF8StringEncoding], payload_length, payload, (int)will.qualityOfServiceLevel, true);
                
                // Handle error and return nil
                if (result != MOSQ_ERR_SUCCESS)
                {
                    mosquitto_destroy(mosquitto_client);
                    NSLog(@"%s error setting will with error code %d", __func__, result);
                    return nil;
                }
			}
            
            // Set callbacks
            mosquitto_connect_callback_set(mosquitto_client, on_connect);
            mosquitto_disconnect_callback_set(mosquitto_client, on_disconnect);
            
            mosquitto_publish_callback_set(mosquitto_client, on_publish);
            
            mosquitto_message_callback_set(mosquitto_client, on_message);
            
            mosquitto_subscribe_callback_set(mosquitto_client, on_subscribe);
            mosquitto_unsubscribe_callback_set(mosquitto_client, on_unsubscribe);
		}
	}
	
	return self;
}


- (void)dealloc
{
	mosquitto_destroy(mosquitto_client);
}


#pragma mark -
#pragma mark Connection

- (BOOL)connect
{
    NSString *host = [self.brokerInfo objectForKey:kMQTTBrokerHostKey];
    int port = [[self.brokerInfo objectForKey:kMQTTBrokerPortKey] intValue];
    int result = mosquitto_connect(mosquitto_client, [host cStringUsingEncoding:NSUTF8StringEncoding], port, (int)self.keepAliveInterval, self.cleanSession);
    
    if (result != MOSQ_ERR_SUCCESS)
        NSLog(@"%s failed with libmosquitto error code %d", __func__, result);
    else
        [self startNetworkEventLoop];
    
    return result == MOSQ_ERR_SUCCESS;
}


- (BOOL)disconnect
{
    int result = mosquitto_disconnect(mosquitto_client);
    
    if (result != MOSQ_ERR_SUCCESS)
        NSLog(@"%s failed with libmosquitto error code %d", __func__, result);
    
    return result == MOSQ_ERR_SUCCESS;
}


#pragma mark -
#pragma mark Loop

- (void)startNetworkEventLoop
{
    if (self.isNetworkLoopActive)
        return;
    
    self.tearDownNetworkLoop = NO;
    self.networkLoopActive = YES;
    
    dispatch_queue_t queue = dispatch_queue_create("com.mosquitto-framework.client", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^
                   {
                       while (!mosquitto_loop(mosquitto_client, -1))
                       {
                           if (self.tearDownNetworkLoop)
                               break;
                       }
                       
                       // Reset variables as network loop stopped
                       self.tearDownNetworkLoop = NO;
                       self.networkLoopActive = NO;
                   });
}


- (void)stopNetworkEventLoop
{
    if (self.isNetworkLoopActive)
        self.tearDownNetworkLoop = YES;
}


#pragma mark -
#pragma mark Broker

- (BOOL)publishMessage:(MosquittoMessage *)outgoingMessage error:(NSError **)anError
{
    uint16_t messageID = 0;
    
    // Get payload
    uint32_t payload_length = (uint32_t)[outgoingMessage.payload length];
    uint8_t payload[payload_length];
    [outgoingMessage.payload getBytes:&payload];

    int result = mosquitto_publish(mosquitto_client, &messageID, [outgoingMessage.topic cStringUsingEncoding:NSUTF8StringEncoding], payload_length, payload, (int)outgoingMessage.qualityOfServiceLevel, true);
    
    // libmosquitto assigns IDs for all messages
    outgoingMessage.messageID = messageID;
    
    // In the callback I can return the same message
    [self.messageCache setObject:outgoingMessage forKey:[NSNumber numberWithUnsignedInteger:outgoingMessage.messageID]];
    
    if (anError)
        *anError = nil;
    
    if (result != MOSQ_ERR_SUCCESS)
        *anError = [self _errorWithMosquittoErrorCode:result];
    
    return result == MOSQ_ERR_SUCCESS;
}


- (BOOL)subscribeToTopic:(MosquittoMessage *)outgoingMessage error:(NSError **)anError
{
    uint16_t messageID = 0;
    int result = mosquitto_subscribe(mosquitto_client, &messageID, [outgoingMessage.topic cStringUsingEncoding:NSUTF8StringEncoding], (int)outgoingMessage.qualityOfServiceLevel);
    
    outgoingMessage.messageID = messageID;
    [self.messageCache setObject:outgoingMessage forKey:[NSNumber numberWithUnsignedInteger:outgoingMessage.messageID]];
    
    if (anError)
        *anError = nil;
    
    if (result != MOSQ_ERR_SUCCESS)
        *anError = [self _errorWithMosquittoErrorCode:result];
    
    return result == MOSQ_ERR_SUCCESS;
}


- (BOOL)unsubscribeFromTopic:(MosquittoMessage *)outgoingMessage error:(NSError **)anError
{
    uint16_t messageID = 0;
    int result = mosquitto_unsubscribe(mosquitto_client, &messageID, [outgoingMessage.topic cStringUsingEncoding:NSUTF8StringEncoding]);
    
    outgoingMessage.messageID = messageID;
    [self.messageCache setObject:outgoingMessage forKey:[NSNumber numberWithUnsignedInteger:outgoingMessage.messageID]];
    
    if (anError)
        *anError = nil;
    
    if (result != MOSQ_ERR_SUCCESS)
        *anError = [self _errorWithMosquittoErrorCode:result];
    
    return result == MOSQ_ERR_SUCCESS;
}


#pragma mark -
#pragma mark Authentication

- (void)setUsername:(NSString *)anUsername password:(NSString *)aPassword
{
	mosquitto_username_pw_set(mosquitto_client, [anUsername cStringUsingEncoding:NSUTF8StringEncoding], [aPassword cStringUsingEncoding:NSUTF8StringEncoding]);
}


#pragma mark -
#pragma mark Accessors

- (void)setMessageRetryInterval:(NSUInteger)messageRetryInterval
{
    _messageRetryInterval = messageRetryInterval;
    mosquitto_message_retry_set(mosquitto_client, (unsigned int)_messageRetryInterval);
}


- (void)setLoggingMask:(MosquittoLoggingMask)aLoggingMask
{
    _loggingMask = aLoggingMask;
    
    int logging_destination = (_loggingMask == MosquittoNoLogging) ? MOSQ_LOG_NONE : MOSQ_LOG_STDOUT;
    mosquitto_log_init(mosquitto_client, (int)_loggingMask, logging_destination);
}


#pragma mark -
#pragma mark Errors

- (NSError *)_errorWithMosquittoErrorCode:(NSUInteger)errorCode
{
    switch (errorCode)
    {
        case MosquittoOutOfMemoryError:
        case MosquittoProtocolError:
        case MosquittoInvalidInputParametersError:
        case MosquittoNoConnectionError:
        case MosquittoRefusedConnectionError:
        case MosquittoLostConnectionError:
        case MosquittoTooLargePayloadError:
            return [NSError errorWithDomain:@"MosquittoErrorDomain" code:errorCode userInfo:nil];
        default:
            NSLog(@"%s Unhandled error code %ld", __func__, errorCode);
            return [NSError errorWithDomain:@"MosquittoErrorDomain" code:MosquittoUnknownError userInfo:nil];
    }
}


#pragma mark -
#pragma mark Callbacks

static void on_connect(void *client, int response_code)
{
    MosquittoClient *mosquittoClient = (__bridge MosquittoClient *)client;
    
    if ([mosquittoClient.delegate respondsToSelector:@selector(mosquittoClient:didReceiveConnectionResponse:)])
    {
        [mosquittoClient.delegate mosquittoClient:mosquittoClient didReceiveConnectionResponse:response_code];
    }
}


static void on_disconnect(void *client)
{
    MosquittoClient *mosquittoClient = (__bridge MosquittoClient *)client;
    
    if ([mosquittoClient.delegate respondsToSelector:@selector(mosquittoClientDidDisconnect:)])
    {
        [mosquittoClient.delegate mosquittoClientDidDisconnect:mosquittoClient];
    }
    
    // Tear down event loop
    [mosquittoClient stopNetworkEventLoop];
}


static void on_publish(void *client, uint16_t message_id)
{
    MosquittoClient *mosquittoClient = (__bridge MosquittoClient *)client;
    
    if ([mosquittoClient.delegate respondsToSelector:@selector(mosquittoClient:didPublishMessage:)])
    {
        MosquittoMessage *message = [mosquittoClient.messageCache objectForKey:[NSNumber numberWithUnsignedInteger:message_id]];
        [mosquittoClient.messageCache removeObjectForKey:[NSNumber numberWithUnsignedInteger:message_id]];
        
        if (!message)
            message = [[MosquittoMessage alloc] initWithMessageID:message_id];
        
        [mosquittoClient.delegate mosquittoClient:mosquittoClient didPublishMessage:message];
    }
}


static void on_message(void *client, const struct mosquitto_message *message)
{
    MosquittoClient *mosquittoClient = (__bridge MosquittoClient *)client;
    
    if ([mosquittoClient.delegate respondsToSelector:@selector(mosquittoClient:didReceiveMessage:)])
    {
        MosquittoMessage *mosquittoMessage = [[MosquittoMessage alloc] initWithCMessage:message];
        [mosquittoClient.delegate mosquittoClient:mosquittoClient didReceiveMessage:mosquittoMessage];
    }
}


static void on_subscribe(void *client, uint16_t message_id, int qos_count, const uint8_t *granted_qos)
{
    MosquittoClient *mosquittoClient = (__bridge MosquittoClient *)client;
    
    if ([mosquittoClient.delegate respondsToSelector:@selector(mosquittoClient:didSubscribe:)])
    {
        MosquittoMessage *message = [mosquittoClient.messageCache objectForKey:[NSNumber numberWithUnsignedInteger:message_id]];
        [mosquittoClient.messageCache removeObjectForKey:[NSNumber numberWithUnsignedInteger:message_id]];
        
        if (!message)
        {
            // Caching failed, create a new message instance
            struct mosquitto_message mosq_message;
            mosq_message.mid = message_id;
            mosq_message.payload = (uint8_t *)granted_qos;
            mosq_message.payloadlen = qos_count;
            
            message = [[MosquittoMessage alloc] initWithCMessage:&mosq_message];
        }
        else
        {
            // Set payload to the message used for subscribing
            message.payload = [[NSData alloc] initWithBytes:granted_qos length:qos_count];
        }
        
        [mosquittoClient.delegate mosquittoClient:mosquittoClient didPublishMessage:message];
    }
}


static void on_unsubscribe(void *client, uint16_t message_id)
{
    MosquittoClient *mosquittoClient = (__bridge MosquittoClient *)client;
    
    if ([mosquittoClient.delegate respondsToSelector:@selector(mosquittoClient:didUnsubscribe:)])
    {
        MosquittoMessage *message = [mosquittoClient.messageCache objectForKey:[NSNumber numberWithUnsignedInteger:message_id]];
        [mosquittoClient.messageCache removeObjectForKey:[NSNumber numberWithUnsignedInteger:message_id]];
        
        if (!message)
            message = [[MosquittoMessage alloc] initWithMessageID:message_id];
        
        [mosquittoClient.delegate mosquittoClient:mosquittoClient didUnsubscribe:message];
    }
}

@end
