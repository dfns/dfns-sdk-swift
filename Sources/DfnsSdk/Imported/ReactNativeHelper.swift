/**
 Helper file to declare types and class used in React Native
 */

import Foundation

typealias RCTPromiseResolveBlock = (NSDictionary) -> Void
typealias RCTPromiseRejectBlock = (String?, String?, String?) -> Void

enum RCTConvert {
    static func nsData(_ string: String) -> Data {
        return string.data(using: .utf8)!
    }
}
