import Foundation
import Tagged

struct NodeDto {
  struct File {
    var atime: Date
    var mtime: Date
    var size: NodeSize
  }

  struct Folder {
    var children: [NodeDto]
  }

  enum Details {
    case file(details: File)
    case folder(details: Folder)
  }

  var id: NodeId
  var name: String
  var details: Details
}

enum NodeIdTag {}
typealias NodeId = Tagged<NodeIdTag, UInt32>

typealias NodeSize = Int

// MARK - Extensions

extension NodeDto {
  static var emptyRootFolder: NodeDto {
    NodeDto(
      id: .rootId,
      name: "",
      details: .folder(details: .init(children: []))
    )
  }
}

extension NodeDto {
  func reduce<Result>(
    into initialResult: Result,
    parentId: NodeId,
    update: (inout Result, NodeDto, NodeId) -> Void
  ) -> Result {
    var result = initialResult
    reduce(into: &result, parentId: parentId, update: update)
    return result
  }

  private func reduce<Result>(
    into result: inout Result,
    parentId: NodeId,
    update: (inout Result, NodeDto, NodeId) -> Void
  ) -> Void {
    update(&result, self, parentId)
    if case let .folder(folder) = details {
      folder.children.forEach { child in
        child.reduce(into: &result, parentId: id, update: update)
      }
    }
  }
}
