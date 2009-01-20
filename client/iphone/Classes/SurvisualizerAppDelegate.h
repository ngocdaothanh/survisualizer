//
//  SurvisualizerAppDelegate.h
//  Survisualizer
//
//  Created by Ngoc Dao on 1/20/09.
//  Copyright VTM 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface SurvisualizerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

