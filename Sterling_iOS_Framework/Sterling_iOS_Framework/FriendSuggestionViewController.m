//
//  FriendSuggestionViewController.m
//  Sterling_iOS
//
//  Created by Adam Gluck on 9/9/13.
//  Copyright (c) 2013 Sterling. All rights reserved.
//

#import "FriendSuggestionViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "CloseFriendsDataAccess+GetFriends.h"
#import <QuartzCore/QuartzCore.h>

@interface FriendSuggestionViewController () <CloseFriendsDataAccessDelegate>

@property (strong, nonatomic) NSArray * smartFriendList;
@property (strong, nonatomic) NSMutableArray * selectedFriends;
@property (assign, nonatomic) NSInteger indexOffset;
@end

@implementation FriendSuggestionViewController

+(FriendSuggestionViewController*)initializeFriendSuggestionViewController
{
    FriendSuggestionViewController * viewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateInitialViewController];
    return viewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _indexOffset = 0;
    NSLog(@"%@", [FBSettings sdkVersion]);
    if (!FBSession.activeSession.isOpen){
        [FBSession.activeSession openWithCompletionHandler:^(FBSession * session, FBSessionState state, NSError * error){
            if (!error){
                [self friendsListForCurrentFacebookUser];
            }
        }];
    } else {
        [self friendsListForCurrentFacebookUser];
    }
}

-(void) friendsListForCurrentFacebookUser
{
    CloseFriendsDataAccess * closeFriends = [[CloseFriendsDataAccess alloc] init];
    closeFriends.delegate = self;
    [FBRequestConnection
     startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                       id<FBGraphUser> user,
                                       NSError *error) {
         if (!error) {
             [closeFriends closeFriendsList];
         }
     }];
}

-(void)sterlingServerResponse: (SterlingRequestServerResponse) response
{
    if (response == SterlingRequestNoResponse){
        NSLog(@"No response");
    } else if (response == SterlingRequestFailed){
        NSLog(@"Failed");
    }
}

-(void)closeFriendsList:(NSDictionary *)list
{
    NSString * suggestionList = [(NSString *)list[@"suggestions_list"] stringByReplacingOccurrencesOfString:@"'\"" withString:@"\""];
    suggestionList = [suggestionList stringByReplacingOccurrencesOfString:@"\"'" withString:@"\""];
    suggestionList = [suggestionList stringByReplacingOccurrencesOfString:@"\xc3\xab" withString:@"e"];
    NSData * data = [suggestionList dataUsingEncoding:NSUTF8StringEncoding];
    NSError * e;
    id json = [NSJSONSerialization
               JSONObjectWithData:data
               options:kNilOptions
               error:&e];
    
    if (e){
        NSLog(@"%@",e);
    }
     
    self.smartFriendList = (NSArray *)json;
    [self.collectionView reloadData];
}



- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (section == 0){
        return 12;
    } else {
        return 3;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    cell.backgroundColor = [UIColor whiteColor];

    if (indexPath.section == 0){
        cell = [cv dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        FBProfilePictureView * profile = (FBProfilePictureView *) [cell viewWithTag:1];
        UITextField * textField = (UITextField *)[cell viewWithTag:2];
        
        NSDictionary * userInfo;
        if (self.smartFriendList.count - _indexOffset >= 12){
            userInfo = self.smartFriendList[indexPath.row + _indexOffset];
        } else if (self.smartFriendList.count - _indexOffset < 12){
            NSInteger remainingCells = self.smartFriendList.count - _indexOffset;
            if (self.smartFriendList.count - _indexOffset - indexPath.row - 1 < remainingCells){
                userInfo = self.smartFriendList[indexPath.row + _indexOffset];
            } else {
                userInfo = @{@"user_id":@"", @"user_name":@""};
                profile.profileID = nil;
                return cell;
            }
        }
        
        profile.profileID = nil;
        profile.profileID = userInfo[@"user_id"];
        textField.text = userInfo[@"user_name"];
        textField.font = [UIFont fontWithName:@"OpenSans-Bold" size:10.5f];

        if ([self.selectedFriends containsObject:userInfo]){
            UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 106.5, 106.5)];
            view.backgroundColor = [UIColor redColor];
            view.alpha = .6f;
            [cell.contentView insertSubview:view belowSubview:textField];
        }
    }
    
    if (indexPath.section == 1){
        switch (indexPath.row) {
            case 0:
                cell = [cv dequeueReusableCellWithReuseIdentifier:@"LastCell" forIndexPath:indexPath];
                break;
            case 1:
                cell = [cv dequeueReusableCellWithReuseIdentifier:@"SubmitCell" forIndexPath:indexPath];
                break;
            case 2:
                cell = [cv dequeueReusableCellWithReuseIdentifier:@"NextCell" forIndexPath:indexPath];
                break;
            default:
                break;
        }
    }
    
    return cell;
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && self.smartFriendList.count && self.smartFriendList.count > indexPath.row + _indexOffset){
        NSDictionary * userInfo = self.smartFriendList[indexPath.row + _indexOffset]; 
        UICollectionViewCell * cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        UITextField * textField = (UITextField *)[cell viewWithTag:2];
        
        if ([self.selectedFriends containsObject:userInfo]){
            [self.selectedFriends removeObject:userInfo];

            if ([cell viewWithTag: 3])[[cell viewWithTag:3] removeFromSuperview];
        } else {
            [self.selectedFriends addObject:userInfo];

            textField.alpha = 1.0f;
            UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 106.5, 106.5)];
            view.backgroundColor = [UIColor redColor];
            view.alpha = .6f;
            view.tag = 3;
            [cell.contentView insertSubview:view belowSubview:textField];
        }
        
    }
    
    if (indexPath.section == 1){
        if (indexPath.row == 0 && _indexOffset > 8){
            _indexOffset -= 12;
            [self.collectionView reloadData];
        }
        
        if (indexPath.row == 1){
            
            
            [self postAppRequestToSelectedUsers];
            if (self.selectedFriends.count){
                NSMutableArray * ids = [[NSMutableArray alloc] init];
                for (NSDictionary * userInfo in self.selectedFriends){
                    [ids addObject:userInfo[@"user_id"]];
                }
                
            }
            
        }
        
        if (indexPath.row == 2 && _indexOffset + 12 < self.smartFriendList.count){
            _indexOffset += 12;
            [self.collectionView reloadData];
        }
        
    }
}

-(void)postAppRequestToSelectedUsers
{
    NSMutableArray * ids = [[NSMutableArray alloc] init];
    for (NSDictionary * userInfo in self.selectedFriends){
        [ids addObject:userInfo[@"user_id"]];
    }
    
    if (![FBSession.activeSession.permissions containsObject:@"xmpp_login"]){
        [[FBSession activeSession] requestNewReadPermissions:@[@"xmpp_login"] completionHandler:^(FBSession * session, NSError * error){
            if (!error){
                CloseFriendsDataAccess * friendData = [[CloseFriendsDataAccess alloc] init];
                friendData.delegate = self;
                [friendData invitationsPostedToUsers:[ids copy]];
            }
        }];
    } else {
        CloseFriendsDataAccess * friendData = [[CloseFriendsDataAccess alloc] init];
        friendData.delegate = self;
        [friendData invitationsPostedToUsers:[ids copy]];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1){
        return CGSizeMake(106.5, 85.0);
    } else {
        return CGSizeMake(106, 106);
    }
}

-(NSMutableArray *)selectedFriends
{
    if (!_selectedFriends){
        _selectedFriends = [[NSMutableArray alloc] init];
    }
    
    return _selectedFriends;
}

-(NSArray *) selectionColors
{
    if (!_selectionColors){
        _selectionColors = [[NSArray alloc] init];
    }
    
    return _selectionColors;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
