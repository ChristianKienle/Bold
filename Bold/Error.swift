import Foundation

public struct Error {
  public enum Code : Int {
    case prepareFailed
    case bindFailed
    case executeQueryFailed // Used when executeUpdate failed because executeQuery failed.
    case stepFailed
  }
  public let code:Error.Code
  public let message:String
  public var SQLiteErrorCode:Int32? = nil
  init(code:Error.Code, message:String, SQLiteErrorCode:Int32? = nil) {
    self.code = code
    self.message = message
    self.SQLiteErrorCode = SQLiteErrorCode
  }
}
