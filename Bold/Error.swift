import Foundation

public struct Error {
  public enum Code : Int {
    case prepareFailed
    case bindFailed
    case executeQueryFailed // Used when executeUpdate failed because executeQuery failed.
    case stepFailed
  }
  let code:Error.Code
  let message:String
  var SQLiteErrorCode:Int32? = nil
  init(code:Error.Code, message:String, SQLiteErrorCode:Int32? = nil) {
    self.code = code
    self.message = message
    self.SQLiteErrorCode = SQLiteErrorCode
  }
}
