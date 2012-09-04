//
//  AFPBRequestOperation.m
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

#import "AFPBRequestOperation.h"

static dispatch_queue_t af_pb_request_operation_processing_queue;
static dispatch_queue_t pb_request_operation_processing_queue()
{
   if (af_pb_request_operation_processing_queue == NULL)
   {
      af_pb_request_operation_processing_queue = dispatch_queue_create("com.syncer.networking.pb-request.processing", 0);
   }
   
   return af_pb_request_operation_processing_queue;
}

@interface AFPBRequestOperation ()
@property (readwrite, nonatomic, retain) id responsePBMessage;
@property (readwrite, nonatomic, retain) NSError *PBError;
@end

@implementation AFPBRequestOperation
@synthesize responsePBMessage = _responsePBMessage;
@synthesize PBError = _PBError;
@synthesize expectedPBMessageName = _expectedPBMessageName;

+ (AFPBRequestOperation *)PBRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                  expectedPBMessageName:(NSString *)expectedMsgName
                                                success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id PBMessage))success
                                                failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id PBMessage))failure
{
   AFPBRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];
   requestOperation.expectedPBMessageName = expectedMsgName;
   
   [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
      if (success)
      {
         success(operation.request, operation.response, responseObject);
      }
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      if (failure)
      {
         failure(operation.request, operation.response, error, [(AFPBRequestOperation *)operation responsePBMessage]);
      }
   }];
   
   return requestOperation;
}

- (void)dealloc
{
   [_responsePBMessage release];
   [_expectedPBMessageName release];
   [_PBError release];
   [super dealloc];
}

- (id)responsePBMessage
{
   if (!_responsePBMessage && self.responseData.length > 0 && [self isFinished] && !self.PBError)
   {
      NSError *error = nil;
      
      if (self.responseData.length == 0)
      {
         self.responsePBMessage = nil;
      }
      else
      {
         Class pbMessageClass = NSClassFromString(self.expectedPBMessageName);
         
         if (pbMessageClass != nil)
         {
            @try
            {
               self.responsePBMessage = [pbMessageClass parseFromData:self.responseData];
            }
            @catch (NSException *exception)
            {
               self.responsePBMessage = nil;
               error = [NSError errorWithDomain:AFNetworkingErrorDomain
                                           code:0
                                       userInfo:[NSDictionary dictionaryWithObject:exception forKey:@"PB parsing exception"]];
            }
         }
         else
         {
            self.responsePBMessage = nil;
            error = [NSError errorWithDomain:AFNetworkingErrorDomain
                                        code:0
                                    userInfo:[NSDictionary dictionaryWithObject:@"Unable to load expected PB message class" forKey:@"Error"]];
         }
      }
      
      self.PBError = error;
   }
   
   return _responsePBMessage;
}

- (NSError *)error
{
   if (_PBError)
   {
      return _PBError;
   }
   else
   {
      return [super error];
   }
}

#pragma mark - AFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes
{
   return [NSSet setWithObjects:@"application/x-protobuf", @"application/octet-stream", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request
{
   return [[self acceptableContentTypes] intersectsSet:AFContentTypesFromHTTPHeader([request valueForHTTPHeaderField:@"Content-Type"])]
   || [super canProcessRequest:request];
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
   self.completionBlock = ^{
      if ([self isCancelled])
      {
         return;
      }
      
      if (self.error)
      {
         if (failure)
         {
            dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
               failure(self, self.error);
            });
         }
      }
      else
      {
         dispatch_async(pb_request_operation_processing_queue(), ^{
            id PBMessage = self.responsePBMessage;
            
            if (self.PBError)
            {
               if (failure)
               {
                  dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                     failure(self, self.error);
                  });
               }
            }
            else
            {
               if (success)
               {
                  dispatch_async(self.successCallbackQueue ? : dispatch_get_main_queue(), ^{
                     success(self, PBMessage);
                  });
               }
            }
         });
      }
   };
}

@end
