//
//  DocumentPickerCell.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 5/12/14.
//
//

#import "CustomCellFileAndDirectory.h"
#import "FFCircularProgressView.h"

@interface DocumentPickerCell : CustomCellFileAndDirectory

@property(nonatomic, weak) IBOutlet FFCircularProgressView *circularPV;

@end
