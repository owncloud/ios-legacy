//
//  FileNameUtilsTests.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 24/8/15.
//
//

// Under test
#import "FileNameUtils.h"

// Test support
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@interface FileNameUtils (ExposeForTest)
-(void) isImageSupportedThisObject;
-(void) checkTheTypeOfFile;
@end

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

- (void)testOCMockVerify {
    id mock = [OCMockObject partialMockForObject:NSString.class];
    [[[mock stub] andReturn:@"mocktest"] lowercaseString];
    
    [[mock expect] lowercaseString];

    [mock verify];
    
}

//- (void)testOCMockManageAppSettingDB {
//    //check
//
//    //check method was invoked
//    id mock = [OCMockObject mockForClass:ManageAppSettingsDB.class];
//
//    //TODO create category
//    [[mock expect] insertCertificate];
//    [mock verify];
//}
//
//- (void)testOCMockAcceptCertificate {
//    //check
//
//    //check method was invoked
//    id mock = [OCMockObject mockForClass:CheckAccessToServer.class];
//    [[[mock stub] andReturn:@"mocktest"] lowercaseString];
//
//    id mock = [OCMockObject mockForClass:UtilsUrls.class];
//    [[[mock stub] andReturn:@"mocktest"] getOwnCloudFilePath];
//
//    //TODO create category
//    [[mock expect] insertCertificate];
//    [mock verify];
//}

- (void) testCheckTheTypeOfFile {
    
    //check method was invoked
    id mock = [OCMockObject mockForClass:FileNameUtils.class];
    [[[mock stub] andReturn:@"yes"] isImageSupportedThisFile:@"name"];
    long expectedReturn = 0;
    
    long returnValue = [mock checkTheTypeOfFile:@"name"];
    
    //[[mock expect] isImageSupportedThisFile];
    
    XCTAssertEqual(expectedReturn, returnValue, @"The return value did not match the expected return value");
    
    
}

- (void) testIsImageSupportedThisFile {
    
    FileNameUtils *obj = [[FileNameUtils alloc] init];
    id mock = [OCMockObject partialMockForObject:obj];
    //[[[mock stub] andReturn:@"JPG"] getExtension:@"name.JPG"];
    // long expectedReturn = 0;
    
    //long returnValue = [mock isImageSupportedThisFile:@"name"];
    //
    //tell the mock object what you expect
    [[mock expect] isImageSupportedThisFile:@"name.JPG"];
    //call the second method
    [mock checkTheTypeOfFile:@"name.JPG"];
    //verify if the first method expected is in invoked in the second one
    [mock verify];
    
    // XCTAssertEqual(expectedReturn, returnValue, @"The return value did not match the expected return value");
    
    
}


- (void) testIsImageSupportedThisFileIsInvoked {
    
    //check method was invoked
    FileNameUtils *obj = [[FileNameUtils alloc] init];
    id mock = [OCMockObject partialMockForObject:obj];
    
    [[mock expect] isImageSupportedThisFile:@"name"];
    
    [mock checkTheTypeOfFile:@"name"];
    
    [mock verify];
    
}

- (void) testIsImageSupportedThisFileIsInvoked_ {
    
    //check method was invoked
    id mock = [OCMockObject mockForClass:FileNameUtils.class];
    
    [[mock expect] isImageSupportedThisFile:@"name"];
    
    [mock checkTheTypeOfFile:@"name"];
    
    [mock verify];
    
}

- (void) testIsVideoFileSupportedThisFile {
    
    //check method was invoked
    FileNameUtils *obj = [[FileNameUtils alloc] init];
    id mock = [OCMockObject partialMockForObject:obj];
    
    [[mock expect] isImageSupportedThisFile:@"name"];
    
    [mock isImageSupportedThisObject];
    
    [mock verify];
    
}

- (void) testReject {
    
}



@end
