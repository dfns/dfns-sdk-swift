/**
    Utils to manipulate base64Url string
 */
public enum Utils {
    public static func base64URLUnescaped(_ base: String) -> String {
        let replaced = base.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padding = replaced.count % 4
        if padding > 0 {
            return replaced + String(repeating: "=", count: 4 - padding)
        } else {
            return replaced
        }
    }

    public static func base64URLEscape(_ base: String) -> String {
        return base.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
