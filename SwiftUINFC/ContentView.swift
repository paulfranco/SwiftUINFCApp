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
    @State var showWrite = false
    let holder = "Read Msg will display here"
    
    var body: some View {
        NavigationView {
            // MARK: - Geometry Reader
            GeometryReader { reader in
                // MARK: - VStack
                VStack(spacing: 30) {
                    // MARK: - ZStack
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 4)
                            )
                        Text(self.data.isEmpty ? self.holder : self.data)
                            .foregroundColor(self.data.isEmpty ? .gray : .black)
                            .padding()
                    }.frame(height: reader.size.height * 0.4)
                    
                    // Read Button
                    nfcButton(data: self.$data)
                        .frame(height: reader.size.height * 0.07)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Write Button
                    NavigationLink(destination: WriteView(isActive: self.$showWrite), isActive: self.$showWrite) {
                        Button(action: {
                            self.showWrite.toggle()
                        }) {
                            Text("Write to NFC")
                                .frame(width: reader.size.width * 0.9, height: reader.size.height * 0.07)
                        }
                        .foregroundColor(.white)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    Spacer()
                    
                    
                }.frame(width: reader.size.width * 0.9)
                .navigationBarTitle("NFC App", displayMode: .inline)
                .padding(.top, 20)
                .padding(.leading, 20)
                
            }
        }
    }
}

enum RecordType {
    case text, url
}

class NFCSessionWrite : NSObject, NFCNDEFReaderSessionDelegate {
    
    var session: NFCNDEFReaderSession?
    var message = ""
    var recordType: RecordType = .text
    
    func begginScanning(message: String, recordType: RecordType) {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("Scanning not supported for this device")
            return
        }
        self.message = message
        self.recordType = recordType
        
        session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your phone near an NFC tag to write message"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Do nothing here unless you want to implement error
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Do nothing here
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // This is to silence the console
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // check if more than 1 tag has been found
        if tags.count > 1 {
            // restart session
            let retryInterval = DispatchTimeInterval.milliseconds(2000)
            session.alertMessage = "More than 1 tags has been detected. Remove all other tags and try again"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
            return
        }
        
        let tag = tags.first!
        print("First Tag detected")
        session.connect(to: tag) { (error) in
            if let error = error {
                session.alertMessage = "Unable to connect to the tag"
                session.invalidate()
                print("Error while connecting")
                return
            }
            
            // Query the tag
            tag.queryNDEFStatus { (ndefStatus, capacity, error) in
                if error != nil {
                    session.alertMessage = "Unable to query the NFC tag"
                    session.invalidate()
                    print("Error querying the tag")
                    return
                }
                // proceed to query
                switch ndefStatus {
                case .notSupported:
                    print("Not Supported")
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                case .readWrite:
                    // Write code logic
                    print("Read/Write")
                    let payLoad: NFCNDEFPayload?
                    switch self.recordType {
                    case .text:
                        guard !self.message.isEmpty else {
                            session.alertMessage = "Empty Data"
                            session.invalidate(errorMessage: "Empty text data")
                            return
                        }
                        payLoad = NFCNDEFPayload(format: .nfcWellKnown, type: "T".data(using: .utf8)!, identifier: "Text".data(using: .utf8)!, payload: self.message.data(using: .utf8)!)
                    case .url:
                        // make sure its an actual url
                        guard let url = URL(string: self.message) else {
                            print("Not a calid URL")
                            session.alertMessage = "Invalid URL"
                            session.invalidate(errorMessage: "Data is not a valid url")
                            return
                        }
                        
                        payLoad = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
                    }
                    
                    // make our message array
                    let nfcMessage = NFCNDEFMessage(records: [payLoad!])
                    // write to tag
                    tag.writeNDEF(nfcMessage) { (error) in
                        if error != nil {
                            session.alertMessage = "Write NDEF fail: \(error!.localizedDescription)"
                            print("Write fail: \(error!.localizedDescription)")
                        } else {
                            session.alertMessage = "Write was successful"
                            print("successful write")
                        }
                        session.invalidate()
                    }
                case .readOnly:
                    print("Read Only")
                    session.alertMessage = "Tag is read only"
                    session.invalidate()
                @unknown default:
                    print("Unknown Error")
                    session.alertMessage = "Unknown tag status"
                    session.invalidate()
                }
            }
        }
        
    }
    
}

struct Payload {
    var type: RecordType
    var pickerMsg: String
}

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
//        .navigationBarItems(leading: Button(action: {
//            self.isActive.toggle()
//        }) {
//            HStack(spacing: 5) {
//                Image(systemName: "chevron.left")
//                Text("back")
//            }
//        })
    }
}

struct nfcButton : UIViewRepresentable {
    @Binding var data: String
    
    func makeUIView(context: UIViewRepresentableContext<nfcButton>) -> UIButton {
        let button = UIButton()
        button.setTitle("Read NFC", for: .normal)
        button.backgroundColor = UIColor.black
        button.addTarget(context.coordinator, action: #selector(context.coordinator.beginScan(_:)), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: UIViewRepresentableContext<nfcButton>) {
        // Do nothing
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
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
}
