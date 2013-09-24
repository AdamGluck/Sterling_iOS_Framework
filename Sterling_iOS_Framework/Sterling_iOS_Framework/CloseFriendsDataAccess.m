//
//  CloseFriendsDataAccess.m
//  Sterling_iOS
//
//  Created by Adam Gluck on 9/9/13.
//  Copyright (c) 2013 Sterling. All rights reserved.
//

#import "CloseFriendsDataAccess.h"
#import <FacebookSDK/FacebookSDK.h>
@interface CloseFriendsDataAccess()

@property (strong, nonatomic) NSMutableData * data;
@property (strong, nonatomic) NSHTTPURLResponse* httpResponse;

@end

@implementation CloseFriendsDataAccess

static NSString * kFBURL = @"http://sterling.herokuapp.com/fbNodes";
static NSString * kSuggestionURL = @"http://sterling.herokuapp.com/suggestionsNodes";
static NSString * kInvitationURL = @"http://sterling.herokuapp.com/invitationsNodes";

-(void) getRequest: (NSURL *) url
{
    NSLog(@"get request with string =%@", url.absoluteString);
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    request.HTTPMethod = @"GET";
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

-(void)postRequest:(NSURL *)url withBody:(NSDictionary *) body
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    NSError * error;
    NSData * data = [NSJSONSerialization dataWithJSONObject:body
                                                    options:kNilOptions error:&error];
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"request body = %@ and request url = %@", string, url.absoluteString);
    request.HTTPBody = data;
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

-(void)patchRequest:(NSURL *)url withBody:(NSDictionary *) body
{
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    [request setValue:@"PATCH" forHTTPHeaderField:@"X-HTTP-Method-Override"];
    NSError * error;
    NSData * data = [NSJSONSerialization dataWithJSONObject:body
                                                    options:kNilOptions error:&error];
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"request body = %@ and request url = %@", string, url.absoluteString);
    request.HTTPBody = data;
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

#pragma mark - Utility Methods

-(BOOL)connection:(NSURLConnection *)connection matchesRegex:(NSString *)pattern
{
    NSString * urlString = connection.originalRequest.URL.absoluteString;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    __block BOOL found = NO;
    [regex enumerateMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        if ([match rangeAtIndex:0].location != NSNotFound){
            found = YES;
        }
    }];
    return found;
}

-(BOOL)connectionWasPatchRequest:(NSURLConnection *)connection
{
    return [[connection.originalRequest valueForHTTPHeaderField:@"X-HTTP-Method-Override"] isEqualToString:@"PATCH"];
}

-(BOOL)connectionWasPostRequest:(NSURLConnection *)connection
{
    return [connection.originalRequest.HTTPMethod isEqualToString:@"POST"];
}

-(BOOL)connectionWasGetRequest:(NSURLConnection *)connection
{
    return [connection.originalRequest.HTTPMethod isEqualToString:@"GET"];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.httpResponse = (NSHTTPURLResponse*)response;
    self.data.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate sterlingServerResponse:SterlingRequestNoResponse];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError * jsonSerializationError;
    NSDictionary * json = [NSJSONSerialization
                           JSONObjectWithData:self.data
                           options:kNilOptions
                           error:&jsonSerializationError];
    
    if (jsonSerializationError){
        NSLog(@"json error: %@", jsonSerializationError);
    }
    
    [self didReceiveDictionary:json fromConnection:connection withResponse:self.httpResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"authentication challenge");
    /*
     NSString *username = @"username";
     NSString *password = @"password";
     
     NSURLCredential *credential = [NSURLCredential credentialWithUser:username
     password:password
     persistence:NSURLCredentialPersistenceForSession];
     [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
     */
}

#pragma mark - Public Methods

-(void)sterlingUserLogin
{
    NSLog(@"login called");
    if (![self.class loggedIn]){
        NSLog(@"!loggedIn");
        [FBRequestConnection
         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                           id<FBGraphUser> user,
                                           NSError *error) {
             NSLog(@"completed");
             if (!error) {
                 NSLog(@"!error");
                 NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
                 [defaults setObject:user.id forKey:fb_id_key];
                 NSString * urlRequest = [NSString stringWithFormat:@"%@/", kFBURL];
                 NSDictionary * postBody = @{@"user_id": user.id, @"o_auth_token": [[FBSession activeSession] accessTokenData].accessToken, @"current_app_id": [[FBSession activeSession] appID]};
                 NSLog(@"post body = %@ to URL %@", postBody, urlRequest);
                 [self postRequest:[NSURL URLWithString:urlRequest] withBody:postBody];
             } else {
                 NSLog(@"error = %@", error);
                 [self.delegate sterlingServerResponse:SterlingRequestFailed];
             }
         }];
    }
}

-(void)closeFriendsList
{
    NSString * urlRequest = [NSString stringWithFormat:@"%@/app_id=%@&user_id=%@/.json", kSuggestionURL, [[FBSession activeSession] appID], [self.class fb_id]];
    [self getRequest:[NSURL URLWithString:urlRequest]];
}

-(void)invitationsPostedToUsers:(NSArray *) invitationList
{
    NSString * urlRequest = [NSString stringWithFormat:@"%@/", kInvitationURL];
    NSDictionary * postBody = @{@"inviter": [self.class fb_id], @"app": [[FBSession activeSession] appID], @"invited_list": invitationList, @"node_id": @"shouldn't have to be there, famous last words"};
    [self postRequest:[NSURL URLWithString:urlRequest] withBody:postBody];
}

#pragma mark - methods

static NSString * logged_in_key = @"sterling_user_logged_in_and_registered1234";
static NSString * fb_id_key = @"sterling_facebook_user_id_storage1234";

-(void)didReceiveDictionary:(NSDictionary*)dictionary fromConnection:(NSURLConnection *)connection withResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"%i %@", response.statusCode, dictionary);
    if (response.statusCode >= 400){
        [self.delegate sterlingServerResponse:SterlingRequestFailed];
        return;
    }
    
    if ([self connection:connection matchesRegex:kInvitationURL]){
        [self.delegate sterlingServerResponse:SterlingInvitationSucceeded];
    }
    
    if ([self connection:connection matchesRegex:kSuggestionURL]){
        NSLog(@"connection worked!");
        NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:logged_in_key];
        [self.delegate closeFriendsList:dictionary];
        return;
    }
    
    if ([self connection:connection matchesRegex:kFBURL]){
        [self.delegate sterlingServerResponse:SterlingLoginSucceded];
        return;
    }
}

+(NSString *)fb_id
{
    NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
    return [defaults objectForKey:fb_id_key];
}

+(BOOL)loggedIn
{
    NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
    return [[defaults objectForKey:logged_in_key] boolValue];
}

#pragma mark - lazy instantiation

-(NSMutableData *) data
{
    if (!_data){
        _data = [[NSMutableData alloc] init];
    }
    return _data;
}

@end
