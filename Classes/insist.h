/*
 *  insist.h
 *  Penrose
 *
 *  Created by finucane on 11/21/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#define insist(e) if(!(e)) [NSException raise: @"error." format: @"%@:%d (%s)", [[NSString stringWithCString:__FILE__] lastPathComponent], __LINE__, #e]
