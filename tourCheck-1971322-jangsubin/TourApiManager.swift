import Foundation

class TourAPIManager: NSObject, URLSessionDelegate {
    static let shared = TourAPIManager()
    let apiKey = "TSYnT8M8MmhQbGkHsE22ER5TPWVEZDGMga2YGiUwzDs8He9AmrsniQJitHnwgJVpgJcf+/9LMl2ReS6+WWSZVg=="
    let baseURLString = "http://apis.data.go.kr/B551011/KorService1"

    func fetchTouristSpots(keyword: String, completion: @escaping ([TouristSpot]?) -> Void) {
        let path = "/searchKeyword1"
        let query: [String: String] = [
            "serviceKey": apiKey,
            "numOfRows": "20",
            "pageNo": "1",
            "MobileOS": "IOS",
            "MobileApp": "tourCheck",
            "_type": "json",
            "contentTypeId": "12",
            "arrange": "O",
            "keyword": keyword
        ]

        guard let url = constructURL(path: path, query: query) else {
            print("Error: Invalid URL")
            completion(nil)
            return
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.dataTask(with: url) { data, response, error in
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
                let filteredSpots = response.response.body.items.item.filter { $0.firstimage != nil && !$0.firstimage!.isEmpty }
                completion(filteredSpots)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }

    private func constructURL(path: String, query: [String: String]) -> URL? {
        var urlComponents = URLComponents(string: baseURLString + path)
        urlComponents?.queryItems = query.map {
            URLQueryItem(name: $0.key, value: "\($0.value)")
        }
        // '+' 문자를 '%2B'로 변환
        let encodedQuery = urlComponents?.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        urlComponents?.percentEncodedQuery = encodedQuery
        return urlComponents?.url
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
