import Foundation
import Network
import os.log
import CommonCrypto

#if os(macOS)
import Cocoa

typealias UIImage = NSImage
typealias UIFont = NSFont
typealias UIColor = NSColor
typealias UIImageView = NSImageView
typealias UIViewController = NSViewController

internal class UIControl {
    enum State {
        case normal
    }
}

extension NSButton  {
    func setTitle(_ title: String, for state: UIControl.State) {
        self.title = title
    }
    func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
    }
}

extension NSViewController  {
//    @objc func viewWillAppear() {
//        viewWillAppear(false)
//    }
//    @objc func viewDidAppear() {
//        viewDidAppear(false)
//    }
//    @objc func viewWillDisappear() {
//        viewWillAppear(false)
//    }
//    @objc func viewDidDisappear() {
//        viewDidAppear(false)
//    }

    @objc func viewWillAppear(_ animated: Bool) {
    }
    @objc func viewDidAppear(_ animated: Bool) {
    }
    @objc func viewWillDisappear(_ animated: Bool) {
    }
    @objc func viewDidDisappear(_ animated: Bool) {
    }

    @objc func didReceiveMemoryWarning() {
    }
}

extension NSTextView  {
    public var text : String {
        get {
            return string;
        }
        set {
            string = newValue
        }
    }
}

class UIStoryboard : NSStoryboard {
}

class UIAlertController: NSAlert {
}


public class NSStringDrawingOptions  {
    static var usesLineFragmentOrigin : NSString.DrawingOptions {
        get {
            return NSString.DrawingOptions.usesLineFragmentOrigin
        }
    }
}

#else
import UIKit

class NSViewController : UIViewController {

}
#endif //os(macOS)

extension NSAttributedString {
    func heightWithConstrainedWidth(_ width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }

    func widthWithConstrainedHeight(_ height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.width)
    }
}

extension String {
    func toBCD(nBytes: Int) -> [UInt8]? {
        var r = [UInt8]()
        let str = self.padding(toLength: nBytes * 2, withPad: "0", startingAt: 0)

        for i in 0..<nBytes {
            let a = str[i * 2 + 0]
            let b = str[i * 2 + 1]
            if !a.isNumber || !b.isNumber {
                return nil
            }
            let ai = a.wholeNumberValue! << 4
            let bi = b.wholeNumberValue!
            r.append(UInt8(ai + bi))
        }

        return r
    }

    func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.height
    }

    func widthWithConstrainedHeight(_ height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.width
    }

    // MARK: - sub String
    func substringToIndex(_ index:Int) -> String {
        let start = self.index(startIndex, offsetBy: index)
        return String(self[..<start])
    }
    func substringFromIndex(_ index:Int) -> String {
        let start = self.index(startIndex, offsetBy: index)
        return String(self[start...])
    }
    func substringWithRange(_ range:Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[start...end])
    }
    
    subscript(index:Int) -> Character{
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    subscript(range:Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
    
    
    // MARK: - replace
    func replaceCharactersInRange(_ range:Range<Int>, withString: String!) -> String {
        let result:NSMutableString = NSMutableString(string: self)
        result.replaceCharacters(in: NSRange(range), with: withString)
        return result as String
    }
    
    func masked (_ start: Int, end: Int) -> String {
        let len = self.count
        var s = self.substringToIndex(start)
        for _ in 1...(len-(start+end)) {
            s += "*"
        }
        s += self.substringFromIndex(len-end)
        
        return s
    }

    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.

    var dataFromHexadecimalString: Data? {
        var data = Data(capacity: self.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        return data
    }

    var hexIntValue: UInt64 {
        guard let data = self.dataFromHexadecimalString else { return 0 }

        var r: UInt64 = 0
        for b in data {
            r <<= 8
            r |= UInt64(b)
        }

        return r
    }

    var intValue: Int! {
        return Int(self) ?? 0
    }

    var int32Value: Int32! {
        return Int32(self) ?? 0
    }

    var uint32Value: UInt32! {
        return UInt32(self) ?? 0
    }

    var uint64Value: UInt64! {
        return UInt64(self) ?? 0
    }
}

extension Date {
    var year: Int {
        return NSCalendar.current.component(.year, from: self)
    }
    var month: Int {
        return NSCalendar.current.component(.month, from: self)
    }
    var day: Int {
        return NSCalendar.current.component(.day, from: self)
    }
    var hour: Int {
        return NSCalendar.current.component(.hour, from: self)
    }
    var minute: Int {
        return NSCalendar.current.component(.minute, from: self)
    }
    var second: Int {
        return NSCalendar.current.component(.second, from: self)
    }

    public static func fromFormat(format: String, data: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current

        let date = dateFormatter.date(from: data)
        return date
    }

    public func toString(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = format

        return dateFormatter.string(from: self)
    }

    public func toString(_ dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, relativeDate: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        dateFormatter.doesRelativeDateFormatting = relativeDate
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current

        return dateFormatter.string(from: self)
    }

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}


extension Data {
    var hexString: String {
        return map { String(format: "%02X", $0) }
            .joined(separator: "")
    }

    var bytes: [UInt8] { return [UInt8](self) }

    var sha1: Data {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(self.count), &digest)
        }
        return Data(digest)
    }
    var sha256: Data {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &digest)
        }
        return Data(digest)
    }
}


