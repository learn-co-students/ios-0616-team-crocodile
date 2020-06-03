//
//  SpotifyAPIClient.swift
//  Jamdemic
//
//  Created by Ismael Barry on 8/11/16.
//  Copyright © 2016 crocodile. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class SpotifyAPIClient {
    
    struct URLRouter {
        
       static let baseURLString = "https://api.spotify.com/v1/recommendations?"
        
    }
    
    struct spotifyParameter {
        
        static let seedGenre = "seed_genres"
        
        static let seedArtists = "seed_artist"
        
        static let seedLimit = "limit"
        
        static let authorization = "Authorization"
        
    }
    
    // Genre and token are placeholders here. When we call the function in the controller, we then pass these values in.
    class func generateArtists(withGenres genre: String, withToken token: String, completion: @escaping (JSON?) -> ()) {
        
        let genreParameterDictionary = [spotifyParameter.seedGenre : genre]
        
        let authorizationDictionary = [spotifyParameter.authorization : "Bearer \(token)"]
        
        
        Alamofire.request(URLRouter.baseURLString, method:.get, parameters: genreParameterDictionary, encoding: URLEncoding(destination: .queryString), headers: authorizationDictionary).validate().responseJSON { (response) in
            
            guard let responseValue = response.response?.statusCode else { fatalError("Error converting response value.") }
            
            if responseValue == 200 {
                
                let responseValue = response.result.value
                
                guard let unwrappedResponseValue = responseValue else { fatalError("Error unwrapping JSON response.") }
                
                let json = JSON(unwrappedResponseValue)
                
                completion(json)
                
            } else {
                
                print("Error Code: \(responseValue)")
                
                completion(nil)
            }
        }
    }
    
    // Artist, Genre, Mood and token are placeholders here. When we call the function in the controller, we then pass these values in.
    class func generateArtistsAndSongs(withUserSelectedArtists selectedArtists : String, withGenre genre : String,  withMood mood: [String : AnyObject], withToken token: String, completion:@escaping (JSON?, NSError?) -> ()) {
        
        var parameterDictionary : [String : AnyObject] = ([spotifyParameter.seedArtists : selectedArtists, spotifyParameter.seedGenre : genre, spotifyParameter.seedLimit : 80] as AnyObject) as! [String : AnyObject]
        
        let authorizationDictionary = [spotifyParameter.authorization : "Bearer \(token)"]
        
        for (key, value) in mood {
            
            parameterDictionary[key] = value
        }
     
        Alamofire.request(URLRouter.baseURLString,method: .get, parameters: parameterDictionary, encoding: URLEncoding(destination: .queryString), headers: authorizationDictionary).validate().responseJSON { (response) in
                 let responseValue = response.result.value
            guard let unwrappedResponseValue = responseValue else { fatalError("Error unwrapping response value.") }
            
            switch response.result {
             
            case .success(let _)://.Sucess
               let responseValue = response.result.value
                
                guard let unwrappedResponseValue = responseValue else { fatalError("Error unwrapping response value.") }
                
                let json = JSON(unwrappedResponseValue)
                
                completion(json, nil)
                
            case .failure(let error):
            //.Failure(let error):
                
                print(error.localizedDescription)
                completion(nil, error as NSError)
            }
            
        }
    }
}
