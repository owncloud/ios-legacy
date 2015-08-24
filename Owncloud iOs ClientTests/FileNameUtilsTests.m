//
//  FileNameUtilsTests.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 24/8/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "FileNameUtils.h"

@interface FileNameUtilsTests : XCTestCase

@end

@implementation FileNameUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - getExtension
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



@end
