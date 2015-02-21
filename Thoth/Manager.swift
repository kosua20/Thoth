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
    let uploader : FTPManager
    
    init(rootPath : String, configuration : Config){
        println("Initializing the manager...")
        self.rootPath = rootPath
        self.config = configuration
        self.loader = Loader(folderPath: config.articlesPath, defaultAuthor: config.defaultAuthor, dateStyle:config.dateStyle)
        println("Loader loaded")
        self.loader.sortArticles()
        println("Articles sorted")
        self.renderer = Renderer(articles: self.loader.articles, articlesPath: config.articlesPath, exportPath: config.outputPath, rootPath: rootPath, defaultWidth:config.imageWidth, blogTitle: config.blogTitle, imagesLink : config.imagesLinks)
        println("Renderer rendered")
        self.uploader = FTPManager()
    }
    
    func generate(option : Int) {
        println("Option : \(option)")
        switch option {
            case 1:
                renderer.articlesOnly()
            case 2:
                renderer.draftsOnly()
            case 3:
                renderer.fullExport()
            default:
                renderer.defaultExport()
        }
        println("Export done !")
    }
    
    func upload(){
        let server = FMServer(destination: config.ftpAdress, username: config.ftpUsername, password: config.ftpPassword)
        server.destination
        let progTimer = NSTimer(timeInterval: 0.1, target: self, selector: Selector("changeProgress"), userInfo: nil, repeats: true)
        println("Beggining upload to \(config.ftpAdress)")
        
        let filePath = "/Developer/XCode/Siblog/Test/output/articles/01-09-2011_auberge_japonaise.html"
        var succeeded = false
        
        let succeeded = self.uploader.uploadFile(NSURL(string: filePath), toServer: server)
        
        progTimer.invalidate()
    }
    
    func uploadElementAtPath(path :  String, toPath uploadPath : String) -> Bool {
        if
    }
    
    func changeProgress() {
        if let progress : NSNumber = uploader.progress().objectForKey("kFMProcessInfoProgress") as? NSNumber{
            println(progress.floatValue * 100)
        }
    }
    
    func index() {
        renderer.updateIndex()
    }
    
    func ressources(){
        renderer.updateRessources()
    }
    
}