import AppKit
import SwiftUI

struct ContentView: View {

  @State private var selectedFolderURL: URL?
  @State private var allFiles: [URL] = []
  @State private var uniqueExtensions: Set<String> = []
  @State private var selectedExtensions: Set<String> = []
  @State private var selectedFiles: Set<URL> = Set()
  @State private var combinedText: String = ""

  @State var showRoadmap = false

  var body: some View {
    NavigationSplitView {
      // Sidebar with proper styling
      VStack(alignment: .leading, spacing: 0) {
        if allFiles.isEmpty {
          VStack {
            Spacer()
            Button(action: {
              let openPanel = NSOpenPanel()
              openPanel.canChooseFiles = false
              openPanel.canChooseDirectories = true
              openPanel.allowsMultipleSelection = false
              openPanel.begin { response in
                if response == .OK {
                  selectedFolderURL = openPanel.urls.first
                  if let folderURL = selectedFolderURL {
                    let result = findFiles(in: folderURL)
                    allFiles = result.files
                    uniqueExtensions = result.extensions
                    // Initially select all extensions
                    selectedExtensions = uniqueExtensions
                    // Update selected files based on initial filter
                    updateSelectedFilesBasedOnFilter()
                  }
                }
              }
            }) {
              VStack(spacing: 12) {
                Image(systemName: "folder.badge.plus")
                  .font(.system(size: 36))
                Text("Select Folder")
                  .font(.headline)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            Spacer()
          }
        } else {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Filter by Extension")
                .font(.headline)
              Spacer()
              Button(action: {
                // Reset folder selection
                selectedFolderURL = nil
                allFiles = []
                uniqueExtensions = []
                selectedExtensions = []
                selectedFiles = []
                combinedText = ""
              }) {
                Image(systemName: "arrow.left")
                  .font(.system(size: 12, weight: .semibold))
              }
              .buttonStyle(.borderless)
              .help("Select a different folder")
            }
            .padding(.horizontal)
            .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(uniqueExtensions.sorted(), id: \.self) { ext in
                  Button(action: {
                    if selectedExtensions.contains(ext) {
                      selectedExtensions.remove(ext)
                    } else {
                      selectedExtensions.insert(ext)
                    }
                    updateSelectedFilesBasedOnFilter()
                  }) {
                    Text(ext.isEmpty ? "(none)" : ext)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 4)
                      .background(
                        selectedExtensions.contains(ext)
                          ? Color.accentColor : Color(NSColor.controlBackgroundColor)
                      )
                      .cornerRadius(6)
                      .foregroundColor(selectedExtensions.contains(ext) ? .white : .primary)
                  }
                  .buttonStyle(.plain)
                }
              }
              .padding(.horizontal)
            }
            .frame(height: 34)

            Divider()
              .padding(.vertical, 8)

            Text("Files")
              .font(.headline)
              .padding(.horizontal)

            List {
              ForEach(filteredFiles, id: \.self) { file in
                HStack {
                  Toggle(
                    isOn: Binding(
                      get: { selectedFiles.contains(file) },
                      set: { isOn in
                        if isOn {
                          selectedFiles.insert(file)
                        } else {
                          selectedFiles.remove(file)
                        }
                        updateCombinedText()
                      }
                    )
                  ) {
                    HStack {
                      fileIcon(for: file.pathExtension)
                      Text(file.lastPathComponent)
                        .truncationMode(.middle)
                    }
                  }
                }
              }
            }
            .listStyle(.sidebar)
          }
        }
      }
      .frame(minWidth: 220, idealWidth: 250)
    } detail: {
      // Main content
      VStack {
        // Display concatenated string
        TextEditor(text: $combinedText)
          .font(.system(.body, design: .monospaced))
          .disabled(combinedText.isEmpty)
      }
      .padding()
      .frame(minWidth: 400, minHeight: 300)
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          Text("\(combinedText.count) characters")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(combinedText, forType: .string)
          } label: {
            Image(systemName: "doc.on.doc")
          }
          .help("Copy to Clipboard")
          .keyboardShortcut("C", modifiers: [.command, .shift])
          .disabled(combinedText.isEmpty)
        }
      }
    }
    .sheet(
      isPresented: $showRoadmap,
      content: {
        Roadmap()
      })
  }

  @ViewBuilder
  func fileIcon(for extension: String) -> some View {
    let fileExtension = `extension`.lowercased()

    if fileExtension == "swift" {
      Image(systemName: "swift")
        .foregroundColor(.orange)
    } else if ["jpg", "jpeg", "png", "gif", "heic"].contains(fileExtension) {
      Image(systemName: "photo")
        .foregroundColor(.blue)
    } else if ["mp4", "mov", "avi"].contains(fileExtension) {
      Image(systemName: "film")
        .foregroundColor(.purple)
    } else if ["pdf"].contains(fileExtension) {
      Image(systemName: "doc.richtext")
        .foregroundColor(.red)
    } else if ["md", "txt"].contains(fileExtension) {
      Image(systemName: "doc.text")
        .foregroundColor(.gray)
    } else if ["html", "css", "js"].contains(fileExtension) {
      Image(systemName: "globe")
        .foregroundColor(.green)
    } else {
      Image(systemName: "doc")
        .foregroundColor(.gray)
    }
  }

  func animate() {
    for i in 0...4 {
      DispatchQueue.main.asyncAfter(deadline: .now() + (Double(Double(i) * 0.2))) {
        NSApplication.shared.dockTile.contentView = NSImageView(image: NSImage(named: "an\(i)")!)
        NSApplication.shared.dockTile.display()
      }
    }
  }

  private func updateSelectedFilesBasedOnFilter() {
    let filtered = filteredFiles
    // Keep only selected files that are still present in the filtered list
    selectedFiles = selectedFiles.filter { filtered.contains($0) }
    // Select all files that match the current filter by default
    selectedFiles = Set(filtered)
    updateCombinedText()
  }

  var filteredFiles: [URL] {
    if selectedExtensions.isEmpty {
      return []  // Or return allFiles if you prefer that behavior when no extensions are selected
    }
    return allFiles.filter { fileURL in
      let fileExtension = fileURL.pathExtension.lowercased()
      return selectedExtensions.contains(fileExtension)
        || (fileExtension.isEmpty && selectedExtensions.contains(""))  // Handle files with no extension
    }
  }

  private func updateCombinedText() {
    combinedText = selectedFiles.compactMap { try? String(contentsOf: $0) }.joined(
      separator: "\n\n")
  }

  func findFiles(in folderURL: URL) -> (files: [URL], extensions: Set<String>) {
    var foundFiles: [URL] = []
    var foundExtensions: Set<String> = Set()
    let fileManager = FileManager.default
    guard
      let enumerator = fileManager.enumerator(
        at: folderURL, includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants])
    else {
      return ([], [])
    }

    for case let fileURL as URL in enumerator {
      do {
        let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
        if resourceValues.isRegularFile == true {
          foundFiles.append(fileURL)
          foundExtensions.insert(fileURL.pathExtension.lowercased())
        }
      } catch {
        print("Error getting resource values for \(fileURL): \(error)")
      }
    }

    return (files: foundFiles, extensions: foundExtensions)
  }
}
