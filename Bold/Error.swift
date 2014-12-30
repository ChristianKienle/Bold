import Foundation

public struct Error {
  public enum Code : Int {
    case PrepareFailed
    case BindFailed
    case ExecuteQueryFailed // Used when executeUpdate failed because executeQuery failed.
    case StepFailed
  }
  let code:Error.Code
  let message:String
  let SQLiteErrorCode:Int32? = nil
  init(code:Error.Code, message:String, SQLiteErrorCode:Int32? = nil) {
    self.code = code
    self.message = message
    self.SQLiteErrorCode = SQLiteErrorCode
  }
}
