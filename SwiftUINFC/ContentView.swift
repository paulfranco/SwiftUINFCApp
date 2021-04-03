//
//  ContentView.swift
//  SwiftUINFC
//
//  Created by Paul Franco on 4/2/21.
//

import SwiftUI
import CoreNFC

struct ContentView: View {
    @State var data = ""
    var body: some View {
        VStack {
            Text(data)
                .padding()
            nfcButton(data: self.$data)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct nfcButton : UIViewRepresentable {
    @Binding var data: String
    
    func makeUIView(context: UIViewRepresentableContext<nfcButton>) -> UIButton {
        let button = UIButton()
        button.setTitle("Read NFC", for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(context.coordinator, action: #selector(context.coordinator.beginScan(_:)), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: UIViewRepresentableContext<nfcButton>) {
        <#code#>
    }
    
    func makeCoordinator() -> nfcButton.Coordinator {
        return Coordinator(data: $data)
    }
    
    
    class Coordinator : NSObject, NFCNDEFReaderSessionDelegate {
        
        var session: NFCNDEFReaderSession?
        @Binding var data: String
        
        init(data: Binding<String>) {
            _data = data
        }
        
        @objc func beginScan(_ sender: Any) {
            guard NFCNDEFReaderSession.readingAvailable else {
                print("error: Scanning not supported")
                return
            }
            
            session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
            session?.alertMessage = "Hold your phone near the tag to scan"
            session?.begin()
        }
        
        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            if let readerError = error as? NFCReaderError {
                if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                    print("Error nfc read: \(readerError.localizedDescription)")
                }
            }
            
            self.session = nil
        }
        
        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            guard
                let nfcMessage = messages.first,
                let record = nfcMessage.records.first, record.typeNameFormat == .absoluteURI || record.typeNameFormat == .nfcWellKnown,
                let payload = String(data: record.payload, encoding: .utf8)
            else {
                return
            }
            print(payload)
            self.data = payload
        }
        
        
    }
}
