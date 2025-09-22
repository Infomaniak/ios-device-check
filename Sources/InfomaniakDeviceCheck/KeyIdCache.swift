//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

import Foundation
import OSLog

struct KeyIdCache {
    private enum DomainError: Error {
        case cannotAccessCachesDirectory
    }

    init() {}

    func getKeyId() -> String? {
        guard let keyIdPath = try? getKeyIdURL(),
              let keyIdData = try? Data(contentsOf: keyIdPath),
              let keyId = String(data: keyIdData, encoding: .utf8) else {
            return nil
        }

        return keyId
    }

    func setKeyId(_ keyId: String) {
        do {
            var keyIdURL = try getKeyIdURL()

            let keyIdParentURL = keyIdURL.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: keyIdParentURL.path) {
                try FileManager.default.createDirectory(at: keyIdParentURL, withIntermediateDirectories: true)
            }

            if FileManager.default.fileExists(atPath: keyIdURL.path) {
                try? FileManager.default.removeItem(at: keyIdURL)
            }

            guard let keyIdData = keyId.data(using: .utf8) else { return }
            try keyIdData.write(to: keyIdURL)

            var metadata = URLResourceValues()
            metadata.isExcludedFromBackup = true
            try keyIdURL.setResourceValues(metadata)
        } catch {
            Logger(subsystem: "com.infomaniak.devicecheck", category: "KeyIdCache")
                .error("Cannot save key id to cache: \(error)")
        }
    }

    private func getKeyIdURL() throws -> URL {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw DomainError.cannotAccessCachesDirectory
        }
        let keyIdURL = cachesDirectory
            .appendingPathComponent("DeviceCheck")
            .appendingPathComponent("key_id")

        return keyIdURL
    }
}
