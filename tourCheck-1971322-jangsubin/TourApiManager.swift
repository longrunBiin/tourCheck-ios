import Foundation

class TourAPIManager: NSObject, URLSessionDelegate {
    static let shared = TourAPIManager()
    let apiKey = "TSYnT8M8MmhQbGkHsE22ER5TPWVEZDGMga2YGiUwzDs8He9AmrsniQJitHnwgJVpgJcf+/9LMl2ReS6+WWSZVg=="

    func fetchTouristSpots(keyword: String, completion: @escaping ([TouristSpot]?) -> Void) {
        let urlString = "http://apis.data.go.kr/B551011/KorService1/searchKeyword1"
        let parameters = [
            "serviceKey": apiKey,
            "numOfRows": "10",
            "pageNo": "1",
            "MobileOS": "IOS",
            "MobileApp": "tourCheck",
            "_type": "json",
            "keyword": keyword
        ]

        var urlComponents = URLComponents(string: urlString)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let requestURL = urlComponents?.url else {
            print("Error: Invalid URL")
            completion(nil)
            return
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("Error: No data received")
                completion(nil)
                return
            }

            do {
                let responseString = String(data: data, encoding: .utf8)
                print("Response Data: \(responseString ?? "No Response")")
                
                let decoder = JSONDecoder()
                let response = try decoder.decode(TouristSpotResponse.self, from: data)
                completion(response.response.body.items.item)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    // URLSessionDelegate 메서드 추가
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, credential)
    }
}

struct TouristSpotResponse: Codable {
    let response: Response

    struct Response: Codable {
        let body: Body

        struct Body: Codable {
            let items: Items

            struct Items: Codable {
                let item: [TouristSpot]
            }
        }
    }
}

struct TouristSpot: Codable {
    let title: String
    let addr1: String
    let firstimage: String?
}
