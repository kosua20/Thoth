//
//  Manager.swift
//  Siblog
//
//  Created by Simon Rodriguez on 07/02/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

import NMSSH

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
    ///- parameter rootPath:      the path to the local directory containing the config file
    ///- parameter configuration: a Configuration object for the current instance of the program
    ///
    
    init(rootPath : String, configuration : Config){
        // println("Initializing the manager...")
        self.rootPath = rootPath
        self.config = configuration
        self.loader = nil
        self.renderer = nil
        
        //Bit of string refactoring for simpler access with NMSSH
        var pathscomp = config.ftpAdress.pathComponents
        self.ftpAdress = pathscomp.remove(at: 0)
        self.ftpPath = pathscomp.joined(separator: "/").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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
    
    - returns: a boolean denoting the success or failure of the connection
    */
    
    func initSession() -> Bool{
        print("SFTP:\tConnecting to the server...\t")
        NMSSHLogger.shared().isEnabled = false
        let session = NMSSHSession.connect(toHost: self.ftpAdress, port: config.ftpPort, withUsername: config.ftpUsername)
        if (session?.isConnected)! {
            session?.authenticate(byPassword: config.ftpPassword)
            
        }
        if (session?.isConnected)! && (session?.isAuthorized)! {
            ftpServer = NMSFTP.connect(with: session)
            return true
        } else {
            print("Error when connecting to SFTP server")
            ftpServer = nil;
            return false
        }
    }
    
    
    
    // MARK: Rendering
  
    /**
    Calls the Renderer with the correct settings
    
    - parameter option: the mode in which the Renderer should run
    */
    
    func generate(_ option : Int) {
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
            print("Generation done !")
        } else {
            print("Error with the renderer")
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
    
    - parameter option: the mode in which the upload should happen
    */
    func upload(_ option : Int = 0){
        if (ftpServer == nil){
            if !initSession(){
                return
            }
        }
        //From here, we can force unwrap ftpServer without risk
        
        print("\tBeginning upload to \(ftpAdress)...\t")
        var succeeded = true
        switch option {
        case 1:
            succeeded = succeeded && uploadElementAtPath("articles", force: true)
            succeeded = succeeded && uploadElementAtPath("index.html", force: true)
            succeeded = succeeded && uploadElementAtPath("feed.xml", force: true)
            succeeded = succeeded && uploadResources()
        case 2:
            succeeded = succeeded && uploadElementAtPath("drafts", force: true)
            succeeded = succeeded && uploadElementAtPath("index-drafts.html", force: true)
            succeeded = succeeded && uploadResources()
        case 3:
            for element in (try! FileManager.default.contentsOfDirectory(atPath: config.outputPath)) {
                succeeded = succeeded && uploadElementAtPath(element, force: true)
            }
        default:
            succeeded = succeeded && uploadElementAtPath("drafts", force: true)
            succeeded = succeeded && uploadElementAtPath("articles", force: false)
            succeeded = succeeded && uploadElementAtPath("index.html", force: true)
            succeeded = succeeded && uploadElementAtPath("feed.xml", force: true)
            succeeded = succeeded && uploadElementAtPath("index-drafts.html",force: true)
            succeeded = succeeded && uploadResources()
        }
        
        if !succeeded {
            print("\tAn error occured during the upload")
        } else {
            print("\tUpload successful !")
        }
        
        ftpServer!.disconnect()
    }
	
	/**
	Upload all elements at the output root that are not articles/drafts/feed/index pages. Relies on the renderer to know if some of these files were modified, to upload them.
	*/
	func uploadResources() -> Bool {
		var succeeded = true
		var remainingFiles = try! FileManager.default.contentsOfDirectory(atPath: config.outputPath)
		remainingFiles = remainingFiles.filter({ $0 != "drafts" && $0 != "articles" })
		remainingFiles = remainingFiles.filter({ $0 != "index.html" && $0 != "feed.xml" && $0 != "index-drafts.html" })
		
		for element in remainingFiles {
			succeeded = succeeded && uploadElementAtPath(element, force: renderer!.dirtyRessources)
		}
		return succeeded
	}
    /**
    Deletes the element passed as parameter if it exists on the server
		
    - parameter distantPath: The path of the element to delete on the server
    */
    fileprivate func cleanElementAtPath(_ distantPath : String) {
        //println("DB: " + distantPath)
        if ftpServer!.fileExists(atPath: distantPath) {
            //println("File exists")
            ftpServer!.removeFile(atPath: distantPath)
        }
        if ftpServer!.directoryExists(atPath: distantPath){
          //  println("Folder exists")
            ftpServer!.removeDirectory(atPath: distantPath)
        }
        //println("Done cleaning")
    }
    
    
    /**
    Uploads the file or folder stored at the given local path.
    
    - parameter path:  the local path pointing to the element to upload
    - parameter force: indicates if an already existing element on the server should be replaced
    
    - returns: a boolean denoting the success of the whole operation
    */
    
    fileprivate func uploadElementAtPath(_ path :  String, force : Bool) -> Bool {
        
       //hack for hidden files
        if path.lastPathComponent.hasPrefix("."){
            return true
        }
        
        var succeeded = true;
        
        //Checking if the file exists locally (else we don't do anything)
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: config.outputPath.stringByAppendingPathComponent(path), isDirectory: &isDir){
            
            let distantPath = ftpPath.stringByAppendingPathComponent(path)
            
            //Cleaning the potentially already existing file on the server
            
            if force {
               // println("Cleaning")
                cleanElementAtPath(distantPath)
            }
            
            if isDir.boolValue { //This is a folder
                //Creating the folder if it doesn't already exist
                //println("Creating directory")
                if !ftpServer!.directoryExists(atPath: distantPath) {
                    ftpServer!.createDirectory(atPath: distantPath)
                }
                
                for file in (try! FileManager.default.contentsOfDirectory(atPath: config.outputPath.stringByAppendingPathComponent(path))) {
                    succeeded = succeeded && uploadElementAtPath(path.stringByAppendingPathComponent(file), force : false)
                }
                
            } else { //This is a file
                //If the file doesn't exists, or if we force (normally it has been cleaned, but let's be careful
                 if !ftpServer!.fileExists(atPath: distantPath) || force {
                   // println("Uploading file...")
                    succeeded = succeeded && ftpServer!.writeFile(atPath: config.outputPath.stringByAppendingPathComponent(path), toFileAtPath: distantPath)
                    
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
        print("Testing SFTP \(ftpAdress)...\t", terminator: "")
        if (ftpServer == nil){
            if !initSession(){
                print("Error when connecting to the server")
                return
            }
        }
        if let ftpServer = ftpServer {
            if ftpServer.isConnected {
                print("Connection to the server is valid.")
                ftpServer.disconnect()
                return
            }
        }
        print("Encountered an error (probably)")
    }
    
    /**
     Creates a draft .md file
     
     - parameter title: the title of the draft file to create
     */
    func createDraft(_ title : String){
        let destinationPath = config.articlesPath.stringByAppendingPathComponent(title.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_").trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) + ".md")
        if  FileManager.default.fileExists(atPath: destinationPath){
            print("Error : file at path \(destinationPath) already exists.")
            return
        }
        do {
            if FileManager.default.fileExists(atPath: config.articlesPath.stringByAppendingPathComponent("#draft.md")){
                try FileManager.default.copyItem(atPath: config.articlesPath.stringByAppendingPathComponent("#draft.md"), toPath: destinationPath)
            } else {
                let content = "#Draft\ndraft\n\(config.defaultAuthor)\n\nThis is a draft.\n"
                FileManager.default.createFile(atPath: destinationPath, contents: content.data(using: String.Encoding.utf8) , attributes: nil)
            }
        } catch _ {
            print("Error when trying to create a draft file in directory \(config.articlesPath) with title \(title).")
        }
    }
    
}
