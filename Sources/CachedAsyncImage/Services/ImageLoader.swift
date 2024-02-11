//
//  ImageLoader.swift
//  CachedAsyncImage
//
//  Created by Dmitry Kononchuk on 15.06.2023.
//  Copyright © 2023 Dmitry Kononchuk. All rights reserved.
//

import Foundation
import Combine

final class ImageLoader: ObservableObject {
    // MARK: - Public Enums
    
    enum State {
        case idle
        case loading(_ progress: Double = .zero)
        case failed(_ error: String)
        case loaded(_ image: CPImage)
    }
    
    // MARK: - Property Wrappers
    
    @Published private(set) var state: State = .idle
    
    // MARK: - Private Properties
    
    private var imageCache: ImageCacheProtocol
    private let networkManager: NetworkProtocol
    
    private var cancellables: Set<AnyCancellable> = []
    
    private static let imageProcessing = DispatchQueue(
        label: "com.cachedAsyncImage.imageProcessing"
    )
    
    // MARK: - Initializers
    
    init(imageCache: ImageCacheProtocol, networkManager: NetworkProtocol) {
        self.imageCache = imageCache
        self.networkManager = networkManager
    }
    
    // MARK: - Deinitializers
    
    deinit {
        cancel()
    }
    
    // MARK: - Public Methods
    
    func fetchImage(from url: String) {
        if case .loading = state { return }
        
        if let url = URL(string: url), let cachedImage = imageCache[url] {
            state = .loaded(cachedImage)
            return
        }
        
        let (progress, data) = networkManager.fetchImage(from: URL(string: url))
        
        progress?
            .publisher(for: \.fractionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fractionCompleted in
                self?.state = .loading(fractionCompleted)
            }
            .store(in: &cancellables)
        
        data
            .map { CPImage(data: $0) }
            .catch { [weak self] error -> AnyPublisher<CPImage?, Never> in
                if let error = error as? NetworkError {
                    Task { @MainActor [weak self] in
                        self?.state = .failed(error.rawValue)
                    }
                    
                    self?.log(error.rawValue, url: url)
                }
                
                return Just(nil).eraseToAnyPublisher()
            }
            .handleEvents(
                receiveSubscription: { _ in
                    Task { @MainActor [weak self] in
                        self?.state = .loading()
                    }
                },
                receiveOutput: { [weak self] in
                    self?.cache(url: URL(string: url), image: $0)
                }
            )
            .subscribe(on: Self.imageProcessing)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let image = image else { return }
                self?.state = .loaded(image)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func cache(url: URL?, image: CPImage?) {
        guard let url = url else { return }
        image.map { imageCache[url] = $0 }
    }
    
    private func cancel() {
        cancellables.forEach { $0.cancel() }
    }
    
    private func log(_ error: String, url: String) {
        guard let emoji = Emoji.getEmoji(from: .hammer) else { return }
        
        let errorMessage = "Error: \(error)"
        let urlMessage = "URL: \(url)"
        
        Log.failure.error(
            "\(emoji) CachedAsyncImage\n\(errorMessage)\n\(urlMessage)"
        )
    }
}
