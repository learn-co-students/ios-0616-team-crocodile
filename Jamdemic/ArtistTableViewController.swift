//
//  ArtistTableViewController.swift
//  Jamdemic
//
//  Created by Ismael Barry on 8/10/16.
//  Copyright © 2016 crocodile. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SCLAlertView

class ArtistTableViewController: UITableViewController {
    
    var genreQueryString = ""
    
    var artists : [Artist] = []
    
    // Photo cache dictionary to store each artist's image after we do a network call.
    var photoCacheDictionary : [String : UIImage] = [:]
    
    var userSelectedArtists : [Artist] = []
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    // Counter to keep track of how many artist buttons a user has selected.
    var artistButtonPressedNumber = 0
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
        self.tableView.allowsMultipleSelection = true
        
        print(genreQueryString)
        
        tableView.estimatedRowHeight = 320
        
        // Before hitting Spotify API, we check if the access token is valid. If it is not, we get a new one before the API call.
        SpotifyAPIOAuthClient.verifyAccessToken(success: { (token) in
            
            SpotifyAPIClient.generateArtists(withGenres: self.genreQueryString, withToken: token, completion: { (json) in
                
                guard let unwrappedJSON = json else { fatalError("Error unwrapping JSON object in ArtistTableViewController.") }
                
                let tracks = unwrappedJSON["tracks"].arrayValue
                
                for i in tracks {
                    
                    // Returns the each Spotify Artist with their respective 'href' URL to access a JSON object that gives us a URL to their artwork.
                    let artistArtworkURLString = i["artists"][0]["href"].stringValue
                    
                    // Returns the each Spotify Artist with their respective album URL to access their artwork.
                    let albumImageURL = i["album"]["images"][0]["url"].stringValue
                    
                    // Returns the each Spotify Artist with their respective name.
                    let artistsNames = i["artists"][0]["name"].stringValue
                    
                    // Returns the each Spotify Artist with their respective spotifyID.
                    let artistSpotifyID = i["artists"][0]["uri"].stringValue
                    
                    // Since each spotifyID has a specific format, we can seperate the ID number.
                    let separatedSpotifyID = artistSpotifyID.components(separatedBy: "spotify:artist:")[1]
                    
                    // Sets each artists that is returned back to the Artist Object we created.
                    let eachArtist = Artist(name: artistsNames, spotifyID: separatedSpotifyID, artistAlbumArtwork: albumImageURL, artistArtworkURLString: artistArtworkURLString)
                    
                    // Adds each artist that is returned to an array of artists that will then be used to populate the table view.
                    self.artists.append(eachArtist)
                                        
                    eachArtist.description()
                }
                
                // After populating the table view, jump back on to the mainthread to reload the table view.
                OperationQueue.main.addOperation({
                    
                    self.tableView.reloadData()
                    
                })
            })

            // If the Spotify API is unavailable, the user is presented with an alert view.
        }) { (error) in
            
            
            
            print("Error verifying access token in ArtistViewController.")
            
            let alertAppearance = SCLAlertView.SCLAppearance(kTextFont: UIFont(name: "Avenir Next", size: 14)!, kButtonFont: UIFont(name: "Avenir Next", size: 14)!)
            
            let alert = SCLAlertView(appearance: alertAppearance)
            
            alert.showError("Oh no!", subTitle: "Something went wrong!")
        }
    }
    
    // MARK: - Table view data source:
    
    // Required for Alphabetical Header Sections:
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        // Displays every artists that is returned from the API call.
        return self.artists.count
    }
    
   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell") as! ArtistTableViewCell
        let artistName = self.artists[indexPath.row].name
        
        
        // Clears the cell before we start using it. This way we don't get multiple pictures loaded in cells.
        cell.albumArtImageView.image = nil
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.artistNameLabel.text = artistName
      
        
        // we have the image, load from cache
        if let artistPhoto = photoCacheDictionary[artistName] {
         
            cell.albumArtImageView.image = artistPhoto
        
        } else {

            Alamofire.request(self.artists[indexPath.row].artistArtworkURLString, method: .get).validate().responseJSON { (response) in
                
                guard let responseValue = response.response?.statusCode else { fatalError("Error converting response value.") }
                
                if responseValue == 200 {
                    
                    let responseValue = response.result.value
                    
                    guard let unwrappedResponseValue = responseValue else { fatalError("Error unwrapping JSON response.") }
                    
                    let json = JSON(unwrappedResponseValue)
                    
                    let imageURLString = json["images"][0]["url"].stringValue
                    
                    if imageURLString == "" {
                        
                        cell.albumArtImageView.image = UIImage(named: "musicPlaceholderImage")
                        
                    } else {
                        
                        guard let unwrappedURLString = NSURL(string: imageURLString) else { fatalError("Error unwrapping NSUL when converting String to NSURL.") }
                        
                        // Create a background queue because NSData(contentsOFURL:) is a network request call. This needs to happen on the background thread.
                        let queue = OperationQueue()
                        queue.addOperation({
                            
                            guard let imageData = NSData(contentsOf: unwrappedURLString as URL) else { fatalError("Error unwrapping data from image URL.") }
                            
                            // On the main thread, we will add the image to the imageView and cache our dictionary.
                            OperationQueue.main.addOperation({
                                
                                guard let artistImage = UIImage(data: imageData as Data) else { fatalError("unable to unwrap image data") }
                                
                                // As long as the cell is not nil, we will load each artist's image into its respective cell.
                                if tableView.cellForRow(at: indexPath as IndexPath) != nil {
                                    
                                    cell.albumArtImageView.image = artistImage
                                }
                                // Load each artist's image into our photoCacheDictionary so we only make a network call to get images once for each artist.
                                self.photoCacheDictionary[artistName] = artistImage
                            })
                        })
                    }
                    
                } else {
                    
                    print("Error Code: \(responseValue)")
                }
            }
        }
        return cell
    }
    
 func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.artistButtonPressedNumber < 5 {
        
            self.artistButtonPressedNumber = self.artistButtonPressedNumber + 1
        
            print(self.artistButtonPressedNumber)
            
            let selectedArtist = self.artists[indexPath.row]
            
            self.userSelectedArtists.append(selectedArtist)
        
            for artist in userSelectedArtists {
            
                print("The selected artist(s) name: \(artist.name) -- SpotifyID: \(artist.spotifyID)\n")
            }
            
           
            // If the user chooses more than five artists, they are presented with an alert view and no more genres are added to the selectedArtist array.
        } else {
            self.displayMaxArtistsSelectedAlert()
        }
    }
    
    func displayMaxArtistsSelectedAlert() {
        
        let alertAppearance = SCLAlertView.SCLAppearance(kTextFont: UIFont(name: "Avenir Next", size: 14)!, kButtonFont: UIFont(name: "Avenir Next", size: 14)!)
        
        let alert = SCLAlertView(appearance: alertAppearance)
        
        alert.showWarning("", subTitle: "Maximum number of artists selected")

    }
    
    // MARK: - Navigation:
    
   func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showMoodSegue" {
            
            let destinationVC = segue.destination as! MoodViewController
            
            // Pass on the genre query string to further customize our final API call to Spotify.
            destinationVC.genreQueryString = self.genreQueryString
            
            // Pass on the Artists array to further customize our final API call to Spotify.
            destinationVC.userSelectedArtists = self.userSelectedArtists
        }
    }
}
