import Foundation
import Network

// MARK: - 네트워크 매니저
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:5000"  // Python 서버 주소
    private let session = URLSession.shared
    private let monitor = NWPathMonitor()
    
    @Published var isConnected = false
    @Published var serverAvailable = false
    
    private init() {
        startNetworkMonitoring()
        checkServerHealth()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if self?.isConnected == true {
                    self?.checkServerHealth()
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func checkServerHealth() {
        guard let url = URL(string: "\(baseURL)/health") else { return }
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    self?.serverAvailable = true
                } else {
                    self?.serverAvailable = false
                }
            }
        }
        task.resume()
    }
    
    // MARK: - API 호출 메서드들
    
    func analyzePaceStability(data: [String: Any]) async throws -> [String: Any] {
        return try await performRequest(endpoint: "/analyze/pace_stability", data: data)
    }
    
    func analyzeEfficiency(data: [String: Any]) async throws -> [String: Any] {
        return try await performRequest(endpoint: "/analyze/efficiency", data: data)
    }
    
    func analyzeOvertraining(data: [String: Any]) async throws -> [String: Any] {
        return try await performRequest(endpoint: "/analyze/overtraining", data: data)
    }
    
    func optimizeCadence(data: [String: Any]) async throws -> [String: Any] {
        return try await performRequest(endpoint: "/analyze/cadence_optimization", data: data)
    }
    
    func predictOptimalCadence(targetPace: Double) async throws -> [String: Any] {
        let data = ["target_pace_seconds_per_km": targetPace]
        return try await performRequest(endpoint: "/predict/optimal_cadence", data: data)
    }
    
    func analyzeRecoveryPattern(data: [String: Any]) async throws -> [String: Any] {
        return try await performRequest(endpoint: "/analyze/recovery_pattern", data: data)
    }
    
    func performComprehensiveAnalysis(data: [String: Any]) async throws -> [String: Any] {
        return try await performRequest(endpoint: "/analyze/comprehensive", data: data)
    }
    
    private func performRequest(endpoint: String, data: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        guard serverAvailable else {
            throw NetworkError.networkUnavailable
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                return jsonObject
            } else {
                throw NetworkError.decodingError
            }
        } catch {
            throw NetworkError.decodingError
        }
    }
}

// MARK: - 네트워크 에러
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case serverError(Int)
    case decodingError
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .encodingError:
            return "데이터 인코딩에 실패했습니다."
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .serverError(let code):
            return "서버 오류가 발생했습니다. (코드: \(code))"
        case .decodingError:
            return "응답 데이터 디코딩에 실패했습니다."
        case .networkUnavailable:
            return "네트워크 연결을 확인해주세요."
        }
    }
}
