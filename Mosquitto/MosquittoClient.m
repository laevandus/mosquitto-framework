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

@interface MosquittoClient()
@property (nonatomic, readonly) id delegate;
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
		mosquitto_client = mosquitto_new([anIdentifier cStringUsingEncoding:NSUTF8StringEncoding], (__bridge void *)(self));
		
		if (mosquitto_client)
		{
			_identifier = anIdentifier;
			_brokerInfo = aBrokerInfo;
			_delegate = aDelegate;
            
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
#pragma mark Authentication

- (void)setUsername:(NSString *)username password:(NSString *)password
{
	mosquitto_username_pw_set(mosquitto_client, [username cStringUsingEncoding:NSUTF8StringEncoding], [password cStringUsingEncoding:NSUTF8StringEncoding]);
}


#pragma mark -
#pragma mark Accessors

- (void)setMessageRetryInterval:(NSUInteger)messageRetryInterval
{
    _messageRetryInterval = messageRetryInterval;
    mosquitto_message_retry_set(mosquitto_client, (unsigned int)_messageRetryInterval);
}


#pragma mark -
#pragma mark Callbacks

static void on_connect(void *client, int response_code)
{
    
}


static void on_disconnect(void *client)
{
    
}


static void on_publish(void *client, uint16_t message_id)
{
    
}


static void on_message(void *client, const struct mosquitto_message *message)
{
    // copy it
}


static void on_subscribe(void *client, uint16_t message_id, int qos_count, const uint8_t *granted_qos)
{
    
}


static void on_unsubscribe(void *client, uint16_t message_id)
{
    
}

@end

















