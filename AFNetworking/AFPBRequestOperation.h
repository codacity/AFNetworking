//
//  AFPBRequestOperation.h
//  Syncer
//
//  Created by Valeriy Dyryavyy on 02/09/2012.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

/**
 `AFPBRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and working with ProtocolBuffers response data.
 
 ## Acceptable Content Types
 
 By default, `AFPBRequestOperation` accepts the following MIME types, which includes the unofficial naming, `application/x-protobuf`, as well as other commonly-used type:
 
 - `application/octet-stream`
 */
@interface AFPBRequestOperation : AFHTTPRequestOperation

@property (readonly, nonatomic, retain) id responsePBMessage;
@property (readwrite, nonatomic, copy) NSString *expectedPBMessageName;

+ (AFPBRequestOperation *)PBRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                  expectedPBMessageName:(NSString *)expectedMsgName
                                                success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id PBMessage))success
                                                failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id PBMessage))failure;

@end
