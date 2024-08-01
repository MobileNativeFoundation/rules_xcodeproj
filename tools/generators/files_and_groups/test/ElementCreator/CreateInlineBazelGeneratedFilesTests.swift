import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateInlineBazelGeneratedFilesTests: XCTestCase {
    
    func testMultipleConfigs() throws {
        let simConfig = PathTreeNode.GeneratedFiles.Config(name: "ios-sim", path: "ios-sim/bin", children: [
            .file(name: "fileA")
        ])
        let deviceConfig = PathTreeNode.GeneratedFiles.Config(name: "ios-device", path: "ios-device/bin", children: [
            .file(name: "fileA")
        ])
        let generatedFiles = PathTreeNode.GeneratedFiles.multipleConfigs([
            simConfig,
            deviceConfig
        ])
        
        let iosSimGroupChildElementAndChildren = GroupChild.ElementAndChildren(
            bazelPath: BazelPath("ios-sim/bin"),
            element: .init(
                name: "ios-sim",
                object: .init(
                    identifier: "ios-sim-identifier",
                    content: ""
                ),
                sortOrder: .groupLike),
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: .init(
                elements: [],
                transitiveObjects: [],
                bazelPathAndIdentifiers: [],
                knownRegions: [], resolvedRepositories: []
            )
        )
        let iosDeviceGroupChildElementAndChildren = GroupChild.ElementAndChildren(
            bazelPath: BazelPath("ios-device/bin"),
            element: .init(
                name: "ios-device",
                object: .init(
                    identifier: "ios-device-identifier",
                    content: ""
                ),
                sortOrder: .groupLike),
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: .init(
                elements: [],
                transitiveObjects: [],
                bazelPathAndIdentifiers: [],
                knownRegions: [], resolvedRepositories: []
            )
        )
        let expectedParentBazelPath = BazelPath("bazel-out")
        
        let stubbedGroupChildElements: [GroupChild.ElementAndChildren] = [
            iosSimGroupChildElementAndChildren,
            iosDeviceGroupChildElementAndChildren
        ]
        
        let createInlineBazelGeneratedConfigGroup = ElementCreator.CreateInlineBazelGeneratedConfigGroup.mock(groupChildElements: stubbedGroupChildElements)
        
        let expectedCreateInlineBazelGeneratedConfigGroup: [ElementCreator.CreateInlineBazelGeneratedConfigGroup.MockTracker.Called] = [
            .init(config: simConfig, parentBazelPath: expectedParentBazelPath),
            .init(config: deviceConfig, parentBazelPath: expectedParentBazelPath)
        ]
        
        let stubbedCreateGroupChildElement = GroupChildElements(
            elements: [
                .init(
                    name: "ios-sim/bin",
                    object: .init(
                        identifier: "ios-sim-identifier",
                        content: ""
                    ),
                    sortOrder: .groupLike),
                .init(
                    name: "ios-device/bin",
                    object: .init(
                        identifier: "ios-device-identifier",
                        content: ""
                    ),
                    sortOrder: .groupLike)
            ],
            transitiveObjects: [],
            bazelPathAndIdentifiers: [],
            knownRegions: [],
            resolvedRepositories: []
        )
        let createGroupChildElements = ElementCreator.CreateGroupChildElements.mock(
            groupChildElements: stubbedCreateGroupChildElement
        )
        
        let expectedCreateGroupChildElements: [ElementCreator.CreateGroupChildElements.MockTracker.Called] = [
            .init(
                parentBazelPath: expectedParentBazelPath,
                groupChildren: [
                    .elementAndChildren(iosSimGroupChildElementAndChildren),
                    .elementAndChildren(iosDeviceGroupChildElementAndChildren),
                ],
                resolvedRepositories: []
            )
        ]
        
        let stubbedCreateInlineBazelGeneratedFilesElement = Element(
            name: "bazel-out",
            object: .init(
                identifier: "bazel-out-identifier",
                content: ""
            ),
            sortOrder: .groupLike
        )
        let createInlineBazelGeneratedFilesElement = ElementCreator.CreateInlineBazelGeneratedFilesElement.mock(
            element: stubbedCreateInlineBazelGeneratedFilesElement
        )
        let expectedCreateInlineBazelGeneratedFilesElement: [ElementCreator.CreateInlineBazelGeneratedFilesElement.MockTracker.Called] = [
            .init(
                path: "bazel-out",
                childIdentifiers: ["ios-sim-identifier", "ios-device-identifier"]
            )
        ]
        
        let result = ElementCreator.CreateInlineBazelGeneratedFiles.defaultCallable(
            for: generatedFiles,
            createGroupChild: ElementCreator.Stubs.createGroupChild,
            createGroupChildElements: createGroupChildElements.mock,
            createInlineBazelGeneratedConfigGroup: createInlineBazelGeneratedConfigGroup.mock,
            createInlineBazelGeneratedFilesElement: createInlineBazelGeneratedFilesElement.mock
        )
        
        let expectedResult = GroupChild.ElementAndChildren(
            bazelPath: expectedParentBazelPath,
            element: stubbedCreateInlineBazelGeneratedFilesElement,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: stubbedCreateGroupChildElement
        )
        XCTAssertNoDifference(
            createInlineBazelGeneratedConfigGroup.tracker.called,
            expectedCreateInlineBazelGeneratedConfigGroup
        )
        
        XCTAssertNoDifference(
            createGroupChildElements.tracker.called,
            expectedCreateGroupChildElements
        )
        
        XCTAssertNoDifference(
            expectedCreateInlineBazelGeneratedFilesElement,
            createInlineBazelGeneratedFilesElement.tracker.called
        )
        
        XCTAssertNoDifference(
            result,
            expectedResult
        )
    }
    
    func testSingleConfig() throws {
        let configChild = PathTreeNode.file(name: "fileA")
        let generatedFiles = PathTreeNode.GeneratedFiles.singleConfig(
            path: "ios-sim",
            children: [configChild]
        )
        
        let iosSimGroupChildElementAndChildren = GroupChild.ElementAndChildren(
            bazelPath: BazelPath("ios-sim/bin/fileA"),
            element: .init(
                name: "fileA",
                object: .init(
                    identifier: "fileA-identifier",
                    content: ""
                ),
                sortOrder: .groupLike
            ),
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: .init(
                elements: [],
                transitiveObjects: [],
                bazelPathAndIdentifiers: [],
                knownRegions: [], resolvedRepositories: []
            )
        )
        let expectedParentBazelPath = BazelPath("bazel-out/ios-sim")
        
        let createGroupChild = ElementCreator.CreateGroupChild.mock(children: [
            .elementAndChildren(iosSimGroupChildElementAndChildren)
        ])
        
        let expectedCreateGroupChild: [ElementCreator.CreateGroupChild.MockTracker.Called] =
        [
            .init(
                node: configChild,
                parentBazelPath: expectedParentBazelPath,
                parentBazelPathType: .bazelGenerated
            )
        ]
        

        let stubbedCreateGroupChildElement = GroupChildElements(
            elements: [
                .init(
                    name: "ios-sim/bin",
                    object: .init(
                        identifier: "ios-sim-identifier",
                        content: ""
                    ),
                    sortOrder: .groupLike
                )
            ],
            transitiveObjects: [],
            bazelPathAndIdentifiers: [],
            knownRegions: [],
            resolvedRepositories: []
        )
        let createGroupChildElements = ElementCreator.CreateGroupChildElements.mock(
            groupChildElements: stubbedCreateGroupChildElement
        )
        
        let expectedCreateGroupChildElements: [ElementCreator.CreateGroupChildElements.MockTracker.Called] = [
            .init(
                parentBazelPath: expectedParentBazelPath,
                groupChildren: [
                    .elementAndChildren(iosSimGroupChildElementAndChildren),
                ],
                resolvedRepositories: []
            )
        ]
        
        let stubbedCreateInlineBazelGeneratedFilesElement = Element(
            name: "bazel-out/ios-sim",
            object: .init(
                identifier: "bazel-out-identifier",
                content: ""
            ),
            sortOrder: .groupLike
        )
        let createInlineBazelGeneratedFilesElement = ElementCreator.CreateInlineBazelGeneratedFilesElement.mock(
            element: stubbedCreateInlineBazelGeneratedFilesElement
        )
        let expectedCreateInlineBazelGeneratedFilesElement: [ElementCreator.CreateInlineBazelGeneratedFilesElement.MockTracker.Called] = [
            .init(
                path: "bazel-out/ios-sim",
                childIdentifiers: ["ios-sim-identifier"]
            )
        ]
        
        let result = ElementCreator.CreateInlineBazelGeneratedFiles.defaultCallable(
            for: generatedFiles,
            createGroupChild: createGroupChild.mock,
            createGroupChildElements: createGroupChildElements.mock,
            createInlineBazelGeneratedConfigGroup: ElementCreator.Stubs.createInlineBazelGeneratedConfigGroup,
            createInlineBazelGeneratedFilesElement: createInlineBazelGeneratedFilesElement.mock
        )
        
        let expectedResult = GroupChild.ElementAndChildren(
            bazelPath: expectedParentBazelPath,
            element: stubbedCreateInlineBazelGeneratedFilesElement,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: stubbedCreateGroupChildElement
        )
        
        XCTAssertNoDifference(
            createGroupChild.tracker.called,
            expectedCreateGroupChild
        )
        
        XCTAssertNoDifference(
            createGroupChildElements.tracker.called,
            expectedCreateGroupChildElements
        )
        
        XCTAssertNoDifference(
            expectedCreateInlineBazelGeneratedFilesElement,
            createInlineBazelGeneratedFilesElement.tracker.called
        )
        
        XCTAssertNoDifference(
            result,
            expectedResult
        )
    }
}
