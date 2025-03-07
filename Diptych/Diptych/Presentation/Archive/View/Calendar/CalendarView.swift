//
//  CalendarView.swift
//  Diptych
//
//  Created by Koo on 2023/07/17.
//


import SwiftUI
import Foundation

struct CalendarView: View {
    
    ///Property
    @EnvironmentObject var VM : ArchiveViewModel
    @State var date: Date
    let changeMonthInt : Int
    
    var body: some View {
        VStack(spacing: 0) {
            MonthlyCalendarView(changeMonthInt: changeMonthInt, VM: VM, today: date)
        }//】 VStack
        .onAppear{
            
        }
    }//】 body
}// Struct

// MARK: - Previews
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(date: Date(), changeMonthInt: 0)
    }
}
