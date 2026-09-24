//
//  PomeloRPC.swift
//  Pomelo
//
//  Created by Stossy11 on 17/11/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import Foundation

func startRPC(game: PomeloGame) {
    // The URL of the server endpoint
    let urlString = UserDefaults.standard.string(forKey: "pomeloRPCIP")
    guard let url = URL(string: urlString ?? "") else {
        print("Invalid URL")
        return
    }
    
    // The data to send in the request
    let json: [String: Any] = [
        "name": game.title,
        "id": String(game.programid),
        "developer": game.developer
    ]
    
    // Convert the dictionary to JSON data
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        
        // Create the POST request
        var request = URLRequest(url: url.appendingPathComponent("start-rpc"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Create a URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Data successfully sent to server")
            } else {
                print("Failed to send data. Server responded with: \(String(describing: response))")
            }
        }
        
        // Start the task
        task.resume()
        
    } catch {
        print("Error encoding JSON: \(error.localizedDescription)")
    }
}


func rpcHeartBeat() {
    
    let urlString = UserDefaults.standard.string(forKey: "pomeloRPCIP")
    
    guard let url = URL(string: urlString ?? "") else {
        print("Invalid URL string")
        return
    }
    
    let urlRequest = URLRequest(url: url.appendingPathComponent("heartbeat"))
    
    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
        print(data)
        print(response)
        print(error)
    }
    
    task.resume()
}
