import Foundation

public struct SQLValue {
  private let value: Bindable?
  init(_ value: Bindable?) {
    self.value = value
  }
  public var string: String? { return get() }
  public var int: Int? { return get() }
  public var double: Double? { return get() }
  public var data: Data? { return get() }
  public var bool: Bool? { return get() }
  
  public func get<T>() -> T? {
    return value as? T
  }
}
