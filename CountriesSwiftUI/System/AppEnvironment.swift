//
//  AppEnvironment.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 09.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import UIKit
import Combine

struct AppEnvironment {
    let container: DIContainer
    let systemEventsHandler: SystemEventsHandler
}

extension AppEnvironment {
    
    static func bootstrap() -> AppEnvironment {
        let appState = Store<AppState>(AppState())
        /*       Uncomment to see deep linking in action
         
        appState.bulkUpdate { appState in
            appState.routing.countriesList.countryDetails = "AFG"
            appState.routing.countryDetails.detailsSheet = true
        }
        */
        let session = configuredURLSession()
        let webRepositories = configuredWebRepositories(session: session)
        let interactors = configuredInteractors(appState: appState, webRepositories: webRepositories)
        let systemEventsHandler = RealSystemEventsHandler(appState: appState)
        let diContainer = DIContainer(appState: appState, interactors: interactors)
        return AppEnvironment(container: diContainer,
                              systemEventsHandler: systemEventsHandler)
    }
    
    private static func configuredURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }
    
    private static func configuredWebRepositories(session: URLSession) -> WebRepositoriesContainer {
        let countriesWebRepository = RealCountriesWebRepository(
            session: session,
            baseURL: "https://restcountries.eu/rest/v2")
        let imageWebRepository = RealImageWebRepository(
            session: session,
            baseURL: "https://ezgif.com")
        return WebRepositoriesContainer(imageRepository: imageWebRepository,
                                        countriesRepository: countriesWebRepository)
    }
    
    private static func configuredInteractors(appState: Store<AppState>,
                                              webRepositories: WebRepositoriesContainer
    ) -> DIContainer.Interactors {
        let countriesInteractor = RealCountriesInteractor(
            webRepository: webRepositories.countriesRepository,
            appState: appState)
        let inMemoryCache = ImageMemCacheRepository()
        let fileCache = ImageFileCacheRepository()
        let memoryWarning = NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .map { _ in }.eraseToAnyPublisher()
        let imagesInteractor = RealImagesInteractor(
            webRepository: webRepositories.imageRepository,
            inMemoryCache: inMemoryCache,
            fileCache: fileCache,
            memoryWarning: memoryWarning)
        return .init(countriesInteractor: countriesInteractor,
                     imagesInteractor: imagesInteractor)
    }
}

private extension AppEnvironment {
    struct WebRepositoriesContainer {
        let imageRepository: ImageWebRepository
        let countriesRepository: CountriesWebRepository
    }
}
