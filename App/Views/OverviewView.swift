//
//  OverviewView.swift
//  GlucoseDirect
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        

        
        if let latestGlucose = store.state.latestGlucose {
            

        //    let glucoseEmoji: String = GetFunctionalArrows(glucose: latestGlucose)
            
        //     if let glucoseValue = latestGlucose.glucoseValue, !latestGlucose.isFaultyGlucose {
            

                ScrollView {
                    ZStack {
                      
                            
                            if store.state.latestSensorGlucose != nil {
                                GlucoseView()
                            }
                            
                            if !store.state.glucoseValues.isEmpty {
                                if #available(iOS 16.0, *) {
                                    ChartView()
                                } else {
                                    ChartViewFallback()
                                }
                            }
                            InsulinDeliveryView()
                            ConnectionView()
                            SensorView()
                       
                    }
                }.edgesIgnoringSafeArea(.vertical)
                /*
                NavigationView {
                    VStack {
                        HStack {
                            Button("Red") {
                                setNavbarColor(color: Color.red)
                            }
                            Button("Pink") {
                                setNavbarTitleColor(color: Color.pink)
                            }
                            Button("Reset") {
                                resetNavBar()
                            }
                        }
                        List {
                            
                            if store.state.latestSensorGlucose != nil {
                                GlucoseView()
                            }
                            
                            if !store.state.glucoseValues.isEmpty {
                                if #available(iOS 16.0, *) {
                                    ChartView()
                                } else {
                                    ChartViewFallback()
                                }
                            }
                            InsulinDeliveryView()
                            ConnectionView()
                            SensorView()
                        }.listStyle(.grouped)
                    }
                    
                    .navigationBarTitle("Glucose Direct 🩸\(glucoseValue.asGlucose(unit: store.state.glucoseUnit)) \(glucoseEmoji)")
            //        .setNavbarColor(color: getGlucoseTitleColor)
                    
                    ///.navigationBarTitleDisplayMode(.large)
                    
                    
                    
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "plus.square.dashed")
                                }
                            }
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                            }
                        }
                    }
                    
                    
                }
            } else {
                VStack {
                    List {
                        
                        if store.state.latestSensorGlucose != nil {
                            GlucoseView()
                        }
                        
                        if !store.state.glucoseValues.isEmpty {
                            if #available(iOS 16.0, *) {
                                ChartView()
                            } else {
                                ChartViewFallback()
                            }
                        }
                        InsulinDeliveryView()
                        ConnectionView()
                        SensorView()
                    }.listStyle(.grouped)
     
        }
                 
       
                 
            }
                 */
        }
    
    }
    

    
    private func GetAlarmLevel(glucose: Glucose) -> String {
       if let glucoseValue = glucose.glucoseValue, glucoseValue < store.state.alarmLow {
           return "High"
       }
        if let glucoseValue = glucose.glucoseValue, glucoseValue > store.state.alarmHigh {
            return "Low"
        }
       return "Range"
   }
    
    /*
     Change later the emojis, please clean up after me - I'm new to Swift. HALP.
     */
    private func GetFunctionalArrows(glucose: Glucose) -> String {
       if let glucoseValue = glucose.glucoseValue, glucoseValue < store.state.alarmLow {
           return "↗️"
       }
        if let glucoseValue = glucose.glucoseValue, glucoseValue > store.state.alarmHigh {
            return "↘️"
        }
        

       return ""
   }

    /*
        Change to pretty values later.
     */
    private func getGlucoseBackgroundColor(glucose: Glucose) -> Color {
        if GetAlarmLevel(glucose: glucose) == "High" {
            return Color.red
        }
        if GetAlarmLevel(glucose:  glucose ) == "Low" {
            return Color.orange
        }
        return Color.green
   }
    
    private func getGlucoseTitleColor(glucose: Glucose) -> Color {
        if GetAlarmLevel(glucose: glucose) == "High" {
            return Color.white
        }
        if GetAlarmLevel(glucose:  glucose ) == "Low" {
            return Color.black
        }
        return Color.white
   }
    
    
   
   
}
