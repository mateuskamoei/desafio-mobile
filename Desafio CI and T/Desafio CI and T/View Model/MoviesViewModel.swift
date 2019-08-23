//
//  MoviesViewModel.swift
//  Desafio CI&T
//
//  Created by Mateus Kamoei on 31/07/19.
//  Copyright © 2019 Mateus Kamoei. All rights reserved.
//

import Foundation
import UIKit

protocol MoviesViewModelDelegate {
    func didFinishGettingPopularMovies(_ viewModel: MoviesViewModel, dictionary: [String: Any])
    func didFailGettingPopularMovies(_ viewModel: MoviesViewModel, error: Error?)
    func didFinishSearchingMovies(_ viewModel: MoviesViewModel, dictionary: [String: Any])
    func didFailSearchingMovies(_ viewModel: MoviesViewModel, error: Error?)
}

class MoviesViewModel {
    
    private let kResultsKey = "results"
    private let delegate: MoviesViewModelDelegate
    
    private var network: Network!
    private var movies: [Movie]!
    private(set) public var isSearchingMovies = false
    private var page = 0;
    
    var selectedMovieIndex: Int!
    var moviesCount: Int {
        guard let movies = self.movies else { return 0 }
        return movies.count
    }
    var selectedMovie: Movie {
        return self.movies[selectedMovieIndex]
    }
    
    init(delegate: MoviesViewModelDelegate) {
        self.delegate = delegate
        self.network = Network(delegate: self)
        self.movies = [Movie]()
        self.getPopularMovies()
    }
    
    func getPopularMovies() {
        isSearchingMovies = false
        page += 1
        self.network.getPopularMovies(page: page)
    }
    
    func searchMovies(query: String) {
        isSearchingMovies = true
        page += 1
        self.network.searchMovies(query: query, page: page)
    }
    
    func setMovieInformation(on cell: MovieCollectionViewCell, with indexPath: IndexPath) {
        let movie = self.movies[indexPath.row]
        cell.titleLabel.text = movie.title
        cell.imageView.image = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        cell.releaseDateLabel.text = dateFormatter.string(from: movie.releaseDate)
        
        DispatchQueue.global(qos: .background).async {
            let url = URL(string: "https://image.tmdb.org/t/p/w185_and_h278_bestv2\(movie.posterPath)")
            if let data = try? Data(contentsOf: url!) {
                let image = UIImage(data: data)!
                DispatchQueue.main.async {
                    cell.imageView.image = image
                }
            } else {
                DispatchQueue.main.async {
                    cell.imageView.image = nil
                }
            }
        }
    }
    
    func parseMoviesFromDictionary(_ dictionary: [String : Any]) {
        if page == 1 {
            self.movies = [Movie]()
        }
        
        if let results = dictionary[kResultsKey] as? [[String: Any]] {
            for result in results {
                let movie = Movie(result)
                self.movies.append(movie)
            }
        }
    }
    
    func resetPage() {
        page = 0
    }
}

extension MoviesViewModel: NetworkDelegate {
    func didFinishGettingPopularMovies(_ dictionary: [String : Any]) {
        self.parseMoviesFromDictionary(dictionary)
        self.delegate.didFinishGettingPopularMovies(self, dictionary: dictionary)
    }
    
    func didFailGettingPopularMovies(_ error: Error?) {
        self.delegate.didFailGettingPopularMovies(self, error: error)
    }
    
    func didFinishSearchingMovies(_ dictionary: [String : Any]) {
        self.parseMoviesFromDictionary(dictionary)
        self.delegate.didFinishSearchingMovies(self, dictionary: dictionary)
    }
    
    func didFailSearchingMovies(_ error: Error?) {
        self.delegate.didFailSearchingMovies(self, error: error)
    }
}
