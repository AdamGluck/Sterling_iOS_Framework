//
//  CloseFriendsDataAccess.h
//  Sterling_iOS
//
//  Created by Adam Gluck on 9/9/13.
//  Copyright (c) 2013 Sterling. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CloseFriendsDataAccessDelegate <NSObject>

typedef NS_ENUM(NSInteger, SterlingRequestServerResponse){
    SterlingRequestFailed,
    SterlingRequestNoResponse,
    SterlingRequestProcessing,
    SterlingInvitationSucceeded,
    SterlingLoginSucceded
};

-(void)closeFriendsList:(NSDictionary *)list;
-(void)sterlingServerResponse: (SterlingRequestServerResponse) response;

@end

@interface CloseFriendsDataAccess : NSObject

@property (weak, nonatomic) id <CloseFriendsDataAccessDelegate> delegate;

-(void)sterlingUserLogin;
-(void)invitationsPostedToUsers: (NSArray *) invitationList;

+(NSString *)fb_id;
+(BOOL)loggedIn;

@end
