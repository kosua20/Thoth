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
    var loader : Loader?
    var renderer : Renderer?
    let ftpAdress : String
    let ftpPath : String
    var ftpServer : NMSFTP?
    
    
    init(rootPath : String, configuration : Config){
        // println("Initializing the manager...")
        self.rootPath = rootPath
        self.config = configuration
        self.loader = nil
        self.renderer = nil

        
        //Bit of string refactoring for simpler access with NMSSH
        var pathscomp = config.ftpAdress.pathComponents
        self.ftpAdress = pathscomp.removeAtIndex(0)
        self.ftpPath = "/".join(pathscomp).stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "/"))
        self.ftpServer = nil;
        
    }
    
    func initRenderer(){
        self.loader = Loader(folderPath: config.articlesPath, defaultAuthor: config.defaultAuthor, dateStyle:config.dateStyle)
        //println("Loader loaded")
        self.loader!.sortArticles()
        //println("Articles sorted")
        //println("Option : \(option)")
        self.renderer = Renderer(articles: self.loader!.articles, articlesPath: config.articlesPath, exportPath: config.outputPath, rootPath: rootPath, templatePath:config.templatePath, defaultWidth:config.imageWidth, blogTitle: config.blogTitle, imagesLink : config.imagesLinks, siteRoot: config.siteRoot)
        //println("Renderer rendered")
    }
    
    func generate(option : Int) {
        if renderer == nil {
            initRenderer()
        }
        if let renderer = renderer {
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
        } else {
            println("Error with the renderer")
        }
    }
    
    
    
    func runTest(){
        print("Testing SFTP \(ftpAdress)...\t")
        if (ftpServer == nil){
            if !initSession(){
                println("Error when connecting to the server")
                return
            }
        }
        if let ftpServer = ftpServer {
            if ftpServer.connected {
                println("Connection to the server is valid.")
                ftpServer.disconnect()
                return
            }
        }
        println("Encountered an error (probably)")
    }
    
   
    func initSession() -> Bool{
        print("Connecting to the server...\t")
        NMSSHLogger.sharedLogger().enabled = false
        let session = NMSSHSession.connectToHost(self.ftpAdress, port: config.ftpPort, withUsername: config.ftpUsername)
        if session.connected {
            session.authenticateByPassword(config.ftpPassword)
            
        }
        if session.connected && session.authorized {
            ftpServer = NMSFTP.connectWithSession(session)
            return true
        } else {
            println("Error when connecting to SFTP server")
            ftpServer = nil;
            return false
        }
    }
    
    
    func upload(option : Int = 0){
        if (ftpServer == nil){
            if !initSession(){
                return
            }
        }
        //From here, we can force unwrap ftpServer without risk
        
        print("Beginning upload to \(ftpAdress)...\t")
        var succeeded = true
        switch option {
        case 1:
            succeeded = succeeded && uploadElementAtPath("articles", force: true)
            succeeded = succeeded && uploadElementAtPath("index.html", force: true)
            succeeded = succeeded && uploadElementAtPath("resources", force: false)
        case 2:
            succeeded = succeeded && uploadElementAtPath("drafts", force: true)
            succeeded = succeeded && uploadElementAtPath("index-drafts.html", force: true)
            succeeded = succeeded && uploadElementAtPath("resources", force: false)
        case 3:
            for element in NSFileManager.defaultManager().contentsOfDirectoryAtPath(config.outputPath, error: nil) as! [String] {
                succeeded = succeeded && uploadElementAtPath(element, force: true)
            }
        default:
            succeeded = succeeded && uploadElementAtPath("drafts", force: true)
            succeeded = succeeded && uploadElementAtPath("articles", force: false)
            succeeded = succeeded && uploadElementAtPath("index.html", force: true)
            succeeded = succeeded && uploadElementAtPath("index-drafts.html",force: true)
            succeeded = succeeded && uploadElementAtPath("resources", force: false)
        }
        
        if !succeeded {
            println("An error occured during the upload")
        } else {
            println("Upload successful !")
        }
        
        ftpServer!.disconnect()
    }
    
    private func cleanElementAtPath(distantPath : String) {
        //println("DB: " + distantPath)
        if ftpServer!.fileExistsAtPath(distantPath) {
            //println("File exists")
            ftpServer!.removeFileAtPath(distantPath)
        }
        if ftpServer!.directoryExistsAtPath(distantPath){
          //  println("Folder exists")
            ftpServer!.removeDirectoryAtPath(distantPath)
        }
        //println("Done cleaning")
    }
    
    private func uploadElementAtPath(path :  String, force : Bool) -> Bool {
        
        
        //hack for hidden files
        if path.lastPathComponent.hasPrefix("."){
            return true
        }
        
        var succeeded = true;
        
        //Checking if the file exists locally (else we don't do anything)
        var isDir : ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(config.outputPath.stringByAppendingPathComponent(path), isDirectory: &isDir){
            
            let distantPath = ftpPath.stringByAppendingPathComponent(path)
            
            //Cleaning the potentially already existing file on the server
            
            if force {
               // println("Cleaning")
                cleanElementAtPath(distantPath)
            }
            
            if isDir { //This is a folder
                //Creating the folder if it doesn't already exist
                //println("Creating directory")
                if !ftpServer!.directoryExistsAtPath(distantPath) {
                    ftpServer!.createDirectoryAtPath(distantPath)
                }
                
                for file in NSFileManager.defaultManager().contentsOfDirectoryAtPath(config.outputPath.stringByAppendingPathComponent(path), error: nil) as! [String]{
                    succeeded = succeeded && uploadElementAtPath(path.stringByAppendingPathComponent(file), force : false)
                }
                
            } else { //This is a file
                //If the file doesn't exists, or if we force (normally it has been cleaned, but let's be careful
                 if !ftpServer!.fileExistsAtPath(distantPath) || force {
                   // println("Uplaoding file...")
                    succeeded = succeeded && ftpServer!.writeFileAtPath(config.outputPath.stringByAppendingPathComponent(path), toFileAtPath: distantPath)
                    
                }
            }
        }
        
        return succeeded
    }
    
    func index() {
        if renderer == nil {
            initRenderer()
        }
        if let renderer = renderer {
            renderer.updateIndex()
        }
    }
    
    func resources(){
        if renderer == nil {
            initRenderer()
        }
        if let renderer = renderer {
            renderer.updateResources()
        }
    }
    
}