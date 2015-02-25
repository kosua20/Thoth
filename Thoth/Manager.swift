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
    var uploader : FTPManager
    var server : FMServer?
    
    init(rootPath : String, configuration : Config){
        // println("Initializing the manager...")
        self.rootPath = rootPath
        self.config = configuration
        self.loader = Loader(folderPath: config.articlesPath, defaultAuthor: config.defaultAuthor, dateStyle:config.dateStyle)
        //println("Loader loaded")
        self.loader.sortArticles()
        //println("Articles sorted")
        self.renderer = Renderer(articles: self.loader.articles, articlesPath: config.articlesPath, exportPath: config.outputPath, rootPath: rootPath, templatePath:config.templatePath, defaultWidth:config.imageWidth, blogTitle: config.blogTitle, imagesLink : config.imagesLinks)
        //println("Renderer rendered")
        self.uploader = FTPManager()
        
    }
    
    func generate(option : Int) {
        //println("Option : \(option)")
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
        println("Generation done !")
    }
    
    func upload(option : Int = 0){
        //println("Option : \(option)")
        server = FMServer(destination: config.ftpAdress, username: config.ftpUsername, password: config.ftpPassword)
        if !uploader.checkLogin(server) { println("Unable to login.");return}
        print("Beginning upload to \(config.ftpAdress)...\t")
        var succeeded = true
        let contents1 = uploader.contentsOfServer(server) as [NSDictionary]
        switch option {
        case 1:
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("articles"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("index.html"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("resources"), force: false, contents: contents1)
        case 2:
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("drafts"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("index-drafts.html"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("resources"), force: false, contents: contents1)
        case 3:
            for element in NSFileManager.defaultManager().contentsOfDirectoryAtPath(config.outputPath, error: nil) as [String] {
                
                succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent(element), force: true, contents: contents1)
            }
        default:
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("drafts"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("articles"), force: false, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("index.html"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("index-drafts.html"), force: true, contents: contents1)
            succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent("resources"), force: false, contents: contents1)
        }
        /*for element in NSFileManager.defaultManager().contentsOfDirectoryAtPath(config.outputPath, error: nil) as [String] {
        if option == 3 {
        //Full export
        succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent(element), force: true)
        } else if element == "articles" && option == 1{
        //Articles only
        succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent(element), force: true)
        } else if element == "drafts" && (option == 2 || option == 0){
        //Drafts only
        succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent(element), force: true)
        } else if element == "index.html" || element == "index-drafts.html" {
        succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent(element), force: true)
        } else {
        succeeded = succeeded && uploadElementAtPath(config.outputPath.stringByAppendingPathComponent(element), force: false)
        }
        }*/
        
        if !succeeded {
            println("An error occured during the upload")
        } else {
            println("Upload successful !")
        }
    }
    
    func cleanElementAtPath(path : String) {
        var isDir : ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir){
            if isDir {
                server!.destination = server!.destination.stringByAppendingPathComponent(path.lastPathComponent)
                for file in NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil) as [String]{
                    cleanElementAtPath(path.stringByAppendingPathComponent(file))
                }
                server!.destination = server!.destination.stringByDeletingLastPathComponent
                
            }
            uploader.deleteFileNamed(path.lastPathComponent, fromServer: server)
        }
    }
    
    func uploadElementAtPath(path :  String, force : Bool, contents : [NSDictionary]) -> Bool {
        if path.lastPathComponent.hasPrefix("."){
            return true
        }
        if force {
            cleanElementAtPath(path)
        }
        var isDir : ObjCBool = false
        var succeeded = true
        if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir){
            var found = false
            var isDistantDirectory = false
            superLoop : for dict in contents {
                let name: String = dict.objectForKey(kCFFTPResourceName) as String
                if name == path.lastPathComponent {
                    found = true
                    isDistantDirectory = (dict.objectForKey(kCFFTPResourceType)?.intValue) == 4
                    
                    //println("\(path) \(isDistantDirectory)")
                    break superLoop
                }
            }
            
            
            
            if isDir {
                if !found {
                    uploader.createNewFolder(path.lastPathComponent , atServer: server)
                }
                server!.destination = server!.destination.stringByAppendingPathComponent(path.lastPathComponent)
                if found {
                    //println("1 ")
                }
                
                let contents1 = uploader.contentsOfServer(server) as [NSDictionary]
                
                for file in NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil) as [String]{
                    succeeded = succeeded && uploadElementAtPath(path.stringByAppendingPathComponent(file), force : force, contents : contents1)
                }
                server!.destination = server!.destination.stringByDeletingLastPathComponent
                
            } else {
                if !found || force {
                    succeeded = succeeded && uploader.uploadFile(NSURL(string: path), toServer: server)
                }
            }
        }
        
        return succeeded
    }
    
    func index() {
        renderer.updateIndex()
    }
    
    func resources(){
        renderer.updateResources()
    }
    
}