import Foundation
import PluginInterface

typealias InitFunction = @convention(c) () -> UnsafeMutableRawPointer

func plugin(at path: String) -> WriterPlugin {
    let openRes = dlopen(path, RTLD_NOW|RTLD_LOCAL)
    if openRes != nil {
        defer {
            dlclose(openRes)
        }
        
        let symbolName = "writerPlugin"
        let sym = dlsym(openRes, symbolName)
        
        if sym != nil {
            let f: InitFunction = unsafeBitCast(sym, to: InitFunction.self)
            let pluginPointer = f()
            let builder = Unmanaged<PluginBuilder<WriterPlugin>>.fromOpaque(pluginPointer).takeRetainedValue()
            return builder.build()
        }
        else {
            fatalError("error loading lib: symbol \(symbolName) not found, path: \(path)")
        }
    }
    else {
        if let err = dlerror() {
            fatalError("error opening lib: \(String(format: "%s", err)), path: \(path)")
        }
        else {
            fatalError("error opening lib: unknown error, path: \(path)")
        }
    }
}

let myPlugin = plugin(at: "/Users/illia.kniaziev/Desktop/libtest/TestPlugin/.build/x86_64-apple-macosx/debug/libTestPlugin.dylib")
let a = myPlugin.supportedFileType
print(a)

/*
 
 
 import Foundation
 
 guard let plugin = LibsFactory.getWriter(forExtension: "bmp") else {
 print("EXIT")
 exit(0)
 }
 
 print(plugin.supportedFileType, "🟢")
 
 /*
  /Users/illia.kniaziev/Desktop/libtest/TestPlugin/.build/x86_64-apple-macosx/debug/libTestPlugin.dylib
  */
 
 
 */
