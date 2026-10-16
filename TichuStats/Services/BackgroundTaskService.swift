//
//  BackgroundTaskService.swift
//  TichuStats
//
//  Created by Leon on 13.10.2026.
//



import BackgroundTasks
import SwiftUI

@MainActor
final class ExportCoordinator {
    @AppStorage("userName") var userName: String = "Storage - Unknown"
    static let shared = ExportCoordinator()
    static let taskID = "com.Drakynem.Tichu.Export"

    struct Job {
        let userId: Int
        let folderURL: URL
        let exportProfile: Bool
        let exportSettings: Bool
        let exportFriends: Bool
        let exportGames: Bool
        let exportEloHistory: Bool
        let exportStatsHistory: Bool
        let fullStatsHistory: Bool
    }
    private var pendingJob: Job?
    private let network = NetworkService.shared

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskID, using: nil) { [weak self] task in
            guard let task = task as? BGContinuedProcessingTask else { return }
            Task { @MainActor in await self?.run(task) }
        }
    }

    func submit(_ job: Job) throws {
        pendingJob = job
        let request = BGContinuedProcessingTaskRequest(
            identifier: Self.taskID,
            title: String(localized:"export.task.title"),
            subtitle: String(localized:"export.task.subtitle")
        )
        request.strategy = .fail
        do { try BGTaskScheduler.shared.submit(request) }
        catch { pendingJob = nil; throw error }
    }

    private func run(_ task: BGContinuedProcessingTask) async {
        defer { pendingJob = nil }
        guard let job = pendingJob else { task.setTaskCompleted(success: false); return }

        let accessing = job.folderURL.startAccessingSecurityScopedResource()
        defer { if accessing { job.folderURL.stopAccessingSecurityScopedResource() } }

        task.progress.totalUnitCount = 100
        let network = self.network
        
        let safeName = userName
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: "-")
        
        let fileName = String(format:String(localized:"export.fileName"),safeName,Int(Date().timeIntervalSince1970))
        
        let work = Task.detached {
            let download = Progress(totalUnitCount: 100)
            task.progress.addChild(download, withPendingUnitCount: 90)
            let data = try await network.fetchExportData(profileId: job.userId,exportProfile:job.exportProfile,exportSettings: job.exportSettings,exportFriends:job.exportFriends,exportGames: job.exportGames,exportEloHistory: job.exportEloHistory,exportStatsHistory: job.exportStatsHistory,fullStatsHistory: job.fullStatsHistory, progress: download)
            let name = fileName
            let fileURL = job.folderURL.appendingPathComponent(name).appendingPathExtension("json")
            try data.write(to: fileURL, options: .atomic)
            task.progress.completedUnitCount = 100
        }
        task.expirationHandler = { work.cancel() }

        do {
            try await work.value
            task.updateTitle(String(localized:"export.task.title.finished"), subtitle: String(format:String(localized:"export.task.subtitle.saved"),fileName))
            task.setTaskCompleted(success: true)
        } catch {
            task.updateTitle(String(localized:"export.task.failed"), subtitle: error.localizedDescription)
            task.setTaskCompleted(success: false)
        }
    }
}

final class ExportDownloader: NSObject, URLSessionDownloadDelegate {
    private let progress: Progress?
    private var session: URLSession?
    private var continuation: CheckedContinuation<URL, Error>?
    private var movedURL: URL?
    private var failure: Error?

    init(progress: Progress?) {
        self.progress = progress
    }

    func download(_ request: URLRequest) async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                self.continuation = cont
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                self.session = session
                session.downloadTask(with: request).resume()
            }
        } onCancel: {
            self.session?.invalidateAndCancel()
        }
    }

    // Progress
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let progress, totalBytesExpectedToWrite > 0 else { return }
        progress.totalUnitCount = totalBytesExpectedToWrite
        progress.completedUnitCount = totalBytesWritten
    }

    // The temp file is deleted when this returns, so move it right away
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let http = downloadTask.response as? HTTPURLResponse else {
            failure = URLError(.badServerResponse)
            return
        }
        guard http.statusCode == 200 else {
            failure = URLError(.badServerResponse, userInfo: [
                NSLocalizedDescriptionKey: "Export failed (HTTP \(http.statusCode))"
            ])
            return
        }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            movedURL = dest
        } catch {
            failure = error
        }
    }

    // Always called last; resume the continuation exactly once here
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.finishTasksAndInvalidate()   // breaks the session -> delegate retain cycle
        if let error = error ?? failure {
            continuation?.resume(throwing: error)
        } else if let movedURL {
            if let progress { progress.completedUnitCount = progress.totalUnitCount }
            continuation?.resume(returning: movedURL)
        } else {
            continuation?.resume(throwing: URLError(.unknown))
        }
        continuation = nil
    }
}
