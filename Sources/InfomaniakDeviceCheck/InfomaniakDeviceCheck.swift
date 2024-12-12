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

import CryptoKit
import DeviceCheck

struct ValidApiResponse<T: Codable>: Codable {
    let data: T
}

public struct InfomaniakDeviceCheck: Sendable {
    public static let tokenHeaderField = "Ik-mobile-token"

    private let baseURL: URL
    private let environment: Environment

    enum ErrorDomain: Error {
        case notSupported
        case cannotConvertChallengeToData
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    public enum Environment: Sendable {
        case prod
        case preprod
    }

    public init(
        apiURL: URL = URL(string: "https://api.infomaniak.com/1/attest")!,
        environment: Environment = .prod
    ) {
        baseURL = apiURL
        self.environment = environment
    }

    /// Generate a token to access a protected API route
    /// - Parameters:
    ///   - targetUrl: The protected API URL
    ///   - bundleId: BundleId of the calling app
    ///   - bypassValidation: Skip attestation generation and validation. Only working in preprod.
    /// - Returns: A token passed in the headers. Use `InfomaniakDeviceCheck.tokenHeaderField` for the name
    public func generateAttestationFor(targetUrl: URL,
                                       bundleId: String,
                                       bypassValidation: Bool = false) async throws -> String {
        let service = DCAppAttestService.shared

        guard service.isSupported || bypassValidation else {
            throw ErrorDomain.notSupported
        }

        let verificationChallengeId = UUID().uuidString

        let keyId = try await service.generateKey(bypassValidation: bypassValidation)

        let serverChallenge = try await serverChallenge(verificationChallengeId: verificationChallengeId)

        guard let serverChallengeData = serverChallenge.data(using: .utf8) else {
            throw ErrorDomain.cannotConvertChallengeToData
        }

        let clientDataHash = Data(SHA256.hash(data: serverChallengeData))

        let attestationData = try await service.attestKey(
            keyId: keyId,
            clientDataHash: clientDataHash,
            bypassValidation: bypassValidation
        )

        let authentificationToken = try await attestToken(
            targetUrl: targetUrl.absoluteString,
            bundleId: bundleId,
            keyId: keyId,
            challengeId: verificationChallengeId,
            attestation: attestationData.base64EncodedString(),
            bypassValidation: bypassValidation
        )

        return authentificationToken
    }

    func serverChallenge(verificationChallengeId: String) async throws -> String {
        let request = try makeRequest(
            method: .post,
            path: "/challenge",
            parameters: ["challenge_id": verificationChallengeId]
        )

        let serverChallenge: ValidApiResponse<String> = try await performRequest(request)

        return serverChallenge.data
    }

    func attestToken(targetUrl: String,
                     bundleId: String,
                     keyId: String,
                     challengeId: String,
                     attestation: String,
                     bypassValidation: Bool) async throws -> String {
        var parameters = [
            "target_url": targetUrl,
            "bundle_id": bundleId,
            "key_id": keyId,
            "challenge_id": challengeId,
            "attestation": attestation
        ]

        if environment == .preprod && !bypassValidation {
            parameters["force_attest_test"] = "true"
        }

        let request = try makeRequest(
            method: .post,
            path: "/attestation",
            parameters: parameters
        )

        let serverChallenge: ValidApiResponse<String> = try await performRequest(request)

        return serverChallenge.data
    }

    private func makeRequest(method: HTTPMethod, path: String, parameters: [String: String]) throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        urlComponents?.path.append(path)

        if method == .get {
            let queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if method == .post {
            let encoder = JSONEncoder()
            let data = try encoder.encode(parameters)
            urlRequest.httpBody = data
        }

        return urlRequest
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
