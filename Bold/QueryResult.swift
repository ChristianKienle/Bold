import Foundation
/**
  A query result is returned by executeQuery(query:(arguments:)). The result of a query can either be a success (.Success) or a failure (.Failure). If the result is .Success then it has an associated result set (see ResultSet). If the result is .Failure then it has an associcated error (see Error).

  You can use for-in to iterate over the query result:

  let queryResult = db.executeQuery(query)
  for row in queryResult {
    // work with the row
  }

  In the above example row is an instance of Row. If the query result is .Failure the above code is still valid but the code block of the for-in-loop is simply not executed. If the above for-loop iterates over every row in the query result it is closed automatically for you after the last iteration. If you are not using for-in to iterate over the complete result set then you have to close it manually.

  You can use isSuccess and isFailure to find out whether the query contains a result or an error.
*/
public enum QueryResult {
  /**
    Represents a successful query.
  */
  case success(ResultSet)
  
  /**
    Represents a failed query.
  */
  case failure(Error)

  /**
    Is used to determine if the query was successful.
  
    :returns: true if the query was successful (then you can be sure that resultSet is non-nil), otherwise false.
  */
  public var isSuccess:Bool {
    return resultSet != nil
  }
 
  /**
    Is used to determine if the query failed.
  
    :returns: true if the query failed (then you can be sure that the error is non-nil), otherwise false.
  */

  public var isFailure:Bool {
    return !isSuccess
  }
  
  /**
    Is used to determine get to the actual result set (see ResultSet).
  
    :returns: a result set if the query succeeded, otherwise nil.
  */

  public var resultSet:ResultSet? {
    switch self {
      case .success(let result): return result
      case .failure: return nil
    }
  }
  
  /**
    Is used to close the underlying result set. If there is no result set then false is returned. This means that you can safely call this method even if there is no result set.
  
    :returns: true if there was a result set and it has been closed, otherwise false.
  */
  public func closeResultSet() -> Bool {
    if let resultSet = self.resultSet {
      return resultSet.close()
    }
    return false
  }
  
  public typealias Consumer = (_ resultSet: ResultSet) -> (Void)
  public func consumeResultSet(_ consumer: Consumer) {
    guard let resultSet = resultSet else {
      return
    }
    consumer(resultSet)
  }
  
  public func consumeResultSetAndClose(_ consumer: Consumer) {
    consumeResultSet { set in
      consumer(set)
      let _ = set.close()
    }
  }
}

public struct QueryResultGenerator : IteratorProtocol {
  public typealias Element = Row
  let queryResult: QueryResult
  init(queryResult: QueryResult) {
    self.queryResult = queryResult
  }
  public func next() -> Element? {
    guard let resultSet = queryResult.resultSet else {
      return nil
    }
    guard resultSet.next() else {
      let _ = resultSet.close()
      return nil
    }
    return resultSet.row
  }
}

extension QueryResult : Sequence {
  public typealias GeneratorType = QueryResultGenerator

  public func makeIterator() -> GeneratorType {
    return QueryResultGenerator(queryResult:self)
  }
}
