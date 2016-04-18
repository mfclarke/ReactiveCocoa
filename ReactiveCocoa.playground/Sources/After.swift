import Foundation

public func executeAfter(seconds time: NSTimeInterval, block: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), block)
}
