//
//  Manager.swift
//  Siblog
//
//  Created by Simon Rodriguez on 07/02/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

class Manager {
    let rootPath : String
    let config : Config
    
    init(rootPath : String, configuration : Config){
        self.rootPath = rootPath
        self.config = configuration
    }
    
    
    
    func generate() {
                let loader = Loader(folderPath: config.articlesPath, defaultAuthor: config.defaultAuthor, dateStyle:config.dateStyle)
                loader.sortArticles()
                let renderer = Renderer(articles: loader.articles, articlesPath: config.articlesPath, exportPath: config.outputPath, rootPath: rootPath, defaultWidth:config.imageWidth, blogTitle: config.blogTitle)
                renderer.fullExport()
                println("Export done !")
    }
    
}