import Foundation

protocol FileDetails {
  var atime: Date { get }
  var mtime: Date { get }
  var size: NodeSize { get }
}

protocol FolderDetails {
  var id: NodeId { get }
  var children: [Node] { get }
}

enum NodeDetails {
  case file(details: FileDetails)
  case folder(details: FolderDetails)
}

protocol Node {
  var id: NodeId { get }
  var name: String { get }
  var isFavorite: Bool { get }
  var details: NodeDetails { get }
}
