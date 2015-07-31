//
//  Security.swift
//  Thoth
//
//  Created by Simon Rodriguez on 30/07/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation



func openKeychain(server: String?) -> Keychain? {
    if let server = server {
        let URL = NSURL(string: "sftp://" + server)!
        var keychain = Keychain(server: URL, protocolType: .SSH)
        //keychain = keychain.service(server)
        keychain = keychain.label("Thoth")
        
        return keychain
    } else {
         println("Error : unknown server adress")
    }
    return nil
}

func registerUser( _name: String, forServer server: String?, password: String)-> Bool{
    if let keychain = openKeychain(server) {
        if let error = keychain.set(password, key: _name){
          //  println("error: \(error.localizedDescription)")
        } else {
            return true
        }
    }
    return false
}

func updateUser( _name: String, forServer server: String?, password: String)-> Bool{
    
    if let keychain = openKeychain(server) {
        if let error = keychain.set(password, key: _name){
          //  println("error: \(error.localizedDescription)")
        } else {
            return true
        }
    }
    return false
}

func removeUser( _name: String, forServer server: String?)-> Bool{
    if let keychain = openKeychain(server) {
        if let error = keychain.remove(_name){
         //   println("error: \(error.localizedDescription)")
        } else {
            return true
        }
    }
    return false
}

func retrievePasswordForUser( _name: String, andServer server: String?)-> String{
    if let keychain = openKeychain(server), key = keychain.getString(_name){
       return key
    }
    return ""
}


