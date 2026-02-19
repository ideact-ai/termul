//
//  main.swift
//  Termul
//
//  Main entry point for Service Helper application
//

import Cocoa

// Main entry point for the application
// This code initializes the app, sets up the delegate, and starts the run loop

// Create shared application instance
let app = NSApplication.shared

// Create and set the app delegate
let appDelegate = AppDelegate()
app.delegate = appDelegate

// Configure app as menu bar accessory (no dock icon)
app.setActivationPolicy(.accessory)

// Activate the app
app.activate(ignoringOtherApps: true)

// Run the application (blocking call)
app.run()
