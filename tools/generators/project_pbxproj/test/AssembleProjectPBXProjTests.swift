import CustomDump
import ToolCommon
import XCTest

@testable import project_pbxproj

class AssembleProjectPBXProjTests: XCTestCase {
    func test_partials() throws {
        // Arrange

        // The same partials that the generators create: objects of the same
        // `isa` are spread across partials, and identifiers are out of order
        let partials = [
            // pbxproj_prefix
            #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 70;
	objects = {
		FF0100000000000000000100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				TARGET_NAME = BazelDependencies;
			};
			name = Debug;
		};
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			name = BazelDependencies;
		};
		FF0000000000000000000100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				SRCROOT = /tmp/workspace;
			};
			name = Debug;
		};
		FF0000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				LastUpgradeCheck = 9999;
			};
			knownRegions = (
				en,
			);
			targets = (
				FF0100000000000000000001 /* BazelDependencies */,
				0100000000000000000000A1 /* App */,
			);
		};

"""#,
            // pbxnativetargets
            #"""
		0100000000000000000000A1 /* App */ = {
			isa = PBXNativeTarget;
			name = App;
		};
		0100000000000000000000B2 /* b.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0100000000000000000000F2 /* b.swift */; };

"""#,
            // files_and_groups
            #"""
		0100000000000000000000F2 /* b.swift */ = {isa = PBXFileReference; path = b.swift; sourceTree = "<group>"; };
		0100000000000000000000B1 /* a.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0100000000000000000000F1 /* a.swift */; };
		0100000000000000000000F1 /* a.swift */ = {isa = PBXFileReference; path = a.swift; sourceTree = "<group>"; };
	};
	rootObject = FF0000000000000000000001 /* Project object */;
}

"""#,
        ]

        let expectedProjectPBXProj = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 70;
	objects = {

/* Begin PBXAggregateTarget section */
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			name = BazelDependencies;
		};
/* End PBXAggregateTarget section */

/* Begin PBXBuildFile section */
		0100000000000000000000B1 /* a.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0100000000000000000000F1 /* a.swift */; };
		0100000000000000000000B2 /* b.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0100000000000000000000F2 /* b.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		0100000000000000000000F1 /* a.swift */ = {isa = PBXFileReference; path = a.swift; sourceTree = "<group>"; };
		0100000000000000000000F2 /* b.swift */ = {isa = PBXFileReference; path = b.swift; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXNativeTarget section */
		0100000000000000000000A1 /* App */ = {
			isa = PBXNativeTarget;
			name = App;
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		FF0000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				LastUpgradeCheck = 9999;
			};
			knownRegions = (
				en,
			);
			targets = (
				FF0100000000000000000001 /* BazelDependencies */,
				0100000000000000000000A1 /* App */,
			);
		};
/* End PBXProject section */

/* Begin XCBuildConfiguration section */
		FF0000000000000000000100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				SRCROOT = /tmp/workspace;
			};
			name = Debug;
		};
		FF0100000000000000000100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				TARGET_NAME = BazelDependencies;
			};
			name = Debug;
		};
/* End XCBuildConfiguration section */
	};
	rootObject = FF0000000000000000000001 /* Project object */;
}

"""#

        // Act

        let projectPBXProj = try assemble(partials)

        // Assert

        XCTAssertNoDifference(projectPBXProj, expectedProjectPBXProj)
    }

    func test_noObjects() throws {
        let partials = [
            "{\n\tobjectVersion = 70;\n\tobjects = {\n",
            "\t};\n\trootObject = FF0000000000000000000001;\n}\n",
        ]

        XCTAssertNoDifference(try assemble(partials), partials.joined())
    }

    func test_singleLineISAInComment() throws {
        let partials = [#"""
	objects = {
		B /* isa = PBXGroup; */ = {isa = PBXFileReference; path = b; };
		A /* a */ = {isa = PBXGroup; path = a; };
	};

"""#]

        let expectedProjectPBXProj = #"""
	objects = {

/* Begin PBXFileReference section */
		B /* isa = PBXGroup; */ = {isa = PBXFileReference; path = b; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
		A /* a */ = {isa = PBXGroup; path = a; };
/* End PBXGroup section */
	};

"""#

        XCTAssertNoDifference(try assemble(partials), expectedProjectPBXProj)
    }

    func test_missingObjects() {
        assertMalformed(
            ["{\n\tobjectVersion = 70;\n}\n"],
            "Malformed 'PBXProj' partials: missing the 'objects = {' line"
        )
    }

    func test_objectWithoutISA() {
        assertMalformed(
            ["\tobjects = {\n\t\tA = {\n\t\t\tname = a;\n\t\t};\n\t};\n"],
            "Malformed 'PBXProj' partials (line 2): object without an 'isa'"
        )
        assertMalformed(
            ["\tobjects = {\n\t\tA = {name = a; };\n\t};\n"],
            "Malformed 'PBXProj' partials (line 2): object without an 'isa'"
        )
    }

    func test_unterminatedObject() {
        assertMalformed(
            ["\tobjects = {\n\t\tA = {\n\t\t\tisa = PBXGroup;\n"],
            "Malformed 'PBXProj' partials (line 2): unterminated object"
        )
        assertMalformed(
            [#"""
	objects = {
		A = {
			isa = PBXGroup;
		B = {isa = PBXGroup; };
		};
	};

"""#],
            "Malformed 'PBXProj' partials (line 2): unterminated object"
        )
    }
}

private func assemble(_ partials: [String]) throws -> String {
    var output: [UInt8] = []
    try Generator.assembleProjectPBXProj(
        Array(partials.joined().utf8)
    ) { bytes in
        output.append(contentsOf: bytes)
    }
    return String(decoding: output, as: UTF8.self)
}

private func assertMalformed(
    _ partials: [String],
    _ message: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertThrowsError(try assemble(partials), file: file, line: line) {
        XCTAssertNoDifference(
            ($0 as? PreconditionError)?.message,
            message,
            file: file,
            line: line
        )
    }
}