extension NSData {
    var hexString: String { return (self as Data).hexString }

    var bytes: [UInt8] { return [UInt8](self) }
}


extension Sequence where Iterator.Element == UInt8 {
    func someMessage(){
        print("UInt8 Array")
    }
}

extension Array where Element == UInt8 {
    func getNumberBE(start: Int, length: Int) -> UInt64 {
        var r: UInt64 = 0

        for val in self[start..<(start+length)] {
            r <<= 8
            r |= UInt64(val)
        }
        return r
    }

    func getU64(start: Int) -> UInt64 {
        return getNumberBE(start: start, length: 8)
    }

    func getU32(start: Int) -> UInt32 {
        return UInt32(getNumberBE(start: start, length: 4))
    }

    func getU16(start: Int) -> UInt16 {
        return UInt16(getNumberBE(start: start, length: 2))
    }

    func getInt32(start: Int) -> Int {
        return Int(getU32(start: start))
    }

    func getInt16(start: Int) -> Int {
        return Int(getU16(start: start))
    }
}
extension Array {
    func subArray(_ start: Int, len: Int = -1) -> [Element] {
        var l = len
        if l < 0 {
            l = self.count - start
        }
        return [Element](self[start..<(start + l)])
    }

    var hexString: String {
        let string = NSMutableString(capacity: count * 2)
        
        if self.first is UInt8 {
            let byteArray = self.map { $0 as! UInt8 }
            for i in 0 ..< count {
                string.appendFormat("%02X", byteArray[i])
            }
        }
        return string as String
    }
}

extension Float {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

extension Int {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)d" as NSString, self) as String
    }

    func bytesBE(_ length: Int) -> [UInt8] {
        let t = UInt64(self)
        var b = [UInt8](repeating: 0x00, count: length)
        for i in 0..<length {
            b[length - i - 1] = UInt8( (Int(t) >> (i * 8)) & 0xFF);
        }
        return b
    }
    func bytesLE(_ length: Int) -> [UInt8] {
        let t = UInt64(self)
        var b = [UInt8](repeating: 0x00, count: length)
        for i in 0..<length {
            b[i] = UInt8( (Int(t) >> (i * 8)) & 0xFF);
        }
        return b
    }
}

extension String {
    func stringByAppendingPathComponent(_ path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
}

#if os(macOS)
extension NSViewController {
    static var alert: UIAlertController? = nil

