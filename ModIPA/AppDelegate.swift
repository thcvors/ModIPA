//
//  AppDelegate.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching.")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("Application will terminate.")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
