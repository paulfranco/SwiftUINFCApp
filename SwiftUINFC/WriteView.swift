//
//  WriteView.swift
//  SwiftUINFC
//
//  Created by Paul Franco on 4/4/21.
//

import SwiftUI

struct WriteView : View {
    @State var record = ""
    @State private var selection = 0
    
    @Binding var isActive: Bool
    
    var sessionWrite = NFCSessionWrite()
    var recordType = [Payload(type: .text, pickerMsg: "Text"), Payload(type: .url, pickerMsg: "URL")]
    
    var body : some View {
        
        Form {
            Section {
                TextField("Message here...", text: self.$record)
            }
            
            Section {
                Picker(selection: self.$selection, label: Text("Pick a record type")) {
                    ForEach(0..<self.recordType.count) {
                        Text(self.recordType[$0].pickerMsg)
                    }
                }
            }
            
            Section {
                Button(action: {
                    self.sessionWrite.begginScanning(message: self.record, recordType: self.recordType[self.selection].type)
                }) {
                    Text("Write")
                }
            }
        }
        .navigationTitle("NFC Write")
    }
}


