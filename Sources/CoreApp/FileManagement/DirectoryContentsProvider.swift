//
//  DirectoryContentsProvider.swift
//  
//
//  Created by Illia Kniaziev on 27.03.2023.
//

import Foundation

final class DirectoryContentsProvider {
    private init() {}
    
    static func getFileUrls(
        withExtension aExtension: String,
        inDirectory directory: String,
        usingBasePath basePath: URL = Bundle.main.bundleURL
    ) throws -> [URL] {
        let path = basePath.appending(path: directory)
        let fileUrls = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
        return fileUrls.filter { $0.pathExtension == aExtension }
    }
    
}
