//
//  ArtistViewController.swift
//  Jamdemic
//
//  Created by Matt Amerige on 8/22/16.
//  Copyright © 2016 crocodile. All rights reserved.
//

import UIKit
import SCLAlertView
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView

class ArtistViewController: UIViewController, NVActivityIndicatorViewable {
    
    var genreQueryString = ""
    
    var artists : [Artist] = []
    
    // Photo cache dictionary to store each artist's image after we do a network call.
    var photoCacheDictionary : [String : UIImage] = [:]
    
    var userSelectedArtists : [Artist] = []
    
    // Counter to keep track of how many artist buttons a user has selected.
    var artistButtonPressedNumber = 0
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Cell Spacing
    let numberOfColumns: CGFloat = 2.0
    let cellSpacing: CGFloat = 5.0
    var totalSpacing: CGFloat {
        return numberOfColumns + 1
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsMultipleSelection = true
        
        self.setCollectionViewPadding()
        self.querySpotifyForArtists()
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

// MARK: - Spotify Queries
extension ArtistViewController {
    func querySpotifyForArtists() {
        
        self.startAnimating(message: "Loading...", type: .lineScalePulseOutRapid)
        print("Seaching for artists matching genre: \(self.genreQueryString)")
        SpotifyAPIOAuthClient.verifyAccessToken(success: { (token) in
            
            SpotifyAPIClient.generateArtists(withGenres: self.genreQueryString, withToken: token, completion: { (json) in
                
                guard let unwrappedJSON = json else {
                    print("Error unwrapping JSON object in ArtistTableViewController.")
                    return
                }
                
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
                    self.stopAnimating()
                    self.collectionView.reloadData()
                    
                })
            })
            
            // If the Spotify API is unavailable, the user is presented with an alert view.
        }) { (error) in
            self.stopAnimating()
            print("Error verifying access token in ArtistViewController.")
            
            let alertAppearance = SCLAlertView.SCLAppearance(kTextFont: UIFont(name: "Avenir Next", size: 14)!, kButtonFont: UIFont(name: "Avenir Next", size: 14)!)
            
            let alert = SCLAlertView(appearance: alertAppearance)
            
            alert.showError("Oh no!", subTitle: "Something went wrong!")
        }
        
    }
}

// MARK: - Collection View Stuff
extension ArtistViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: Cell Layout & Sizing
    private func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return calculcateCellSize()
        
    }
    
    private func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    private func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    func calculcateCellSize() -> CGSize {
        let cellWidthAndHeight = (self.collectionView.bounds.size.width - (self.cellSpacing * self.totalSpacing)) / self.numberOfColumns
        return CGSize(width: cellWidthAndHeight, height: cellWidthAndHeight)
    }
    
    func setCollectionViewPadding() {
        self.collectionView.contentInset = UIEdgeInsets(top: self.cellSpacing, left: self.cellSpacing, bottom: self.cellSpacing, right: self.cellSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.artists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell  {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "artistCell", for: indexPath as IndexPath) as! ArtistCollectionViewCell
        
        let artistObj = self.artists[indexPath.row]
        
        cell.artistNameLabel.text = artistObj.name
        
        if cell.isSelected {
            cell.selectedImageView.isHidden = false
            cell.artistHighlightedState.isHidden = false
        }
        else {
            cell.selectedImageView.isHidden = true
            cell.artistHighlightedState.isHidden = true
        }
        
        self.loadPhotosForArtist(artist: artistObj, cell: cell, indexPath: indexPath as NSIndexPath)
        
        
        return cell
    }
    
    private func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.userSelectedArtists.count == 5 {
            self.displayMaxArtistsSelectedAlert()
            return false
        }
        return true
    }
    
    private func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedArtist = self.artists[indexPath.row]
        
        self.userSelectedArtists.append(selectedArtist)
        
        for artist in userSelectedArtists {
            
            print("The selected artist(s) name: \(artist.name) -- SpotifyID: \(artist.spotifyID)\n")
        }
        
        if let cell = collectionView.cellForItem(at: indexPath as IndexPath) as? ArtistCollectionViewCell {
            cell.selectedImageView.isHidden = false
            cell.artistHighlightedState.isHidden = false            
        }
        
    }
    
    private func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedArtist = self.artists[indexPath.row]
        
        let indexToRemove = self.userSelectedArtists.firstIndex(where: { $0.name == selectedArtist.name} )
        
        if let indexToRemove = indexToRemove {
            self.userSelectedArtists.remove(at:indexToRemove)
        }
        
        if let cell = collectionView.cellForItem(at: indexPath as IndexPath) as? ArtistCollectionViewCell {
            cell.selectedImageView.isHidden = true
            cell.artistHighlightedState.isHidden = true
        }
        
        
        
    }
    
}


// MARK: - Loading Photos
extension ArtistViewController {
    func loadPhotosForArtist(artist: Artist, cell: ArtistCollectionViewCell, indexPath: NSIndexPath) {
        
        // Reset the image so when the cell is reused the previous image does not show up
        cell.artistImageView.image = nil
        
        // we have the image, load from cache
        if let artistPhoto = photoCacheDictionary[artist.name] {
            cell.artistImageView.image = artistPhoto
            
        } else {
            
            Alamofire.request(artist.artistArtworkURLString, method: .get)
                .validate().responseJSON { response in
                    
                    guard let responseValue = response.response?.statusCode else { fatalError("Error converting response value.") }
                    
                    if responseValue == 200 {
                        
                        let responseValue = response.result.value
                        
                        guard let unwrappedResponseValue = responseValue else { fatalError("Error unwrapping JSON response.") }
                        
                        let json = JSON(unwrappedResponseValue)
                        
                        let imageURLString = json["images"][0]["url"].stringValue
                        
                        if imageURLString == "" {
                            
                            cell.artistImageView.image = UIImage(named: "musicPlaceholderImage")
                            
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
                                    if self.collectionView.cellForItem(at: indexPath as IndexPath) != nil {
                                        
                                        cell.artistImageView.image = artistImage
                                    }
                                    // Load each artist's image into our photoCacheDictionary so we only make a network call to get images once for each artist.
                                    self.photoCacheDictionary[artist.name] = artistImage
                                })
                            })
                        }
                        
                    } else {
                        
                        print("Error Code: \(responseValue)")
                    }
            }
        }
        
    }
}
