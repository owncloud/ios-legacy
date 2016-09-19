//
//  FileNameUtilsTests.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 24/8/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

// Under test
#import "FileNameUtils.h"
#import "MoveFile.h"

// Test support
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@interface FileNameUtils ()
-(void) isImageSupportedThisObject;
-(void) checkTheTypeOfFile;
@end

@interface FileNameUtilsTests : XCTestCase
 @property (nonatomic) FileNameUtils *oFileNameUtils;
@end

@implementation FileNameUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
     self.oFileNameUtils = [[FileNameUtils alloc] init];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - getExtension test with performance measure
- (void)testGetUpperCaseExtensionByFilenameWithOneExtension {
    //given
    NSString *originalFileName = @"test.pdf";
    NSString *expectedExtension = @"PDF";
    __block NSString *extension = @"";
    
    //when
    [self measureBlock:^{
        extension = [FileNameUtils getExtension:originalFileName];
    }];
    
    //then
    XCTAssertEqualObjects(expectedExtension, extension, @"The extension .pdf string did not match the expected extension PDF");
}

- (void)testGetUpperCaseExtensionByFilenameWithComposedValidExtension {
    //given
    NSString *originalFileName = @"test.pages.zip";
    NSString *expectedExtension = @"PAGES.ZIP";
    __block NSString *extension = @"";
    
    //when
    [self measureBlock:^{
        extension = [FileNameUtils getExtension:originalFileName];
    }];
    
    //then
    XCTAssertEqualObjects(expectedExtension, extension, @"The extension pages.zip string did not match the expected extension PAGES.ZIP");
}

- (void)testGetUpperCaseExtensionByFilenameWithTwoExtension {
    //given
    NSString *originalFileName = @"test.pdf.zip";
    NSString *expectedExtension = @"ZIP";
    __block NSString *extension = @"";
    
    //when
    [self measureBlock:^{
        extension = [FileNameUtils getExtension:originalFileName];
    }];
    
    //then
    XCTAssertEqualObjects(expectedExtension, extension, @"The extension pdf.zip string did not match the expected extension ZIP");
}


# pragma mark - mock tests

- (void)testOCMockEqual {
    id mock = [OCMockObject mockForClass:NSString.class];
    [[[mock stub] andReturn:@"mocktest"] lowercaseString];
    
    NSString *expectedReturn = @"mocktest";
    
    NSString *returnValue = [mock lowercaseString];
    
    
    XCTAssertEqualObjects(expectedReturn, returnValue, @"The return value did not match the expected return value");
    
}


- (void)testOCMockNotEqual {
    id mock = [OCMockObject mockForClass:NSString.class];
    [[[mock stub] andReturn:@"mocktest"] lowercaseString];
    
    NSString *expectedReturn = @"mocktestNoEqual";
    
    NSString *returnValue = [mock lowercaseString];
    
    
    XCTAssertNotEqualObjects(expectedReturn, returnValue, @"The return value match the expected return value");
    
}


@end
