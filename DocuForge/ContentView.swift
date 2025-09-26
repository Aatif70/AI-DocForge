//
//  ContentView.swift
//  DocuForge
//
//  Created by Aatif Ahmed on 5/11/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        WelcomeView()
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
