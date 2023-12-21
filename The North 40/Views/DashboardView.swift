//
//  DashboardView.swift
//  The North 40
//
//  Created by Addison Ballif on 12/13/23.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        GeometryReader{ geometry in
            HStack {
                CalendarView()
                    .frame(width: geometry.size.width*4.0/11.0)
                
                Color.gray
                    .frame(width:5)
                    .frame(maxHeight:.infinity)
                
                ToDoView2()
                    //.frame(width: geometry.size.width*3.0/11.0)
                
                Color.gray
                    .frame(width:5)
                    .frame(maxHeight:.infinity)
                
                GoalListView2(isNavigationViewStacked: true)
                    //.frame(width: geometry.size.width*3.0/11.0)
                
                
            }
        }
    }
}

