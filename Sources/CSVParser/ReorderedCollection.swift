public struct ReorderedCollection<C>: RandomAccessCollection where C: RandomAccessCollection, C.Index == Int {
    @inlinable
    public init(_ baseCollection: C, order: [Int]) {
        precondition(baseCollection.count == order.count, "Collection count must be the same as orderer")
        self.baseCollection = baseCollection
        self.order = order
    }
    
    public var startIndex: C.Index {
        baseCollection.startIndex
    }
    
    public var endIndex: C.Index {
        baseCollection.endIndex
    }
    
    public subscript(index: Int) -> C.Element {
        return baseCollection[order[index]]
    }
    
    @usableFromInline
    let baseCollection: C
    
    @usableFromInline
    let order: [Int]
    
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    public func index(before i: Int) -> Int {
        i - 1
    }
    
}
