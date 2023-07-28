# Why generate Compile Commands
1. I hope to use Bazel to develop C/C++/ObjC/ObjC++/Swift under VSCode. So I need to get SourceKit-LSP working on VSCode. Therefore, it is necessary to generate compilation commands to cooperate with SourceKit-LSP to be able to use code completion normally.
2. Although Xcode's indexing mechanism may be the best among mainstream IDEs, it is often left to wait for Index Building because it is not open enough. So another goal is to quickly generate a global index through Compile Commands after having the ability to take over the Xcode global index, and to continue working in the background.
# What are Index Compile Commands
Index Compile Commands refers to the processing of complete compilation instructions to obtain compilation instructions that are only used for code indexing.
1. After running through Index Compile Commands, there is no need to produce target files and IndexStoreDB can be generated at the same time. Such as -index-store-path.
2. The IDE that supports the libClang type can execute a compilation instruction without outputting the target file and at the same time obtain the AST corresponding to the source code. For example -fsyntax-only.

# Purpose of Compile Commands in rules_xcodeproj Build with Proxy (BwP)
Although currently rules_xcodeproj does not support BwP yet. This design may not work. If BwP is supported. We can use XCBBuildService to modify IndexRequest. According to Index Compile Commands, modify IndexRequest compilation parameters to more accurate parameters for indexing. This enables the libClang module in Xcode to get a more accurate AST.

# Post process rules
Here are some post process rules.

## For C/C++/ObjC/ObjC++
|   Add   |  Delete  | Replace  |
|  ----   |   ----   |   ----   |
| -index-store-path  | DEBUG_PREFIX_MAP_PWD=. |   \_\_BAZEL_XCODE_SDKROOT\_\_ |
| -index-unit-output-path  | -o <path/to/obj> |   \_\_BAZEL_XCODE_DEVELOPER_DIR\_\_ |
| -index-ignore-macros  | --serialize-diagnostics | - |
| -index-ignore-system-symbols  | -MMD | - |
| -index-ignore-pcms  | -MF | - |
| -fsyntax-only  | - | - |

## For Swift
|   Add   |  Delete  | Replace  |
|  ----   |   ----   |   ----   |
| -index-store-path  | DEBUG_PREFIX_MAP_PWD=. |   \_\_BAZEL_XCODE_SDKROOT\_\_ |
| -index-unit-output-path  |  -enable-batch-mode |   \_\_BAZEL_XCODE_DEVELOPER_DIR\_\_ |
| - |  -emit-object | - |
| - |  -serialize-diagnostics | - |
