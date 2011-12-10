//
//  Debug.h
//  chaocovietnam
//
//  Created by Son Dao Hoang on 12/6/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#ifndef chaocovietnam_Debug_h
#define chaocovietnam_Debug_h

#ifdef DEBUG
#define DLog(s, ...) NSLog(s, ##__VA_ARGS__)
#else
#define DLog(s, ...)
#endif

#endif
