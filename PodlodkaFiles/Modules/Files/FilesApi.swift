import Combine
import Foundation

enum FilesApi {
  enum LoadError: Error {
    case authError
  }

  static func loadFiles(accessToken: AuthToken) -> Future<NodeDto, Error> {
    Future { resolve in
      DispatchQueue.global().async {
        resolve(.success(.mockRootNode))
      }
    }
  }
}

private extension NodeDto {
  static var mockRootNode: NodeDto {
    NodeDto(id: .rootId, name: "", details: .folder(details: .init(children: [
      NodeDto(id: 2, name: "ticket.pdf", details: .mockFileDetails),
      NodeDto(id: 3, name: "report.docx", details: .mockFileDetails),
      NodeDto(id: 4, name: "Private", details: .folder(details: .init(children: [
        NodeDto(id: 5, name: "books", details: .folder(details: .init(children: [
          NodeDto(id: 6, name: "Optimizing-Collections-Nov-2017.epub", details: .mockFileDetails),
          NodeDto(id: 7, name: "SwiftUI_by_Tutorials_v2.0.0.epub", details: .mockFileDetails),
          NodeDto(id: 8, name: "Flight School Guide to Swift Codable.pdf", details: .mockFileDetails),
        ]))),
        NodeDto(id: 9, name: "docs", details: .folder(details: .init(children: [
          NodeDto(id: 10, name: "Страховой полис.pdf", details: .mockFileDetails),
          NodeDto(id: 11, name: "Свидетельство о собственности.pdf", details: .mockFileDetails),
          NodeDto(id: 12, name: "Международный полис.pdf", details: .mockFileDetails),
        ]))),
        NodeDto(id: 13, name: "work", details: .folder(details: .init(children: [
          NodeDto(id: 14, name: "Report-2020-Q4.pptx", details: .mockFileDetails),
          NodeDto(id: 15, name: "Report-2020-Q3.pptx", details: .mockFileDetails),
          NodeDto(id: 16, name: "Report-2020-Q2.pptx", details: .mockFileDetails),
          NodeDto(id: 17, name: "Report-2020-Q1.pptx", details: .mockFileDetails),
        ]))),
      ]))),
      NodeDto(id: 18, name: "Camera Uploads", details: .folder(details: .init(children: [
        NodeDto(id: 19, name: "IMG_0001.HEIC", details: .mockFileDetails),
        NodeDto(id: 20, name: "IMG_0002.HEIC", details: .mockFileDetails),
        NodeDto(id: 21, name: "IMG_0003.HEIC", details: .mockFileDetails),
        NodeDto(id: 22, name: "IMG_0004.HEIC", details: .mockFileDetails),
      ]))),
    ])))
  }
}

extension NodeDto.Details {
  static let mockFileDetails =
    NodeDto.Details.file(details: .init(atime: Date(), mtime: Date(), size: 123))
}
