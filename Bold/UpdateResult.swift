import Foundation

/**
  Represents the result of a executeUpdate(query:(arguments:)) call.
*/
public enum UpdateResult {
  /**
    Used to represent a successful update.
  */
  case success
  
  /**
    Used to represent a failed update.
  */
  case failure(Error)
  
  /**
    Is used to determine if the update query was successful.
  
    :returns: true if the query was successful, otherwise false.
  */
  public var isSuccess:Bool {
    switch self {
      case .success: return true
      case .failure: return false
    }
  }
  /**
    Is used to determine if the update query failed.
  
    :returns: true if the update query failed (then you can be sure that the error is non-nil), otherwise false.
  */
  public var isFailure:Bool {
    return !isSuccess
  }
  
  // TODO: Add convenience error read-only property.
}

