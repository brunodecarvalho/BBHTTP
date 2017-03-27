//
// Copyright 2013 BiasedBit
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//
//  Created by Bruno de Carvalho - @biasedbit / http://biasedbit.com
//  Copyright (c) 2013 BiasedBit. All rights reserved.
//

#import "BBHTTPRequest+PrivateInterface.h"

#import "BBHTTPUtils.h"



#pragma mark -

@implementation BBHTTPRequest (PrivateInterface)


#pragma mark Events

- (BOOL)executionStarted
{
    if ([self hasFinished]) return NO;

    _startTimestamp = BBHTTPCurrentTimeMillis();
    
    dispatch_async(self.callbackQueue, ^{
        
        if (self.startBlock != nil)
        {
            self.startBlock();
            self.startBlock = nil;
        }
    });

    return YES;
}

- (BOOL)executionFailedWithFinalResponse:(BBHTTPResponse*)response error:(NSError*)error
{
    if ([self hasFinished]) return NO;

    _endTimestamp = BBHTTPCurrentTimeMillis();
    _error = error;
    _response = response;

    dispatch_async(self.callbackQueue, ^{
        
        if (self.finishBlock != nil)
        {
            self.finishBlock(self);
            self.finishBlock = nil;
        }
        
        self.uploadProgressBlock = nil;
        self.downloadProgressBlock = nil;
        
    });
                   
    return YES;
}

- (BOOL)uploadProgressedToCurrent:(NSUInteger)current ofTotal:(NSUInteger)total
{
    if ([self hasFinished]) return NO;

    _sentBytes = current;

    dispatch_async(self.callbackQueue, ^{
        
        if (self.uploadProgressBlock != nil)
        {
            self.uploadProgressBlock(current, total);
        }

    });
    
    return YES;
}

- (BOOL)downloadProgressedToCurrent:(NSUInteger)current ofTotal:(NSUInteger)total
{
    if ([self hasFinished]) return NO;

    _receivedBytes = current;
    
    dispatch_async(self.callbackQueue, ^{
        
        if (self.downloadProgressBlock != nil)
        {
            self.downloadProgressBlock(current, total);
        }
    });

    return YES;
}

@end
