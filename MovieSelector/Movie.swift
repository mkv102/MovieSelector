//
//  Movie.swift
//  MovieSelector
//
//  Created by Mukund Vemuri on 2017-08-23.
//  Copyright © 2017 Mukund Vemuri. All rights reserved.
//

import UIKit

public struct Movie {
    
    static let APIKEY = "9989acf39dd3f2306ecc0614bf889611"

    private static let imageBaseUrl = "https://image.tmdb.org/t/p/w500"
    
    public var title:String!
    public var imagePath:String!
    public var description:String!
    
    
    public init(title:String, imagePath:String, description:String) {
        self.title = title
        self.imagePath = imagePath
        self.description = description
    }
    
    private static func getMovieData (with completion:@escaping (_ success:Bool, _ object:AnyObject?)->()) {
        
        let session = URLSession(configuration: .default)
        
        let request = URLRequest(url: URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(APIKEY)")!)
        
        session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    completion(true, json as AnyObject?)
                } else {
                    completion(false, json as AnyObject?)
                }
            }
            
        }.resume()
    }
    
    public static func nowPlaying (with completion: @escaping (_ success: Bool, _ movies: [Movie]?)->()) {
    
        Movie.getMovieData { (success, object) in
            if success {
                var movieArray = [Movie]()
                
                if let movieResults = object?["results"] as? [Dictionary<String, AnyObject>] {
                    for movie in movieResults {
                        let title = movie["original_title"] as! String
                        let description = movie["overview"] as! String
                        
                        guard let posterImage = movie["poster_path"] as? String else {continue}
                        
                        let movieObj = Movie(title: title, imagePath: posterImage, description: description)
                        movieArray.append(movieObj)
                    }
                    completion(true, movieArray)
                } else {
                    completion(false, nil)
                }
            }
        }
    
    }
    
    private static func getDocumentsDirectory () -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        guard let documents:String = paths.first else {return nil}
        
        return documents
    }
    
    private static func checkForImageData (withMovieObject movie:Movie) ->String?{
        if let documents = getDocumentsDirectory() {
            let movieImagePath = documents + "/\(movie.title!)"
            
            let escapedImagePath = movieImagePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            if FileManager.default.fileExists(atPath: escapedImagePath!) {
                return escapedImagePath
            }
        }
        
        return nil
    }
    
    public static func getImage (forCell cell:AnyObject, withMovieObject movie:Movie){
        if let imagePath = checkForImageData(withMovieObject: movie) {
            // image already downloaded
            if let imageData = FileManager.default.contents(atPath: imagePath) {
                if cell is UITableViewCell {
                    let tableViewCell = cell as! UITableViewCell
                    tableViewCell.imageView?.image = UIImage(data: imageData)
                    tableViewCell.setNeedsLayout()
                    
                } else {
                    let collectionViewCell = cell as! MovieCollectionViewCell
                    collectionViewCell.movieImageView.image = UIImage(data: imageData)
                    collectionViewCell.setNeedsLayout()
                }
            }
        } else {
            let imagePath = Movie.imageBaseUrl + movie.imagePath
            
            let imageUrl = URL(string: imagePath)
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                do {
                    let data = try Data(contentsOf: imageUrl!)
                    
                    let documents = getDocumentsDirectory()
                    
                    let imageFilePathString = documents! + "/\(movie.title!)"
                    
                    let escapedImagePath = imageFilePathString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    
                    if FileManager.default.createFile(atPath: escapedImagePath!, contents: data, attributes: nil) {
                        print("image saved")
                    }
                    
                    DispatchQueue.main.async(execute: {
                        if cell is UITableViewCell {
                            let tableViewCell = cell as! UITableViewCell
                            tableViewCell.imageView?.image = UIImage(data: data)
                            tableViewCell.setNeedsLayout()
                        } else {
                            let collectionViewCell = cell as! MovieCollectionViewCell
                            collectionViewCell.movieImageView.image = UIImage(data: data)
                            collectionViewCell.setNeedsLayout()
                        }
                    })
                    
                } catch {
                    print("no image at specified location.")
                }
            }
            
        }
    }
}
