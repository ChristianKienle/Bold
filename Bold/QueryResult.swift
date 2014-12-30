import Foundation
/**
  A query result is returned by executeQuery(query:(arguments:)). The result of a query can either be a success (.Success) or a failure (.Failure). If the result is .Success then it has an associated result set (see ResultSet). If the result is .Failure then it has an associcated error (see Error).

  You can use for-in to iterate over the query result:

  let queryResult = db.executeQuery(query)
  for row in queryResult {
    // work with the row
  }

  In the above example row is an instance of Row. If the query result is .Failure the above code is still valid but the code block of the for-in-loop is simply not executed.

  You can use isSuccess and isFailure to find out whether the query contains a result or an error.
*/
public enum QueryResult {
  /**
    Represents a successful query.
  */
  case Success(ResultSet)
  
  /**
    Represents a failed query.
  */
  case Failure(Error)

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
      case .Success(let result): return result
      case .Failure: return nil
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
  
  // TODO: Remove the following methods.
  public func consume(consumer:(row:Row) -> Void) {
    if let resultSet = self.resultSet {
      while resultSet.next() {
        let row = resultSet.row
        consumer(row:row)
      }
    }
    closeResultSet()
  }
  
  public func consumeResultSet(consumer: (resultSet:ResultSet) -> Void) {
    if let resultSet = self.resultSet {
      consumer(resultSet: resultSet)
    }
  }
  
  public func consumeResultSetAndClose(consumer: (resultSet:ResultSet) -> Void) {
    consumeResultSet { set in
      consumer(resultSet:set)
      set.close()
    }
  }
}

public struct QueryResultGenerator : GeneratorType {
  public typealias Element = Row
  let queryResult:QueryResult
  init(queryResult:QueryResult) {
    self.queryResult = queryResult
  }
  public func next() -> Element? {
    if queryResult.isFailure {
      return nil
    }
    if let resultSet = queryResult.resultSet {
      let hadNext = resultSet.next()
      if !hadNext {
        return nil
      }
      return resultSet.row
    }
    return nil
  }
}

extension QueryResult : SequenceType {
  public typealias GeneratorType = QueryResultGenerator

  public func generate() -> GeneratorType {
    return QueryResultGenerator(queryResult:self)
  }
}
