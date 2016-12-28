//
//  main.swift
//  Siblog
//
//  Created by Simon Rodriguez on 25/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

/**
 The general main loop of Thoth
 
 - parameter args: the arguments passed at launch
 */
func main(_ args : [String] = []){
    //println(Process.arguments)
    var args = CommandLine.arguments
    if args.count > 1 {
        args.remove(at: 0)
        mainSwitch(args)
        exit(0)
    } else {
        mainLoop()
    }
}




/**
The main loop of the program in interactive command-line mode
*/

func mainLoop() {
    print("Welcome in {#Thoth}, a static blog generator.")
    let prompt: Prompt = Prompt(argv0: CommandLine.unsafeArgv[0])
    while true {
        if let input1 = prompt.gets() {
            var input2 = input1.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            input2 = input2.replacingOccurrences(of: "\\ ", with: "{#PLAC3HO£D€R$}", options: [], range: nil)
            var args = input2.components(separatedBy: " ")
            /*
            arg[0] : command
            arg[1] : path
            arg[2],... : options
            */
            args = args.filter({
                (x : String) -> Bool in
                !x.isEmpty
            })
            args = args.map({
                (x : String) -> String in
                x.replacingOccurrences(of: "{#PLAC3HO£D€R$}", with: "\\ ", options: [], range: nil)
            })
            
            mainSwitch(args)
        } else {
            print("Error : Null input")
        }
    }
}



/**
	Called when executing thoth with launch arguments

	- parameter args: an array of arguments
*/



