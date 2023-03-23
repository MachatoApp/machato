//
//  GumroadLicenseInput.swift
//  Machato
//
//  Created by Théophile Cailliau on 14/04/2023.
//
#if !MAS
import SwiftUI

struct GumroadLicenseInput: View {
    
    @State var part1: String = "";
    @State var part2: String = "";
    @State var part3: String = "";
    @State var part4: String = "";
    @FocusState var part1focused: Bool;
    @FocusState var part2focused: Bool;
    @FocusState var part3focused: Bool;
    @FocusState var part4focused: Bool;
    @Binding var license_key : String;
    
    var body: some View {
        HStack(spacing: 0) {
            TextField("", text: $part1).font(.body.monospaced()).focused($part1focused, equals: true)
            Text("-")
            TextField("", text: $part2).font(.body.monospaced()).focused($part2focused, equals: true)
            Text("-")
            TextField("", text: $part3).font(.body.monospaced()).focused($part3focused, equals: true)
            Text("-")
            TextField("", text: $part4).font(.body.monospaced()).focused($part4focused, equals: true)
        }.onChange(of: part1) { nv in
            part1.replace(#/[^A-Za-z0-9]/#, with: "")
            part1.replace(#/[a-z]/#) {m in
                return String(part1[m.range]).uppercased()
            }
            updateLicenseKey()
        }.onChange(of: part2) { nv in
            part2.replace(#/[^A-Za-z0-9]/#, with: "")
            part2.replace(#/[a-z]/#) {m in
                return String(part2[m.range]).uppercased()
            }
            updateLicenseKey()
        }.onChange(of: part3) { nv in
            part3.replace(#/[^A-Za-z0-9]/#, with: "")
            part3.replace(#/[a-z]/#) {m in
                return String(part3[m.range]).uppercased()
            }
            updateLicenseKey()
        }.onChange(of: part4) { nv in
            part4.replace(#/[^A-Za-z0-9]/#, with: "")
            part4.replace(#/[a-z]/#) {m in
                return String(part4[m.range]).uppercased()
            }
            updateLicenseKey()
        } .onAppear() {
            if license_key.count == 8*4+3 {
                part1 = String(license_key[license_key.index(license_key.startIndex, offsetBy: 0)..<license_key.index(license_key.startIndex, offsetBy: 8)])
                part2 = String(license_key[license_key.index(license_key.startIndex, offsetBy: 9)..<license_key.index(license_key.startIndex, offsetBy: 17)])
                part3 = String(license_key[license_key.index(license_key.startIndex, offsetBy: 18)..<license_key.index(license_key.startIndex, offsetBy: 26)])
                part4 = String(license_key[license_key.index(license_key.startIndex, offsetBy: 27)..<license_key.index(license_key.startIndex, offsetBy: 35)])
            }
        }
    }
    
    func updateLicenseKey() {
        if part1.count == 8 && part1focused == true {
            part2focused = true
        }
        if part2.count == 8 && part2focused == true {
            part3focused = true
        }
        if part3.count == 8 && part3focused == true {
            part4focused = true
        }
        if part1.count > 8 {
            part2 = String(part1[part1.index(part1.startIndex, offsetBy: 8)..<part1.endIndex])
            part1 = String(part1[part1.startIndex..<part1.index(part1.startIndex, offsetBy: 8)])
        }
        if part2.count > 8 {
            part3 = String(part2[part2.index(part2.startIndex, offsetBy: 8)..<part2.endIndex])
            part2 = String(part2[part2.startIndex..<part2.index(part2.startIndex, offsetBy: 8)])
        }
        if part3.count > 8 {
            part4 = String(part3[part3.index(part3.startIndex, offsetBy: 8)..<part3.endIndex])
            part3 = String(part3[part3.startIndex..<part3.index(part3.startIndex, offsetBy: 8)])
        }
        if part4.count > 8 {
            part4 = String(part4[part4.startIndex..<part4.index(part4.startIndex, offsetBy: 8)])
        }
        license_key = part1 + "-" + part2 + "-" + part3 + "-" + part4
        if license_key.count == 8*4+3 {
            part4focused = true
        }
    }
    
    init(key: Binding<String>) {
        _license_key = key
    }
}
#endif
