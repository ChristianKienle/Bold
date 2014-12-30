import Foundation

internal enum PreparationResult {
  case Success(statement:Statement)
  case Failure(error:Error)
  
  internal var isSuccess:Bool {
    return statement != nil
  }
  
  internal var isFailure:Bool {
    return !isSuccess
  }
  
  internal var statement:Statement? {
    switch self {
    case .Success(let statement): return statement
    case .Failure: return nil
    }
  }
}