    func showMessage(_ title: String, message: String)
    {
        DispatchQueue.main.async {
            if NSViewController.alert != nil {
                //UIViewController?.dismiss(animated: false, completion: nil)
                NSViewController.alert = nil
            }

            let alert = NSAlert.init()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func showError(_ operation: String, error: NSError?)
    {
        if (error != nil)
        {
            showMessage("Error", message: "\(operation) failed with error: \(error!.localizedDescription)!")
        }else
        {
            showMessage("Error", message: "\(operation) failed!")
        }
    }

    class func instantiateFromStoryboard(_ name: String = "Main") -> Self {
        return instantiateFromStoryboardHelper(name)
    }

    fileprivate class func instantiateFromStoryboardHelper<T>(_ name: String) -> T {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let identifier = String(describing: self)
        #if os(macOS)
        let controller = storyboard.instantiateController(withIdentifier: identifier) as! T
        #else //os(macOS)
        let controller = storyboard.instantiateViewController(withIdentifier: identifier) as! T
        #endif //os(macOS)
        return controller
    }
}
#else //os(macOS)
import UIKit

extension UIViewController {
    static var alert: UIAlertController? = nil

    func showMessage(_ title: String, message: String)
    {
        DispatchQueue.main.async {
            if UIViewController.alert != nil {
                UIViewController.alert?.dismiss(animated: false, completion: nil)
                UIViewController.alert = nil
            }

            UIViewController.alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                (result : UIAlertAction) -> Void in
                
            }

            UIViewController.alert!.addAction(okAction)
            self.present(UIViewController.alert!, animated: true, completion: nil)
        }
    }

    func showError(_ operation: String, error: NSError?)
    {
        if (error != nil)
        {
            showMessage("Error", message: "\(operation) failed with error: \(error!.localizedDescription)!")
        }else
        {
            showMessage("Error", message: "\(operation) failed!")
        }
    }

    class func instantiateFromStoryboard(_ name: String = "Main") -> Self {
        return instantiateFromStoryboardHelper(name)
    }

    fileprivate class func instantiateFromStoryboardHelper<T>(_ name: String) -> T {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let identifier = String(describing: self)
        #if os(macOS)
        let controller = storyboard.instantiateController(withIdentifier: identifier) as! T
        #else //os(macOS)
        let controller = storyboard.instantiateViewController(withIdentifier: identifier) as! T
        #endif //os(macOS)
        return controller
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension UIImage {
    static func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0);
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();

        context?.setFillColor(color.cgColor);
        context?.fill(rect);

        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image!;
    }
}

extension UIStoryboard {
    func instantiateVC<T: UIViewController>() -> T? {
        // get a class name and demangle for classes in Swift
        if let name = NSStringFromClass(T.self).components(separatedBy: ".").last {
            return instantiateViewController(withIdentifier: name) as? T
        }
        return nil
    }
}
#endif //os(macOS)

internal class Utils: NSObject {
    
}


internal struct Log {
    enum LogLevel: String {
        case error = "⛔️"
        case warning = "⚠️"
        case debug = "💬"
    }
    enum LogDirection: String {
        case send = "▶️"
        case receive = "◀️"
    }

    static func debug(_ info: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log("%@ %@", type: .default, level.rawValue, info)
//        os_log("%@ %@:%d %@: %@", type: .default, level.rawValue, (file as NSString).lastPathComponent, line, function, info)
        #endif
    }

    static func debugData(title: String, bytes: [UInt8]?, direction: LogDirection) {
        #if DEBUG
        os_log("%@ %@(%d): %@", type: .default, direction.rawValue, title, bytes?.count ?? 0, bytes?.hexString ?? "")
        #endif
    }

    static func debugData(title: String, data: Data?, direction: LogDirection) {
        #if DEBUG
        os_log("%@ %@(%d): %@", type: .default, direction.rawValue, title, data?.count ?? 0, data?.hexString ?? "")
        #endif
    }

    static func warning(_ info: String, level: LogLevel = .warning, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log("%@ %@:%d %@: %@", type: .default, level.rawValue, (file as NSString).lastPathComponent, line, function, info)
        #endif
    }

    static func error(_ errorMessage: String, level: LogLevel = .error, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log("%@ %@", type: .default, level.rawValue, errorMessage)
//        os_log("%@ %@:%d %@: %@", type: .default, level.rawValue, (file as NSString).lastPathComponent, line, function, "\(error)")
        #endif
    }


    static func error(title: String, error: NSError?, level: LogLevel = .error, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log("%@ %@ failed with: %@", type: .default, level.rawValue, title, "\(error?.localizedDescription ?? "")")
        #endif
    }

    static func error(title: String, error: Error?, level: LogLevel = .error, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log("%@ %@ failed with: %@", type: .default, level.rawValue, title, "\(error?.localizedDescription ?? "")")
        #endif
    }

    static func error(title: String, error: NWError?, level: LogLevel = .error, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log("%@ %@ failed with: %@", type: .default, level.rawValue, title, "\(error?.localizedDescription ?? "")")
        #endif
    }

}
