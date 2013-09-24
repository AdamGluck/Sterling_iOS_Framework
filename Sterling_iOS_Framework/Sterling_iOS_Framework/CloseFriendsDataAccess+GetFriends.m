//
//  CloseFriendsDataAccess+GetFriends.m
//  Sterling_iOS_Framework
//
//  Created by Adam Gluck on 9/23/13.
//  Copyright (c) 2013 Sterling. All rights reserved.
//

#import "CloseFriendsDataAccess+GetFriends.h"

#import <FacebookSDK/FacebookSDK.h>

@implementation CloseFriendsDataAccess (GetFriends)
static NSString * kSuggestionURL = @"http://sterling.herokuapp.com/suggestionsNodes";

-(void) getRequest: (NSURL *) url
{
    NSLog(@"get request with string =%@", url.absoluteString);
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    request.HTTPMethod = @"GET";
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

-(void)closeFriendsList
{
    NSString * urlRequest = [NSString stringWithFormat:@"%@/app_id=%@&user_id=%@/.json", kSuggestionURL, [[FBSession activeSession] appID], [self.class fb_id]];
    [self getRequest:[NSURL URLWithString:urlRequest]];
}

@end
