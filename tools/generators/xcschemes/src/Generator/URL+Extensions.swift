import Foundation
extension URL {
    func relativize(from source: URL) -> String {
        let sourceComponents = source.deletingLastPathComponent().pathComponents
        let destComponents = self.pathComponents
        
        // Find common prefix
        var commonPrefixCount = 0
        while commonPrefixCount < sourceComponents.count && 
              commonPrefixCount < destComponents.count && 
              sourceComponents[commonPrefixCount] == destComponents[commonPrefixCount] {
            commonPrefixCount += 1
        }
        
        // Build relative path
        var result = [String]()
        
        // Add "../" for each level to go up
        result.append(contentsOf: Array(repeating: "..", count: sourceComponents.count - commonPrefixCount))
        
        // Add remaining destination components
        result.append(contentsOf: destComponents[commonPrefixCount...])
        
        return result.joined(separator: "/")
    }
}