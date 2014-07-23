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

#import "BBHTTPResponse.h"



#pragma mark - Utility functions

NSString* NSStringFromBBHTTPProtocolVersion(BBHTTPProtocolVersion version)
{
    switch (version) {
        case BBHTTPProtocolVersion_1_0:
            return @"HTTP/1.0";

        default:
            return @"HTTP/1.1";
    }
}

BBHTTPProtocolVersion BBHTTPProtocolVersionFromNSString(NSString* string)
{
    if ([string isEqualToString:@"HTTP/1.0"]) {
        return BBHTTPProtocolVersion_1_0;
    } else {
        return BBHTTPProtocolVersion_1_1;
    }
}



#pragma mark -

@implementation BBHTTPResponse
{
    NSMutableDictionary* _headers;
    BOOL _successful;
}


#pragma mark Creation

- (instancetype)initWithVersion:(BBHTTPProtocolVersion)version
                           code:(NSUInteger)code
                     andMessage:(NSString*)message
{
    self = [super init];
    if (self != nil) {
        _version = version;
        _code = code;
        _message = message;
        _headers = [NSMutableDictionary dictionary];
    }

    return self;
}


#pragma mark Public static methods

+ (BBHTTPResponse*)responseWithStatusLine:(NSString*)statusLine
{
    // TODO check size
    NSString* versionString = [statusLine substringToIndex:8];
    NSRange statusCodeRange = NSMakeRange(9, 3);
    NSString* statusCodeString = [statusLine substringWithRange:statusCodeRange];

    BBHTTPProtocolVersion version = BBHTTPProtocolVersionFromNSString(versionString);
    NSUInteger statusCode = (NSUInteger)[statusCodeString integerValue];

    NSString* message = [statusLine substringFromIndex:NSMaxRange(statusCodeRange) + 1];

    BBHTTPResponse* response = [[self alloc] initWithVersion:version code:statusCode andMessage:message];

    return response;
}


#pragma mark Interface

// override public getter for compatibility : we want a
// dict<string,string> to be returned even for "multiple" headers
// so that code reading the values don't break
-(NSDictionary*)headers {
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    if (!_headers) {
        return @{};
    }
    for (NSString *name in _headers) {
        id val = _headers[name];
        if ([val isKindOfClass:[NSArray class]]) {
            NSArray *valArray = val;
            if (valArray.count>0) {
                val = valArray[0];
            }
        }
        d[name] = val;
    }
    return [NSDictionary dictionaryWithDictionary:d];
}

- (void)finishWithContent:(id)content size:(NSUInteger)size successful:(BOOL)successful
{
    _content = content;
    _contentSize = size;
    _successful = successful;
}

- (NSString*)headerWithName:(NSString*)header
{
    id headerValues = _headers[header];
    if ([headerValues isKindOfClass:[NSString class]]) {
        // header is a string, return id directly
        return headerValues;
    } else if ([headerValues isKindOfClass:[NSArray class]]) {
        // header is an array of strings, get first element
        NSArray *vals = headerValues;
        if (vals.count>0) {
            return vals[0];
        }
    }
    return nil;
}

- (NSString*)objectForKeyedSubscript:(NSString*)header
{
    return [self headerWithName:header];
}

- (void)setValue:(NSString*)value forHeader:(NSString*)header
{
    id curVal = _headers[header];
    if (!curVal) {
        // no previously added headers, assign a string
        _headers[header] = value;
    } else {
        // already one (or more) headers, morph to an array if
        // needed and add element
        NSMutableArray *values;
        if ([curVal isKindOfClass:[NSString class]]) {
            values = [[NSMutableArray alloc] initWithArray:@[curVal]];
        } else {
            values = [NSMutableArray arrayWithArray:values];
        }
        [values addObject:value];
        _headers[header] = [NSArray arrayWithArray:values];
    }
}

- (void)setObject:(NSString*)value forKeyedSubscript:(NSString*)header
{
    [self setValue:value forHeader:header];
}

- (BOOL)isSuccessful
{
    return _successful;
}

- (NSArray*)headersWithName:(NSString*)header {
    id val = _headers[header];
    if (!val) {
        return @[];
    }
    if ([val isKindOfClass:[NSString class]]) {
        return @[val];
    } else {
        return val;
    }
}

#pragma mark Debug

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@{%lu, %@, %lu bytes of data}",
            NSStringFromClass([self class]), (unsigned long)_code, _message, (unsigned long)[self contentSize]];
}


@end