func mainSwitch(_ args : [String]) {
    var args = args
    if args.count > 1 {
        switch args[0] {
        case "setup":
            if !FileManager.default.fileExists(atPath: args[1]) {
                do {
                    try FileManager.default.createDirectory(atPath: args[1], withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
            let _ = ConfigLoader.generateConfigFileAtPath(args[1])
            let folders = ["articles","template","output","resources"] as [String]
            for folder in folders {
                if !FileManager.default.fileExists(atPath: args[1].stringByAppendingPathComponent(folder)){
                    do {
                        try FileManager.default.createDirectory(atPath: args[1].stringByAppendingPathComponent(folder), withIntermediateDirectories: true, attributes: nil)
                    } catch _ {
                    }
                }
            }
            print("The blog is now set up\nUse the command\nthoth password /path/to/blog/folder -set \"YourPassw0rd\"\nto register it.")
        case "check":
            if let config = loadConfigurationFromPath(args[1]) {
                print("The config file seems ok")
                let man = Manager(rootPath: args[1], configuration: config)
                man.runTest()
            }
        case "draft":
            if let config = loadConfigurationFromPath(args[1]) {
                let man = Manager(rootPath: args[1], configuration: config)
                if(args.count > 2){
                    let subArgs = args[2..<args.count]
                    let fullTitle = subArgs.joined(separator: " ")
                    man.createDraft(fullTitle)
                } else {
                    let dateF = DateFormatter()
                    dateF.dateFormat = config.dateStyle
                    man.createDraft("Draft_\(dateF.string(from: Date()))")
                }
                
            }
        case "password":
            if let config = loadConfigurationFromPath(args[1]){
                if args.count > 2 {
                    switch args[2]{
                        case "-remove", "-r", "--r":
                            let _ = Security.removeUser(config.ftpUsername, forServer: config.ftpAdress.pathComponents.first)
                        case "-update", "-u", "--u":
                            if args.count > 3 {
                                let _ = Security.updateUser(config.ftpUsername, forServer: config.ftpAdress.pathComponents.first, password: args[3])
                            } else {
                                print("No password specified")
                            }
                        case "-set", "-s", "--s":
                            if args.count > 3 {
                               let _ =  Security.registerUser(config.ftpUsername, forServer: config.ftpAdress.pathComponents.first, password: args[3])
                            } else {
                                print("No password specified")
                            }
                       
                    default:
                        print("Unknow option")
                    }
                }
            }
        case "index","resources","first","upload","scribe","generate":
            if let config = loadConfigurationFromPath(args[1]) {
                let man = Manager(rootPath: args[1], configuration: config)
                switch args[0] {
                case "index":
                    man.index()
                case "resources":
                    man.resources()
                case "first":
                    man.generate(3)
                    man.upload(3)
                case "generate":
                    args.removeSubrange(0..<2)
                    if let option = interprateArguments(args) {
                        man.generate(option)
                    }
                case "upload":
                    args.removeSubrange(0..<2)
                    if let option = interprateArguments(args) {
                        man.upload(option)
                    }
                case "scribe":
                    args.removeSubrange(0..<2)
                    if let option = interprateArguments(args) {
                        man.generate(option)
                        man.upload(option)
                    }
                default:
                    break
                }
            }
            
        default:
            //Case where the only arguments are the path to a config file and a modulator.
            if FileManager.default.fileExists(atPath: args[0]) {
                let potentialPath = args[0]
                if let config = loadConfigurationFromPath(potentialPath) {
                    args.remove(at: 0)
                    if let option = interprateArguments(args){
                        let man = Manager(rootPath: potentialPath, configuration: config)
                        man.generate(option)
                        man.upload(option)
                    }
                }
            } else {
                print("Unknown command. Type \"help\" to get a list of available commands.")
            }
            break
        }
    } else if args.count == 1 {
        //Commands with no arguments except the command name
        switch args[0] {
        case "help":
            printHelp()
        case "exit":
            exit(0)
        case "ibis":
            printBonus()
        case "version","-version","-v","--version","--v":
            printVersion()
        case "license","licenses","licence","licences":
            printLicense()
        case "setup","chech","index","resources","first","upload","scribe","generate":
            print("Missing argument. Type \"help\" to get a list of available commands.")
        default:
            //Case where the only argument is the path to a config file.
            if FileManager.default.fileExists(atPath: args[0]) {
                let potentialPath = args[0]
                if let config = loadConfigurationFromPath(potentialPath) {
                    args.remove(at: 0)
                    if let option = interprateArguments(args){
                        let man = Manager(rootPath: potentialPath, configuration: config)
                        man.generate(option)
                        man.upload(option)
                    }
                }
            } else {
                print("Unknown command. Type \"help\" to get a list of available commands.")
            }
        }
    } else {
        print("Empty command. Type \"help\" to get a list of available commands.")
    }
}



/**
	Detects the modulating arguments, and return a value corresponding to the right mode.

	- parameter args: an array of arguments

	- returns: an integer representing the mode
*/

func interprateArguments(_ args : [String]) -> Int? {
    //No arguments provided -> default : 0
    if args.count == 0 { return 0 }
    var option = 0
    for i in 0..<args.count {
        switch args[i]{
        case "-a","--a","--articles":
            option = 1
        case "-d","--d","--drafts":
            option = 2
        case "-f","--f","--full":
            option = 3
        default:
            print("Unknown argument: \(args[i])")
            return nil
        }
    }
    return option
}


/**
	Loads a configuration file in memory

	- parameter rootPath: rootPath a String representing the path to the folder containing the config file

	- returns: the Config object corresponding to the config file
*/
func loadConfigurationFromPath(_ rootPath : String)-> Config? {
    if FileManager.default.fileExists(atPath: rootPath) {
        if FileManager.default.fileExists(atPath: rootPath.stringByAppendingPathComponent("config")) {
            return ConfigLoader.loadConfigFileAtPath(rootPath.stringByAppendingPathComponent("config"))
            
        } else {
            print("No config file found in the designated directory.")
        }
    } else {
        print("The folder at path \(rootPath) doesn't exist.")
    }
    return nil
}



/**
	Displays the help text
*/
func printHelp(){
    let s = "setup <path>\tCreates the configuration files and folders (articles, template, output, ressources) in the indicated directory.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory where the configurations files and folders  should be created.\n\n"
        + "first <path>\tRuns the first generation/upload of the site\n\t\t"
        + "Argument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate\n\n"
        + "generate <path> [-a|-d|-f]  Generates the site in the specified ouput folder. All existing files are kept.\n"
        + "\t\tDrafts are updated. New articles are added. Index is rebuilt.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate\n"
        + "\t\tOptions:\n"
        + "\t\t-a rebuilds articles only\n"
        + "\t\t-d rebuilds drafts only\n"
        + "\t\t-f forces to rebuild everything\n\n"
        + "upload <path> [-a|-d|-f]  Upload the content of the site to the FTP set in the config file\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate\n"
        + "\t\tOptions:\n"
        + "\t\t-a uploads articles only\n"
        + "\t\t-d uploads drafts only\n"
        + "\t\t-f uploads everything (Warning: the content of the ftp directory where the site content is put will be deleted)\n\n"
        + "scribe <path> [-a|-d|-f]  Combines \"generate\" and \"upload\" with the corresponding path and option\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate and upload\n\n"
        + "password <path> (-set|-update|-remove) \"password\"  Manage the password of the SFTP account, stored in the OSX user Keychain\n"
        + "\t\tArguments:\n"
        + "\t\t<path> points to the directory containing the config file of the site to manage\n"
        + "\t\t-set: creates a keychain entry to store the password associated with the configured SFTP account\n"
        + "\t\t-update: updates the keychain entry with the new password value\n"
        + "\t\t-remove: deletes the keychain entry associated with the configured SFTP account\n"
        + "\t\t\"password\" value of the password, needed when using the -set and -update options\n\n"
        + "index <path>\tRegenerates the index.html file.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file\n\n"
        + "resources <path>  Rebuilds the resources directory.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file\n\n"
        + "draft <path> (title)\tGenerate a draft markdown file in the 'articles' directory of the given blog.\n"
        + "\t\tArguments:\n"
        + "\t\t<path> points to the directory containing the config file\n"
        + "\t\ttitle the title of the draft file. Spaces are allowed. (optional, by default uses the current date.)\n\n"
        + "check <path>\tChecks the configuration file.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file\n\n"
        + "help\t\tDisplays this help text\n\n"
        + "--version\t\tDisplays the current Thoth version\n\n"
        + "license\t\tDisplays the license text\n\n"
        + "exit\t\tQuits the program"
    print(s)
}



/**
	Displays the version number.
*/

func printVersion(){
    print("{#Thoth} version 1.3.3")
}



/**
	Displays the license text.
*/

func printLicense(){
    print("===============================================================\n{#Thoth}\n===============================================================\nCopyright (c) 2015, Simon Rodriguez\nAll rights reserved.\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n\nContact : contact@simonrodriguez.fr - simonrodriguez.fr\n\n===============================================================\n{#Thoth} uses some third-party components and libraries.\nTheir licenses and copyright notices are displayed here.\n\n===============================================================\nMarkingbird - Markdown.swift\n===============================================================\nCopyright (c) 2014 Kristopher Johnson\n\nPermission is hereby granted, free of charge, to any person obtaining\na copy of this software and associated documentation files (the\n\"Software\"), to deal in the Software without restriction, including\nwithout limitation the rights to use, copy, modify, merge, publish,\ndistribute, sublicense, and/or sell copies of the Software, and to\npermit persons to whom the Software is furnished to do so, subject to\nthe following conditions:\n\nThe above copyright notice and this permission notice shall be\nincluded in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\nMERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND\nNONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE\nLIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION\nOF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION\nWITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\nMarkdown.swift is based on MarkdownSharp, which is based on earlier\nMarkdown implementations.\n\n===============================================================\nswift-libedit\n===============================================================\nCopyright (c) 2014, Neil Pankey\nhttps://github.com/neilpa/swift-libedit\n\n===============================================================\nNMSSH\n===============================================================\nCopyright (c) 2013 Nine Muses AB\nAll rights reserved.\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\nhttps://github.com/Lejdborg/NMSSH\n\n===============================================================\nKeychainAccess\n===============================================================\nCopyright (c) 2014 kishikawa katsumi\n\nThe MIT License (MIT) - Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: \nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\nhttps://github.com/kishikawakatsumi/KeychainAccess\n")
}



/**
	A mysterious function...
*/

func printBonus(){
    print("                                                         \n                                                         \n                        ,,,,,,,,,,                       \n                  ,yQQQQQQQQQQQQQQQQQQyQ                 \n               yQQQQRR^ ..       .``RWQQQQQ,             \n            ,QQQ#R    ,yyy,             \"WQQQQ           \n          ,QQQR^  ,,@R` , 7Q               \"@QQQ         \n         QQQR,y#RR`,,      @Q                `QQQQ       \n       ,QQQR@QyQRR^`7RQQ   ]Q                  YQQQ      \n     ,#RQgRRT.        ]#  ,Qh                   1QQQ     \n   ,#QQQQ~           ,#. y#^                     @QQQ    \n  ]Q#@QQL           y#  #R                        QQQ    \n   . QQQ           @R yR`                         @QQm   \n     QQQ         ,QL @R                           ]QQQ   \n     QQQ        ,Q` @L                            @QQM   \n     ]QQQ       Q. ]Q           ,,yyyyyy,,        QQQ    \n      QQQ       Q   QQ    ,yQQQRRRRRRRW@QQQRRQ,  {QQR    \n      4QQQ       @Q  ^RRR`@R^.           '7R@yQRQQQ#     \n       1QQQ       ?Q,     @y,                .`@QQ#      \n        \"QQQy       ?WRRQy,.`RWRQQyy,,,      ,QQQR       \n          KQQQy           `RQQ     ..^QQRRRQQQQE         \n            KQQQQQ           `RQy,,,,  KQgQQQRV          \n              `RQQQQQQ,           `]Q@QQQQRT             \n                  \"WQQQQQQQQQQQQQQQQQQRR^                \n                        `\"RRRRRRRR^.                     \n                                                         \n                                                         \n                                                         \n")
}

// MARK: - Extension of String
extension String {
    
    /// Returns the last path component of the string
    var lastPathComponent: String {
         get {
            return (self as NSString).lastPathComponent
        }
    }
    
    /// Returns the file extension component of the string
    var pathExtension: String {
        get {
            return (self as NSString).pathExtension
        }
    }
    
    /// Returns a copy of the string where the last path component has been deleted
    var stringByDeletingLastPathComponent: String {
        
        get {
            
            return (self as NSString).deletingLastPathComponent
        }
    }
    /// Returns a copy of the string where the file extension component has been deleted
    var stringByDeletingPathExtension: String {
        
        get {
            
            return (self as NSString).deletingPathExtension
        }
    }
    /// Returns an array containing the path components of the string
    var pathComponents: [String] {
        
        get {
            
            return (self as NSString).pathComponents
        }
    }
    /**
     Appends the argument to the current string to generate a new string path.
     
     - parameter path: the path component to append
     
     - returns: a copy of the string where the new path component has been appended
     */
    func stringByAppendingPathComponent(_ path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathComponent(path)
    }

}
main()



