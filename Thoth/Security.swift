//
//  Security.swift
//  Thoth
//
//  Created by Simon Rodriguez on 30/07/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

/// This class static functions handle the security interactions with the OS X Keychain.
class Security {
    /**
     Opens the keychain record associated with the given SFTP adress.
     
     - parameter server: the string URL of the SFTP server Thoth wants to use
     
     - returns: an opened Keychain if the operation is successful, nil else
     */
    class func openKeychain(_ server: String?) -> Keychain? {
        if let server = server {
            let URL = Foundation.URL(string: "sftp://" + server)!
            var keychain = Keychain(server: URL, protocolType: .ssh)
            //keychain = keychain.service(server)
            keychain = keychain.label("Thoth")
            
            return keychain
        } else {
             print("Error : unknown server adress")
        }
        return nil
    }

    /**
     Creates and registers a new record (server,name,password) in the OS X Keychain.
     
     - parameter _name:    the SFTP username
     - parameter server:   the SFTP server string URL
     - parameter password: the password associated to the given server and username
     
     - returns: a boolean denoting the success of the operation
     */
    class func registerUser( _ _name: String, forServer server: String?, password: String)-> Bool{
        if let keychain = Security.openKeychain(server) {
            do {
                try keychain.set(password, key: _name)
                return true
            } catch _ {
                 //  println("error: \(error.localizedDescription)")
            }
        }
        return false
    }

    /**
     Updates the record associated with the given arguments in the OS X Keychain.
     
     - parameter _name:    the SFTP username
     - parameter server:   the SFTP server string URL
     - parameter password: the password associated to the given server and username
     
     - returns: a boolean denoting the success of the operation
     */
    class func updateUser( _ _name: String, forServer server: String?, password: String)-> Bool{
        
        if let keychain = Security.openKeychain(server) {
            do {
                try keychain.set(password, key: _name)
                return true
            } catch _ {
                 //  println("error: \(error.localizedDescription)")
            }
        }
        return false
    }

    /**
     Removes the record associated with the given arguments in the OS X Keychain.
     
     - parameter _name:  the SFTP username
     - parameter server: the SFTP server string URL
     
     - returns: a boolean denoting the success of the operation
     */
    class func removeUser( _ _name: String, forServer server: String?)-> Bool{
        if let keychain = Security.openKeychain(server) {
            do {
                try keychain.remove(_name)
                return true
            } catch _ {
                //   println("error: \(error.localizedDescription)")
            }
        }
        return false
    }

    /**
     Read the password from the record associated with the given arguments in the OS X Keychain.
     
     - parameter _name:  the SFTP username
     - parameter server: the SFTP server string URL
     
     - returns: the password for the given server and username
     */
    class func retrievePasswordForUser( _ _name: String, andServer server: String?)-> String{
        if let keychain = Security.openKeychain(server), let key = try? keychain.getString(_name){
            if let key = key {
                return key
            }
        }
        return ""
    }


}


