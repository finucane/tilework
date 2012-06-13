/*
 *  geometry.h
 *  Penrose
 *
 *  Created by finucane on 12/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef geometry_h
#define geometry_h

#define PHI 1.61803399

#import <UIKit/UIKit.h>

CGFloat area (CGPoint*points, int num_points);
void centroid (CGPoint*points, int num_points, CGFloat*x, CGFloat*y);
void move (CGPoint*points, int num_points, CGFloat x, CGFloat y);
void rotate (CGPoint*points, int num_points, CGFloat radians);
CGFloat magnitude (CGPoint point);
CGFloat distance (CGPoint a, CGPoint b);
BOOL point_inside_polygon (CGPoint*points, int num_points, CGPoint out_point, CGPoint p);
CGFloat intersection (CGPoint a, CGPoint b, CGPoint c, CGPoint d, CGPoint*p);
BOOL polygon_inside (CGPoint*a, int num_a, CGPoint*b, int num_b);
BOOL polygon_intersection (CGPoint*a, int num_a, CGPoint*b, int num_b, BOOL*inside);
double normalize_angle (double a);

#endif