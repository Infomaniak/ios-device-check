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

import DeviceCheck

extension DCAppAttestService {
    static let userDefaultsKey = "DeviceCheckKeyId"

    func generateOrGetKey(bypassValidation: Bool) async throws -> String {
        if let savedDeviceKeyId = UserDefaults.standard.string(forKey: DCAppAttestService.userDefaultsKey) {
            return savedDeviceKeyId
        } else {
            return try await generateAndCacheKey(bypassValidation: bypassValidation)
        }
    }

    func generateAndCacheKey(bypassValidation: Bool) async throws -> String {
        guard !bypassValidation else {
            return "test-key-id"
        }

        let keyId = try await generateKey()
        UserDefaults.standard.set(keyId, forKey: DCAppAttestService.userDefaultsKey)
        return keyId
    }

    func attestKey(keyId: String, clientDataHash: Data, bypassValidation: Bool) async throws -> Data {
        guard !bypassValidation else {
            return "test-attestation-data".data(using: .utf8) ?? Data()
        }

        return try await attestKey(keyId, clientDataHash: clientDataHash)
    }
}
