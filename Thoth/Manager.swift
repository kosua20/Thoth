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
    let loader : Loader
    let renderer : Renderer
    
    init(rootPath : String, configuration : Config){
        self.rootPath = rootPath
        self.config = configuration
        self.loader = Loader(folderPath: config.articlesPath, defaultAuthor: config.defaultAuthor, dateStyle:config.dateStyle)
        self.loader.sortArticles()
        self.renderer = Renderer(articles: self.loader.articles, articlesPath: config.articlesPath, exportPath: config.outputPath, rootPath: rootPath, defaultWidth:config.imageWidth, blogTitle: config.blogTitle)
    }
    
    func generate(option : Int) {
        switch option {
            case 1:
                renderer.articlesOnly()
            case 2:
                renderer.draftsOnly()
            case 4:
                renderer.fullExport()
            default:
                renderer.defaultExport()
        }
        println("Export done !")
    }
    
    func index() {
        renderer.updateIndex()
    }
    
    func ressources(){
        renderer.updateRessources()
    }
    
}