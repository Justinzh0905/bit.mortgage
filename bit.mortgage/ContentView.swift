//
//  ContentView.swift
//  bit.mortgage
//
//  Created by Justin Zhai on 4/8/23.
//

import Foundation
import SwiftUI
import SwiftSoup

struct ContentView: View {
    @State private var income: Int?
    @State private var incomeSet = false
    @State private var zipcode = ""
    @State private var zipcodeSet = false
    @State private var scoreSelected =  Credit.excellent
    @State private var begun = false
    @State private var rates: [Credit: Double] = [Credit.excellent: 5.980, Credit.veryGood: 6.202, Credit.good: 6.379, Credit.decent: 6.593, Credit.fair: 7.023, Credit.poor: 7.569]
    @State private var creditSet = false
    @FocusState private var isInputActive: Bool
    @State var data: Elements?
    @State var value: String?
    var body: some View {
        VStack {

            
            //logo
            Title()
                .onAppear {
                    Task {
                        data = await parsehtml()
                    }
                }
            Spacer()
    
            ScrollView {
                Spacer()
                
                //start button
                if (!begun) {
                    beginButton(begun: $begun)
                }
                else {
                    
                    //starting prompt
                    Text("let's see what mortgage you can afford")
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Spacer()
                    
                    //income
                    VStack {
                        Text("let's start with your monthly income")

                        TextField("$/month", value: $income, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding()
                            .focused($isInputActive)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    
                                    Button("Done") {
                                        isInputActive = false
                                        withAnimation {
                                            incomeSet = true
                                        }
                                        if zipcode != "" {
                                            withAnimation {
                                                zipcodeSet = true
                                            }
                                            
                                        }
                                    }
                                }
                            }
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                    //zipcode
                    if incomeSet {
                        
                        VStack {
                            Text("It is recommended to spend under 28% of your income on your total housing expenses")
                                .multilineTextAlignment(.center)
                            Spacer()
                            Text("This works out to \(String(format: "$%.2f", (Double(income ?? 0) * 0.28))) per month")
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                        
                        Spacer()
                        
                        VStack {
                            Text("Now let's see what house you can afford based on your other information. Enter your zipcode")
                                .multilineTextAlignment(.center)
                            TextField("zipcode", text: $zipcode)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding()
                                .focused($isInputActive)
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    //credit
                    if zipcodeSet {
                        VStack {
                            Text("what is your credit score?")
                            Picker("credit range", selection: $scoreSelected) {
                                ForEach(Credit.allCases, id: \.self) { score in
                                    Text(score.description)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: scoreSelected) { score in
                                withAnimation {
                                    creditSet = true
                                }
                            }
                            
                            
                            if creditSet {
                                Text("The current average 30 year fixed rate for a credit rating of ")
                                    .multilineTextAlignment(.center)
                                Text(scoreSelected.description)
                                    .foregroundColor(creditColor(rating: scoreSelected))
                                Text(" is \(String(format: "%.3f", rates[scoreSelected] ?? 0))%")
                                
                            }
                            
                            
                        }
                        .padding()
                        .background(.white)
                        .clipShape( RoundedRectangle(cornerRadius: 15))
                        if creditSet {
                            let interest = (rates[scoreSelected] ?? 0)/1200
                            let principal = (Double(income!) * 0.28) * (pow((1 + interest), 360) - 1)
                            let bottom = (interest) * pow(1 + interest, 360)
                            let house = principal / bottom / 0.8

                            VStack {
                                Text("You can afford to take a loan out for \(NumberFormatter.localizedString(from: NSNumber(value: principal / bottom), number: NumberFormatter.Style.currency))")
                                    .multilineTextAlignment(.center)
                                Text("assuming a 20% down payment of \(NumberFormatter.localizedString(from: NSNumber(value: house * 0.2), number: NumberFormatter.Style.currency))")
                                    .multilineTextAlignment(.center)
                                Text("You can afford a house that is worth \(NumberFormatter.localizedString(from: NSNumber(value: house), number: NumberFormatter.Style.currency))")
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(.white)
                            .clipShape( RoundedRectangle(cornerRadius: 15))
                            
                            VStack {
                                Text("The average house in \(zipcode) is \(NumberFormatter.localizedString(from: NSNumber(value: Int(findvalue(zip: zipcode)) ?? 0), number: NumberFormatter.Style.currency))")
                                    .multilineTextAlignment(.center)
                                Text("You can afford a house about \(house / Double(Int(findvalue(zip: zipcode)) ?? 0)) times the average")
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(.white)
                            .clipShape( RoundedRectangle(cornerRadius: 15))
                        }
                    }
                }
            }
            
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.blue, .orange], startPoint: .top, endPoint: .bottom)
            )
    }
    
    func findvalue(zip: String) -> String {
        let zip = Int(zip) ?? 0
        let ziptext = String(zip)
        var count: Int?
        
        if data != nil {
            for row in data! {
                do {
                    var rowtext = try row.text()
                    if rowtext == ziptext {
                        count = 2
                    }
                    if count != nil {
                        if count == 0 {
                            return rowtext
                        }
                        count = count! - 1
                    }
                } catch {
                    print("error")
                }
            }
        }
        
        return ""
    }
    
    func creditColor(rating: Credit) -> Color {
        switch scoreSelected {
        case .excellent:
            return .green
        case .veryGood:
            return .green
        case .good:
            return .orange
        case .decent:
            return .orange
        case .fair:
            return .red
        case .poor:
            return .red
        }
    }
    
    func parsehtml() async-> Elements? {
        let session = URLSession.shared
        let url = URL(string:"https://terpconnect.umd.edu/~jzhai12/sgc/housingdata.html")!
        
        do {
            let (stringAsData, _) = try await session.data(from: url)
            let stringContent = String(data: stringAsData, encoding: .utf8) ?? ""
            let document = try SwiftSoup.parse(stringContent)
                
            let table = try document.select("table[border=1]").first()!
                
            let rows = try table.getElementsByTag("td")
            
            return rows
                
        }
        catch {
            print("eror")
        }
        
        return nil
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


enum Credit : String, CaseIterable, CustomStringConvertible {
    case excellent
    case veryGood
    case good
    case decent
    case fair
    case poor
    
    var description: String {
        switch self {
        case .excellent:
            return "Excellent (760+)"
        case .veryGood:
            return "Very Good (700-759)"
        case .good:
            return "Good (680-699)"
        case .decent:
            return "Decent (660-679)"
        case .fair:
            return "Fair (640-659)"
        case .poor:
            return "Poor (620-639)"
        }
    }
    
}


struct Title: View {
    @State private var rotation = 0.0
    
    var body: some View {
        Button() {
            withAnimation {
                rotation += 360
            }
        } label: {
            Text("bit.mortgage")
                .font(.largeTitle)
                .foregroundStyle(LinearGradient(colors: [.blue, .orange], startPoint: .leading, endPoint: .trailing))
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
    }
}

struct beginButton: View {
    @Binding var begun: Bool
    
    var body: some View {
        VStack {
            Text("Let's get started")
                .padding(.bottom)
            Button() {
                withAnimation{
                    begun.toggle()
                }
            } label: {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}

