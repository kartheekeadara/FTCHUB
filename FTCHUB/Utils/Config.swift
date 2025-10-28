//
//  Config.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct Config {
    // TODO: Replace with your actual Supabase credentials
    // Get these from Supabase Dashboard > Settings > API
    static let supabaseURL = "https://jijephhwqdhzrjmrxhhz.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppamVwaGh3cWRoenJqbXJ4aGh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1Mjc3OTMsImV4cCI6MjA3NzEwMzc5M30.-sKUfbLlkzkr5v20Tpa-pXSLBmgPBmCqcj8OP55PVyM"
    
    // TODO: Replace with your Google OAuth Client ID
    // Get this from Google Cloud Console
    static let googleClientID = "YOUR_GOOGLE_CLIENT_ID"
    
    // App configuration
    static let appName = "FTC Team Hub"
    static let minimumIOSVersion = "16.0"
    
    // API endpoints
    static let baseURL = supabaseURL
    static let apiVersion = "v1"
}
