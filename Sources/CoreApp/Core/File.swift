//
//  LibsFactory.swift
//  
//
//  Created by Illia Kniaziev on 27.03.2023.
//

import Foundation
import PluginInterface

final class LibsFactory {
    
    private typealias InitFunction = @convention(c) () -> UnsafeMutableRawPointer
    
    private init() {}
    
    static func getReader(forData data: Data) -> ReaderPlugin? {
        let plugins = try? getPlugins(ofType: ReaderPlugin.self)
        return plugins?
            .first { $0.validate(data: data) }
    }

    static func getWriter(forExtension aExtension: String) -> WriterPlugin? {
        let plugins = try? getPlugins(ofType: WriterPlugin.self)
        return plugins?
            .first { $0.supportedFileType == aExtension }
    }
    
    private static func getPlugins<T: FilePlugin>(ofType: T.Type) throws -> [T] {
        let pluginPaths = try DirectoryContentsProvider.getFileUrls(
            withExtension: Configuration.dynamicLibExtension,
            inDirectory: Configuration.pluginsDirName)
        
        return pluginPaths
            .compactMap {
                do {
                    return try getPlugin(ofType: T.self, atPath: $0.absoluteString)
                } catch {
                    // TODO: Create a logger
                    print(error)
                    return nil
                }
            }
    }
    
    private static func getPlugin<T: FilePlugin>(ofType: T.Type, atPath path: String) throws -> T {
        let openRes = dlopen(path, RTLD_NOW|RTLD_LOCAL)
        if openRes != nil {
            defer {
                dlclose(openRes)
            }
            
            let symbolName = Configuration.PluginType.getSymbolName(forPluginOfType: T.self)
            let sym = dlsym(openRes, symbolName)
            if sym != nil {
                let f: InitFunction = unsafeBitCast(sym, to: InitFunction.self)
                let pluginPointer = f()
                let builder = Unmanaged<PluginBuilder<T>>.fromOpaque(pluginPointer).takeRetainedValue()
                return builder.build()
            }
            
            throw ReadError.symbolNotFound(symbolName: symbolName, path: path)
        }
        
        if let err = dlerror() {
            throw ReadError.dlError(errorString: String(format: "%s", err), path: path)
        }
        
        throw ReadError.unknownError(path: path)
    }
    
}

// MARK: - Configuration
private extension LibsFactory {
    enum Configuration {
        
        enum PluginType {
            static let reader = "readerPlugin"
            static let writer = "writerPlugin"
            
            static func getSymbolName<T: FilePlugin>(forPluginOfType type: T.Type) -> String {
                if T.self == WriterPlugin.self {
                    return LibsFactory.Configuration.PluginType.writer
                }
                
                return LibsFactory.Configuration.PluginType.reader
            }
        }
        
        static let dynamicLibExtension = "dylib"
        static let pluginsDirName = "plugins"
        
    }
}

// MARK: - Errors
private extension LibsFactory {
    
    enum ReadError: Error, LocalizedError {
        case symbolNotFound(symbolName: String, path: String)
        case dlError(errorString: String, path: String)
        case unknownError(path: String)
        
        var errorDescription: String? {
            switch self {
            case .symbolNotFound(let symbolName, let path):
                return "error loading lib: symbol \(symbolName) not found, path: \(path)"
            case .dlError(let errorString, let path):
                return "error opening lib: \(errorString), path: \(path)"
            case .unknownError(let path):
                return "error opening lib: unknown error, path: \(path)"
            }
        }
    }
    
}
