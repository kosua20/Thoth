//
//  Manager.swift
//  Siblog
//
//  Created by Simon Rodriguez on 07/02/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation



  ///This class manages the upload functionnalities of the program and the initialisation of more specialised classes for loading and rendering the articles.


class Manager {
    
    
    
    // MARK: Properties
    
    /// The path to the folder containing the configuration file
    let rootPath : String
    
    /// The configuration object for the current Manager instance
    let config : Config
    
    /// The Loader object for the current instance, will load the articles from disk.
    var loader : Loader?
    
    /// The Renderer for the current instance, will render the articles to disk.
    var renderer : Renderer?
    
    /// The object managing the SFTP connection
    var ftpServer : NMSFTP?
    
    /// A string representing the domain adress of the FTP
    let ftpAdress : String
    
    /// A string representing the distant path to the destination folder on the FTP
    let ftpPath : String
    
    
    
    // MARK: Initialisation methods
    
    
    ///Initalisation method
    ///
    ///:param: rootPath      the path to the local directory containing the config file
    ///:param: configuration a Configuration object for the current instance of the program
    ///
    
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
    
    
    /**
    Initialises the Renderer for the current configuration and rootpath
    */
    
    func initRenderer(){
        self.loader = Loader(folderPath: config.articlesPath, defaultAuthor: config.defaultAuthor, dateStyle:config.dateStyle)
        //println("Loader loaded")
        self.loader!.sortArticles()
        //println("Articles sorted")
        //println("Option : \(option)")
        self.renderer = Renderer(articles: self.loader!.articles, articlesPath: config.articlesPath, exportPath: config.outputPath, rootPath: rootPath, templatePath:config.templatePath, defaultWidth:config.imageWidth, blogTitle: config.blogTitle, imagesLink : config.imagesLinks, siteRoot: config.siteRoot)
        //println("Renderer rendered")
    }
    
    
    /**
     Initialises the SFTP session for the current configuration and rootpath
    
    :returns: a boolean denoting the success or failure of the connection
    */
    
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
    
    
    
    // MARK: Rendering
  
    /**
    Calls the Renderer with the correct settings
    
    :param: option the mode in which the Renderer should run
    */
    
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
    
    
    /**
    Regenerates the index page
    */
    
    func index() {
        if renderer == nil {
            initRenderer()
        }
        if let renderer = renderer {
            renderer.updateIndex()
        }
    }
    
    
    /**
    Regenerates the resources folder
    */
    
    func resources(){
        if renderer == nil {
            initRenderer()
        }
        if let renderer = renderer {
            renderer.updateResources()
        }
    }
    
    
    
    
    // MARK: Uploading
   
    /**
    Uploads the generated content to the SFTP server designated in the Configuration.
    
    :param: option the mode in which the upload should happen
    */
    
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
    
    
    /**
    Deletes the element passed as parameter if it exists on the server
    
    :param: distantPath The path of the element to delete on the server
    */
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
    
    
    /**
    Uploads the file or folder stored at the given local path.
    
    :param: path  the local path pointing to the element to upload
    :param: force indicates if an already existing element on the server should be replaced
    
    :returns: a boolean denoting the success of the whole operation
    */
    
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
    
    
    
    // MARK: Misc.
    
    /**
    Tests the connection to the SFTP
    */
    
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
    
}