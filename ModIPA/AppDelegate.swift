//
//  AppDelegate.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // Called when the application finishes launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching.")
        // Initialize global configurations or resources here if needed
    }

    // Called when the application is about to terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        print("Application will terminate.")
        // Clean up resources or perform final tasks here
    }

    // Ensures the application terminates when the last window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
