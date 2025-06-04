import Foundation

public class Logger {
    public static func debugLog(_ message: String) {
//        #if DEBUG
        print(message)
//        #endif
    }
} 
