import Foundation

internal enum PreparationResult {
  case success(statement: Statement)
  case failure(error: Error)
  internal var statement: Statement? {
    switch self {
    case .success(let statement): return statement
    case .failure: return nil
    }
  }
}
